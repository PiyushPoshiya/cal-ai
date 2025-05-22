//
//  ContentView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-10.
//

import SwiftData
import SwiftUI
import AppTrackingTransparency
import Mixpanel
import os
import FirebaseCrashlytics
import SuperwallKit
import FirebaseMessaging
import StoreKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview: RequestReviewAction
    @StateObject var um: UserManager = .init()
    @StateObject var dm: DM = .shared
    @StateObject var mm: ModalManager = .init()
    @StateObject var viewModel: ConventViewModel = .init()
    @StateObject var keyboardHeightProvider: KeyboardHeightProvider = .init()
    @StateObject var signUpViewModel: SignUpViewModel = .init()

    var body: some View {
        ZStack {
            if um.checkingAuthState {
                LoadingModalView(progressView: true)
            } else {
                switch um.authState {
                case .none, .userEnteringForm, .signupFormSubmitted, .prewall, .prewallSeen, .paid, .creatingTempUser:
                    WelcomeScreenView()
                case .loggedIn:
                    HomeView()
                }
//                PrewallView(viewModel: signUpViewModel)
            }
            ModalManagerView()
        }
        .onAppear {
            viewModel.onAppear(dm: dm, um: um, mm: mm, signUpViewModel: signUpViewModel, presentationMode: presentationMode, requestReview: requestReview)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                ATTrackingManager.requestTrackingAuthorization { status in
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Mixpanel.mainInstance().track(event: "App Became Active")

                if NavigationState.shared.areConversationMessagesVisible || NavigationState.shared.areConversationMessagesScrolledToBottom {
                    UNUserNotificationCenter.current().setBadgeCount(0)
                }

            } else if newPhase == .inactive {
                //                Mixpanel.mainInstance().track(event: "App Became Inactive")
            } else if newPhase == .background {
                Mixpanel.mainInstance().track(event: "App Went Into Background")
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .environmentObject(mm)
        .environmentObject(um)
        .environmentObject(dm)
        .environment(\.realm, dm.realm)
        .environmentObject(signUpViewModel)
        .environmentObject(keyboardHeightProvider)
        .preferredColorScheme(um.colorScheme)
        .onOpenURL { url in
            Superwall.shared.handleDeepLink(url) // handle your deep link
        }
    }
}

#Preview {
    ContentView()
}


@MainActor
class ConventViewModel: ObservableObject {
    static let loggerCategory = String(describing: ConventViewModel.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )

    private var dm: DM?
    private var um: UserManager?
    private var mm: ModalManager?
    private var signUpViewModel: SignUpViewModel?
    private var presentationMode: Binding<PresentationMode>?
    private var requestReview: RequestReviewAction?

    @MainActor
    func onAppear(dm: DM, um: UserManager, mm: ModalManager, signUpViewModel: SignUpViewModel, presentationMode: Binding<PresentationMode>, requestReview: RequestReviewAction) {
        self.dm = dm
        self.um = um
        self.mm = mm
        self.signUpViewModel = signUpViewModel
        self.presentationMode = presentationMode
        self.requestReview = requestReview
        um.loginErrorHandler = self.onLoginError
        um.loginCompletedHandler = self.onLoginCompleted
        signUpViewModel.onAppear(um: um, presentationMode: presentationMode)
        um.registerAuthStateHandler(initialAuthHandler: self.initialAuthHandler)

        if !UserDefaults.standard.bool(forKey: "firstAppOpenTracked") {
            Mixpanel.mainInstance().track(event: "First App Open")
            Mixpanel.mainInstance().flush(performFullFlush: true)
            UserDefaults.standard.set(true, forKey: "firstAppOpenTracked")
        }
    }

    func initialAuthHandler() {
        guard let signUpViewModel = self.signUpViewModel, let um = self.um, let presentationMode = presentationMode else {
            return
        }

        WLogger.shared.log(Self.loggerCategory, "Initial auth handler called, auth state \(um.authState)")

        if um.authState != .none {
            return
        }

        WLogger.shared.log(Self.loggerCategory, "Initial auth handler called in ContentView with auth state none. Triggering sign up flow in background.")
//        Task { @MainActor in
//            do {
//                try await signUpViewModel.signInAnonymouslyIfNeeded()
//            } catch {
//                WLogger.shared.record(error)
//            }
//        }
    }

    func onLoginError(title: String, message: String) {
        mm!.showErrorModal(title: title, message: message)
    }

    func onLoginCompleted(user: WellingUser) {
        if let um = self.um {
            dm!.set(um: um)
        }

        Task { @MainActor in
            try await self.tryUpdateAppVersion(user: user)
            try await self.updateTimezoneIfNeeded(user: user)
            await self.updateFcmTokenIfNeeded(user: user)
            
            if let requestReview = self.requestReview {
                requestReview()
            }
        }

        dm!.userListener = self.onUserUpdated
    }

    func onUserUpdated(user: WellingUser) {
        um!.user = user
    }

    @MainActor
    func tryUpdateAppVersion(user: WellingUser) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        let version: StructAppVersion = getAppVersionStruct()

        if user.appVersion == nil || !(user.appVersion?.sameAs(s: version) ?? false) {
            WLogger.shared.log(Self.loggerCategory, "Updating app version")

                guard let dm = self.dm else {
                    return
                }

                try await dm.update(user: user, appVersion: version)
        }
    }

    @MainActor
    func updateTimezoneIfNeeded(user: WellingUser) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        if user.timezone == Calendar.current.timeZone.identifier {
           return
        }

        guard let dm = self.dm else {
            return
        }

        let oldTimezone: String = user.timezone

        try await dm.update(user: user, timezone: Calendar.current.timeZone.identifier)

        guard let existingSettings = user.notificationSettings else {
            return
        }

        guard let lunch = existingSettings.lunch, let endOfDay = existingSettings.endOfDay, let weight = existingSettings.weight else {
            return
        }

        let lunchHour: Int = DateUtils.transform(hour: lunch.hour, inTimezone: "UTC", toTimeZone: oldTimezone) ?? 14
        let endOfDayHour: Int = DateUtils.transform(hour: endOfDay.hour, inTimezone: "UTC", toTimeZone: oldTimezone) ?? 21
        let weightHour: Int = DateUtils.transform(hour: weight.hour, inTimezone: "UTC", toTimeZone: oldTimezone) ?? 9

        let update: UserNotificationsUpdate = UserNotificationsUpdate(
            allNotifications: existingSettings.allNotifications,
            lunchFoodLogReminder: existingSettings.lunchFoodLogReminder,
            endOfDayCheckIn: existingSettings.endOfDayCheckIn,
            consistentLoggingReward: existingSettings.consistentLoggingReward,
            educationalContent: existingSettings.educationalContent,
            logWeightReminder: existingSettings.logWeightReminder,
            dailyMorningCheckIn: existingSettings.dailyMorningCheckIn,
            whatsAppMarketing: existingSettings.whatsAppMarketing,
            lunch: getNotificationUpdate(enabled: lunch.enabled, date: Calendar.current.date(bySetting: .hour, value: lunchHour, of: .now)!, daysOfWeek: Array(lunch.daysOfWeek)),
            endOfDay: getNotificationUpdate(enabled: endOfDay.enabled, date: Calendar.current.date(bySetting: .hour, value: endOfDayHour, of: .now)!, daysOfWeek: Array(endOfDay.daysOfWeek)),
            weight: getNotificationUpdate(enabled: weight.enabled, date: Calendar.current.date(bySetting: .hour, value: weightHour, of: .now)!, daysOfWeek: Array(weight.daysOfWeek)))

        try await dm.update(user: user, notificationSettings: update)
    }

    private func getNotificationUpdate(enabled: Bool, date: Date, daysOfWeek: [Bool]) -> NotificationUpdate {
        let components: DateComponents = DateUtils.UtcCalendar.dateComponents([.hour, .minute], from: date)
        return NotificationUpdate(enabled: enabled, hour: components.hour!, minute: components.minute!, daysOfWeek: daysOfWeek)
    }

    @MainActor
    func updateFcmTokenIfNeeded(user: WellingUser) async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let dm = self.dm else {
            return
        }

        do {
            let currentToken = try await Messaging.messaging().token()
            if currentToken == user.fcmToken {
                return
            }

            try await dm.update(user: user, fcmToken: currentToken)
        } catch {
            // Ignore errors.
        }
    }
}
