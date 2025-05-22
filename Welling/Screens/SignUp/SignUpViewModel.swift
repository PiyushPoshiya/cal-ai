//
//  SignUpViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-15.

/*
 Sign up flow is:
 - Get or create firebase anonymous user
 [x] Add signInAnonymously to UserManager
 [x] Make sure UserManager doesn't get user from API if anonymous
 - Check if welling user already exists. If not, create one using the sign-up API
 [x] Read/write methods for temporary welling user
 - Save the created user in storage
 [x] Fetch method to create a new Welling user
 - Listen for firestore events on the signup collection for this user's document.
 [x] Add a listener for the document in signup collection
 
 States:
 - Creating user
 - Entering typeform
 - Waiting for typeform webhook to complete via listener or polling
 - Login with specific credentials
 */

import SwiftUI
import FirebaseFirestore
import SuperwallKit
import Foundation
import os
import FacebookCore
import Mixpanel

class SignUpViewModel: NSObject, ObservableObject, PSignUpFormHandler {
    static let loggerCategory =  String(describing: SignUpViewModel.self)

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )

    @Published var state: SignUpState = .CreatingUser

    var signUpTypeFormId: String = ""
    var signUpUserNanoId: String = ""
    var signUpTracking: UtmParams = .empty
    private var presentationMode: Binding<PresentationMode>?

    private var um: UserManager = .notLoggedIn
    private var initialized: Bool = false
    private let firestore: Firestore = .firestore()
    private let fetchManager: FetchManager = .init()
    private let remoteConfig: WRemoteConfig = .init()
    private let signUpSemaphore = AsyncSemaphore(value: 1)

    @MainActor
    func onAppear(um: UserManager, presentationMode: Binding<PresentationMode>) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        self.um = um
        self.presentationMode = presentationMode
        self.state = .CreatingUser
    }

    @MainActor
    func startSignUpFlow() async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        await self.signUpSemaphore.wait()
        defer {
            signUpSemaphore.signal()
        }
        
        WLogger.shared.log(Self.loggerCategory, "Starting sign up flow.")
        do {
            // At  this point, the app will already have checked the auth state.
            // That means that, if user is already logged in, we would have reloaded the current user.
            
            let uid: String = try await signInAnonymouslyIfNeeded()
            WLogger.shared.log(Self.loggerCategory, "Signed in. Current auth state is \(self.um.authState)")

            switch self.um.authState {
            case .loggedIn:
                Self.logger.error("Unexpected auth state")
            case .none, .creatingTempUser, .userEnteringForm:
                // Do regular flow with temp welling user
                try await checkTempUserAndSendToForm(uid: uid)
            case .signupFormSubmitted, .prewall, .prewallSeen:
                // Check if their profile is set. If profile is set, get them to complete sign up
                // If profile is not set, do regular flow wtih temp welling user
                try await checkProfileAndCompleteSignup(uid: uid)
            case .paid:
                // Already paid, have them login
                withAnimation {
                    self.state = .Login
                }

            }
        } catch {
            Mixpanel.mainInstance().track(event: "Sign Up Failed", properties:["reason":error.localizedDescription])
            Mixpanel.mainInstance().flush(performFullFlush: true)
            WLogger.shared.record(error)
        }
    }

    func checkProfileAndCompleteSignup(uid: String) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        if self.um.user.profile == nil {
            WLogger.shared.log(Self.loggerCategory, "User has no profile, sending to form")
            try await checkTempUserAndSendToForm(uid: uid)
            return
        }

        // Profile is set, however they might still be anonymous? If so, sign them up
        if self.um.isLoggedInAnonymously {
            WLogger.shared.log(Self.loggerCategory, "Is logged in anonymously, continuing")
            await handleFormCompleted()
        } else {
            // They  must already be logged in but how can we be here?!
            WLogger.shared.error(Self.loggerCategory, "Unexpected auth state. User not logged in anonymously but is in sign up flow.")
        }
    }

    @MainActor
    func checkTempUserAndSendToForm(uid: String) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        um.setAuthState(authState: .creatingTempUser)
        let result = await fetchManager.signUpTempUser(request: TempUserSignUpRequest(uid: uid, timezone: TimeZone.current.identifier, utmParams: UtmParams(campaign: nil, source: "ios-app", medium: nil, term: nil, content: nil), appVersion: getAppVersionStruct()))
        WLogger.shared.log(Self.loggerCategory, "Created temp user.")

        guard let user = result.value else {
            WLogger.shared.error(Self.loggerCategory, "User is null")
            return
        }
        
        WLogger.shared.log(Self.loggerCategory, "Setting Superwall identity to \(user.id)")
        Superwall.shared.identify(userId: user.id)
        
        Superwall.shared.preloadPaywalls(forEvents: ["signup"]);

        WLogger.shared.log(Self.loggerCategory, "Temp user saved.")

        try await sendUserToForm(uid: uid, nanoId: user.nanoId, tracking: user.tracking)
    }

    func sendUserToForm(uid: String, nanoId: String, tracking: WellenUserTracking?) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        await um.setAuthState(authState: .userEnteringForm)

        // So we can get the user's id into the claims
        try await um.refreshIdToken()

        await MainActor.run {
            guard let typeFormId = getSignUpTypeFormId() else {
                state = SignUpState.Error
                return
            }
            signUpTypeFormId = typeFormId
            signUpTracking = UtmParams.from(tracking: tracking)
            signUpUserNanoId = nanoId
            
            WLogger.shared.log(Self.loggerCategory, "Sending user to form '\(signUpTypeFormId)', with nanoId: '\(signUpUserNanoId)'")
            
            withAnimation(.easeInOut) {
                state = SignUpState.EnteringTypeform
            }

            AppEvents.shared.logEvent(AppEvents.Name("user_started_intake_form"))
            Mixpanel.mainInstance().track(event: "User Started Intake Form")
            Mixpanel.mainInstance().flush(performFullFlush: true)
        }
    }

    func getSignUpTypeFormId() -> String! {
        return BuildEnvironment.isSimulatorOrTestFlight() ? "pynKdCIc" : "AveOiuwx"
    }

    func onPrewallSeen() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
       
        Task { @MainActor in
            if um.authState != .prewallSeen {
                um.setAuthState(authState: .prewallSeen)
            }
        }
        
        let handler = PaywallPresentationHandler()
        handler.onDismiss { paywallInfo in
            Mixpanel.mainInstance().track(event: "Paywall Dismissed", properties: ["reason":paywallInfo.closeReason.rawValue])
            
            if paywallInfo.closeReason == .systemLogic {
                Task {
                    let latestTransaction: StoreKit.Transaction? = await self.um.getLatestSubscriptionTransaction()
                    var properties: Properties = [:]
                    if let latestTransaction = latestTransaction {
                        properties["product"] = latestTransaction.productID
                        
                        AppEvents.shared.logEvent(AppEvents.Name("user_started_trial"))
                        AppEvents.shared.logEvent(AppEvents.Name("user_started_trial"))
                        Mixpanel.mainInstance().track(event: "User Started Trial", properties: properties)
                        Mixpanel.mainInstance().track(event: "User Completed Transaction")
                    }
                }
            }
        }
        
        handler.onPresent { paywallInfo in
            Mixpanel.mainInstance().track(event: "Paywall Presented")
        }
        
        handler.onError { error in
            Mixpanel.mainInstance().track(event: "Paywall Presentation Error", properties: ["reason":error.localizedDescription])
        }
        
        handler.onSkip { reason in
            Mixpanel.mainInstance().track(event: "Paywall Skipped", properties: ["reason":reason.description])
        }
        
        Superwall.shared.register(event: "signup", handler: handler) {
            Task { @MainActor in
                self.um.setAuthState(authState: .paid)
                withAnimation(.easeInOut) {
                    self.state = .Login
                }
            }
        }
    }

    @MainActor
    private func handleFormCompleted() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        if um.authState == .prewallSeen {
            self.um.setAuthState(authState: .prewallSeen)
            withAnimation(.easeInOut) {
                state = .Paywall
            }
            onPrewallSeen()
        } else {
            self.um.setAuthState(authState: .prewall)
            withAnimation(.easeInOut) {
                state = SignUpState.Prewall
            }
        }
    }

    @MainActor
    private func handleFormSubmittedOnClient() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        self.um.setAuthState(authState: .signupFormSubmitted)

        // Request to send notifications.
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    Mixpanel.mainInstance().track(event: "Sign Up Failed", properties:["reason":"form submission error"])
                    WLogger.shared.record(error)
                } else {
                    Mixpanel.mainInstance().track(event: "User Answered Request Notification Authorization", properties: [
                        "granted": granted])
                }
            }
        )

        withAnimation(.easeInOut) {
            state = SignUpState.Prewall
        }
    }

    @MainActor
    func signInAnonymouslyIfNeeded() async throws -> String {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let uid: String = try await um.signInAnonymously()
        
        WLogger.shared.log(Self.loggerCategory,  "Signed in anonymously")
        return  uid
    }
    
    /** Sign up web view callback handlers **/
    func onReady() {
    }

    func onStarted() {
    }

    func onSubmit() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        if lastQuestion == "a34b277e-9b58-4753-81e1-709d962a5482" {
            Task { @MainActor in
                AppEvents.shared.logEvent(AppEvents.Name("user_submitted_intake_form"))
                Mixpanel.mainInstance().track(event: "User Submitted Intake Form")
                Mixpanel.mainInstance().flush(performFullFlush: true)
                handleFormSubmittedOnClient()
            }
        } else {
            // was not the expected last question, send user back to start screen
            Task { @MainActor in
                Mixpanel.mainInstance().track(event: "User Intake Form Rejected")
                Mixpanel.mainInstance().flush(performFullFlush: true)
                
                await userDeniedAccessToWelling()
            }
        }
    }

    func userDeniedAccessToWelling() async {
        // They were denied access, send them back home.
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        // update the auth state
        await um.setAuthState(authState: .none)
    }

    var lastQuestion: String = ""

    func onQuestionChanged(question: String) {
        lastQuestion = question
    }

    func onClose() {
    }

    func onEndingButtonClick() {
    }

    private func waitForDocumentToExist(_ docRef: DocumentReference) async throws -> DocumentSnapshot? {
        for _ in 0..<10 {
            let snap = try await docRef.getDocument()
            if snap.exists {
                return snap
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        return nil
    }
}

enum SignUpState: Int, Equatable {
    case CreatingUser = 1
    case EnteringTypeform = 2
    case Prewall = 4
    case Paywall = 5
    case Login = 6
    case Error = 7
}

/**
 Represents the user created on Welling that still needs their form filled out.
 */

protocol PSignUpFormHandler {
    func onReady()
    func onStarted()
    func onQuestionChanged(question: String)
    func onSubmit()
    func onClose()
    func onEndingButtonClick()
}
