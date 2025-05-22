//
//  UserManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-12.
//

import FirebaseAuth
import FirebaseCrashlytics
import Foundation
import os
import SwiftUI
import SuperwallKit
import StoreKit
import Mixpanel
import FacebookCore

enum UserAuthState: Int {
    case none
    case creatingTempUser
    case userEnteringForm
    case signupFormSubmitted
    case prewall
    case prewallSeen
    case paid
    case loggedIn
}

class UserManager: ObservableObject {
    static let loggerCategory = String(describing: UserManager.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )

    @Published var user: WellingUser = .empty
    @Published var authState: UserAuthState = .none
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var colorScheme: ColorScheme? = .none
    @Published var checkingInitialLoggedInState: Bool = true
    @Published var checkingAuthState: Bool = false

    private let anonSignInSemaphore: AsyncSemaphore = AsyncSemaphore(value: 1)
    private let auth: Auth
    private var authStateHandlerRegistered: Bool = false
    var isLoggedInAnonymously: Bool = false
    private var fetchManager: FetchManager = .init()
    var initialAuthHandler: (() -> Void)? = nil
    var loginCompletedHandler: (_ user: WellingUser) throws -> Void = { user in
    }
    var loginErrorHandler: (_ title: String, _ message: String) -> Void = { title, message in
    }
    var userPreferences: UserPreferences

    var paywallHandler: PaywallPresentationHandler = PaywallPresentationHandler()

    init() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        let savedAuthState: UserAuthState = Self.loadUserAuthState()
        WLogger.shared.log(Self.loggerCategory, "Loaded auths tate: \(savedAuthState)")
        checkingAuthState = savedAuthState == .none ? false : true
        authState = savedAuthState

        userPreferences = UserManager.loadUserPreferences()
        colorScheme = userPreferences.useSystemSettingsForDarkMode ? .none : (userPreferences.darkMode ? .dark : .light)

        auth = Auth.auth()

        paywallHandler.onDismiss(self.onPaywallDismiss)
        paywallHandler.onSkip(self.onPaywallSkip)
    }

    func onPaywallDismiss(paywallInfo: PaywallInfo) {
        WLogger.shared.log(Self.loggerCategory, "onPaywallDismiss")
        Task { @MainActor in
            await reloadUserFromAPI()
        }
    }

    func onPaywallSkip(reason: PaywallSkippedReason) {
        WLogger.shared.log(Self.loggerCategory, "onPaywallSkip")
        switch reason {
        case .holdout(let experiment):
            return
        case .noRuleMatch:
            return
        case .eventNotFound:
            return
        case .userIsSubscribed:
            WLogger.shared.log(Self.loggerCategory, "onPaywallSkip: user is subscribed")
            Task { @MainActor in
                await reloadUserFromAPI()
            }
        }
    }

    @MainActor
    func onUserUpdated(user: WellingUser) {
        self.user = user
    }

    func refreshIdToken() async throws {
        guard let user = auth.currentUser else {
            return
        }

        try await user.getIDTokenResult(forcingRefresh: true)
    }

    func checkIsSubscribedUsingFirebase() -> Bool {
        guard let subscriptionState = user.subscriptionState else {
            return false
        }

        let now: Int = Int(Date.now.timeIntervalSince1970)

        if subscriptionState.expiresAtUtc >= now {
            return true
        }

        if let gracePeriodEndsAtUtc = subscriptionState.gracePeriodEndsAtUtc {
            if gracePeriodEndsAtUtc >= now {
                return true
            }
        }

        return false
    }

    /**
        Delete the current user. Returns false if it requires user to re-login.
     */
    @MainActor
    func deleteUser() async throws -> Bool {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let fbUser = auth.currentUser else {
            return true
        }

        do {
            try await fbUser.delete()
            Self.deleteUserAuthState()
            self.user = WellingUser.empty
            isLoggedIn = false

            return true
        } catch {
            guard let error = error as NSError? else {
                throw error
            }

            let authError = AuthErrorCode(_nsError: error)
            if authError.code == .requiresRecentLogin {
                return false
            }

            throw error
        }
    }

    @MainActor
    func signInAnonymously() async throws -> String {
        WLogger.shared.log(Self.loggerCategory, "Logging in anonymously")

        await anonSignInSemaphore.wait() // Acquire the semaphore
        defer {
            anonSignInSemaphore.signal()
        } // Release the semaphore when done

        if let fbUser = auth.currentUser {
            isLoggedInAnonymously = fbUser.isAnonymous
            WLogger.shared.log(Self.loggerCategory, "Already logged in, returning. isAnonymous: \(self.isLoggedInAnonymously)")
            return fbUser.uid
        }

        WLogger.shared.log(Self.loggerCategory, "Not signed in anonymously yet, doing that now")

        let result = try await auth.signInAnonymously()
        isLoggedInAnonymously = true
        WLogger.shared.log(Self.loggerCategory, "Finished signing in anonymously: isAnonymous: \(result.user.isAnonymous), uid: \(result.user.uid)")
        return result.user.uid
    }

    /**
     
     Try to tync the currently logged in user with a user in the backend.
     
     If successful, returns true. If already synced, also returns true.
     
     If user doens't exist, return false.
     
     If error, return error.
     */
    func trySyncWhatsApp() async throws -> FetchResult<Void> {
        return await fetchManager.trySyncWhatsAppNumber()
    }

    func updateColorScheme(useSystemSettingsForDarkMode: Bool, darkMode: Bool) {
        userPreferences.useSystemSettingsForDarkMode = useSystemSettingsForDarkMode
        userPreferences.darkMode = darkMode

        colorScheme = userPreferences.useSystemSettingsForDarkMode ? .none : (userPreferences.darkMode ? .dark : .light)
        saveUserPreferences()
    }

    func onAppear(modalManager: ModalManager) {
    }

    func registerAuthStateHandler(initialAuthHandler: @escaping () -> Void) {
        if !authStateHandlerRegistered {
            WLogger.shared.log(Self.loggerCategory, "authStateHandler is nil, adding auth state listener.")
            self.initialAuthHandler = initialAuthHandler
            auth.addStateDidChangeListener(self.authStateHandler)
            authStateHandlerRegistered = true
        }
    }

    func authStateHandler(auth: Auth, user: User?) {
        // print "auth state changed", and which user is logged in
        WLogger.shared.log(Self.loggerCategory, "auth state changed, user: \(user?.uid ?? "nil")")

        guard let user = user else {
            Task { @MainActor in
                isLoggedIn = false

                withAnimation {
                    checkingAuthState = false
                }

                setAuthState(authState: .none)
                checkingInitialLoggedInState = false
                self.triggerInitialAuthHandler()
            }
            return
        }

        AppEvents.shared.userID = user.uid
        Mixpanel.mainInstance().identify(distinctId: user.uid)
        Crashlytics.crashlytics().setCustomValue(user.uid, forKey: "uid")

        if self.user.uid != user.uid {
            WLogger.shared.log(Self.loggerCategory, "User signed in, different user from \(self.user.uid) to \(user.uid)")
            AppEvents.shared.logEvent(AppEvents.Name("user_signed_in"))
            Mixpanel.mainInstance().track(event: "User Signed In")
        }

        isLoggedInAnonymously = user.isAnonymous

        Task { @MainActor in
            let result = await self.reloadUserFromAPI()

            withAnimation {
                checkingAuthState = false
            }

            if !result.success {
                self.triggerInitialAuthHandler()
                return
            }
            
            self.triggerInitialAuthHandler()
        }
    }

    @MainActor
    func triggerInitialAuthHandler() {
        if let initialAuthHandler = self.initialAuthHandler {
            initialAuthHandler()
            self.initialAuthHandler = nil
        }
    }

    @MainActor
    func reloadUserFromAPI() async -> ReloadUserResult {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let latestTransaction: StoreKit.Transaction? = await getLatestSubscriptionTransaction()
        var state: StoreKit.Product.SubscriptionInfo.RenewalState? = nil
        var signedTransactionPayload: String? = nil
        var signedRenewalInfoPayload: String? = nil
        if let latestTransaction = latestTransaction {
            let status = await latestTransaction.subscriptionStatus
            state = status?.state
            signedTransactionPayload = status?.transaction.jwsRepresentation
            signedRenewalInfoPayload = status?.renewalInfo.jwsRepresentation
        } else {
            WLogger.shared.log(Self.loggerCategory, "No transaction info found when reloading user.")
        }

        let result = await fetchManager.getMe(signedTransactionPayload: signedTransactionPayload, signedRenewalInfoPayload: signedRenewalInfoPayload, status: state?.rawValue)

        if let err = result.error {
            checkingInitialLoggedInState = false
            if result.statusCode == 401 {
                return ReloadUserResult(success: false, notSignedUp: true, noProfile: false, user: nil)
            }

            onLoginError(title: err.title, message: err.message)
            return ReloadUserResult(success: false, notSignedUp: false, noProfile: false, user: nil)
        }

        guard let me = result.value else {
            onLoginError(
                title: NSLocalizedString("Unknown Error", comment: "Title for a modal showing an unknown error."),
                message: NSLocalizedString("Please try again", comment: "Asking user to try again in a modal")
            )
            checkingInitialLoggedInState = false
            return ReloadUserResult(success: false, notSignedUp: false, noProfile: false, user: nil)
        }

        WLogger.shared.log(Self.loggerCategory, "Setting Superwall identity to \(me.id)")
        Superwall.shared.identify(userId: me.id)

        if me.profile == nil {
            return ReloadUserResult(success: true, notSignedUp: false, noProfile: true, user: me)
        }

        loginCompleted(user: me)
        checkingInitialLoggedInState = false
        return ReloadUserResult(success: true, notSignedUp: false, noProfile: false, user: me)
    }

    func getLatestSubscriptionTransaction() async -> StoreKit.Transaction? {
        var transactionWithLatestExpiration: StoreKit.Transaction? = nil

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                // Check the type of product for the transaction
                // and provide access to the content as appropriate.
                switch transaction.productType {
                case .autoRenewable, .nonRenewable:
                    if let _transactionWithLatestExpiration = transactionWithLatestExpiration {
                        if let expirationDate = transaction.expirationDate, let currentExpirationDate = _transactionWithLatestExpiration.expirationDate {
                            if expirationDate > currentExpirationDate {
                                transactionWithLatestExpiration = transaction
                            }
                        }
                    } else {
                        transactionWithLatestExpiration = transaction
                    }
                default:
                    continue
                }
            case .unverified(_, _):
                continue
            }
        }

        return transactionWithLatestExpiration
    }

    @MainActor
    func onLoginError(title: String, message: String) {
        Self.logger.error("\(message)")
        loginErrorHandler(title, message)
    }

    @MainActor
    func loginCompleted(user: WellingUser) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        if isLoggedInAnonymously {
            return
        } else {
            setAuthState(authState: .loggedIn)
        }

        self.user = user
        isLoggedIn = true
        
        do {
            try loginCompletedHandler(user)
        } catch {
            WLogger.shared.record(error)
        }
    }

    @MainActor
    func logout() throws {
        try auth.signOut()
        user = WellingUser.empty
        isLoggedIn = false
        setAuthState(authState: .none)
        Superwall.shared.reset()
        Mixpanel.mainInstance().reset()
    }

    func saveUserPreferences() {
        guard let data = try? PropertyListEncoder().encode(userPreferences) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "userPreferences")
    }

    @MainActor
    func setAuthState(authState: UserAuthState) {
        Self.saveUserAuthState(authState: authState)
        self.authState = authState
    }

    static func saveUserAuthState(authState: UserAuthState) {
        UserDefaults.standard.set(authState.rawValue, forKey: "userAuthState")
    }

    static func loadUserAuthState() -> UserAuthState {
        let rawValue = UserDefaults.standard.integer(forKey: "userAuthState")
        return UserAuthState(rawValue: rawValue) ?? .none
    }

    static func deleteUserAuthState() {
        UserDefaults.standard.removeObject(forKey: "userAuthState")
    }

    static func loadUserPreferences() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: "userPreferences"),
              let userPreferences = try? PropertyListDecoder().decode(UserPreferences.self, from: data)
        else {
            return UserPreferences(useSystemSettingsForDarkMode: true, darkMode: false)
        }
        return userPreferences
    }

    static let sample: UserManager = {
        let manager = UserManager()
        manager.user = WellingUser.sample
        manager.isLoggedIn = true
        manager.authState = .loggedIn
        return manager
    }()

    static let notLoggedIn: UserManager = {
        let manager = UserManager()
        return manager
    }()
}

struct ReloadUserResult {
    let success: Bool
    let notSignedUp: Bool
    let noProfile: Bool
    let user: WellingUser?
}
