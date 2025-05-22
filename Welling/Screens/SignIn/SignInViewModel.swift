//
//  SignInViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-12.
//

import AuthenticationServices
import CryptoKit
import FacebookCore
import FirebaseAnalytics
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import GoogleSignInSwift
import os
import SwiftUI
import Mixpanel

enum SignInMode {
    case normal
    case linkAnonymousAccountAndFinishSignUp
    case reauthenticate
}

class SignInViewModel: NSObject, ObservableObject {
    static let loggerCategory =  String(describing: SignInViewModel.self)
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )
    
    @Published var presentConfirmAnonymousLoginPopup: Bool = false
    
    @Published var showEnterPhoneNumberVerification: Bool = false
    @Published var isVerifyingPhoneNumber: Bool = false
    @Published var emailText: String = ""
    private var mode: SignInMode = .normal
    private var um: UserManager = .notLoggedIn
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var modalManager: ModalManager = .empty
    private var onLoginCompleted: ((_ success: Bool) -> Void)?
    
    @MainActor
    func onAppear(
        modalManager: ModalManager,
        um: UserManager,
        mode: SignInMode = .normal,
        onLoginCompleted: ((_ success: Bool) -> Void)? = nil
    ) {
        self.um = um
        self.mode = mode
        self.onLoginCompleted = onLoginCompleted
        self.modalManager = modalManager
        verifySignInWithAppleAuthenticationState()
    }
    
    @MainActor
    func onLoginError(_ errorMessage: String, _ errorTitle: String = "Error logging in") {
        self.modalManager.hideLoadingModal()
        self.modalManager.showErrorModal(title: errorTitle, message: errorMessage)
        self.onLoginCompleted?(false)
    }
    
    @MainActor
    func onLoginCancelled() {
        self.modalManager.hideLoadingModal()
        self.onLoginCompleted?(false)
    }
    
    @MainActor
    private func finishSignIn(with: AuthCredential) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        WLogger.shared.log(Self.loggerCategory, "Completing sign in with mode: \(mode)")
        
        switch mode {
        case .normal:
            Auth.auth().signIn(with: with, completion: self.handleAuthSignInResult)
        case .linkAnonymousAccountAndFinishSignUp:
            Mixpanel.mainInstance().track(event: "Sign In - Linking Anon Account")
            if Auth.auth().currentUser == nil {
                WLogger.shared.record(WellingLoginError.currentUserIsNilWhileLinkingAnonymousAccount)
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"current user is nil while linking"])
                self.onLoginError("Uknown error, please try again or contact support@welling.ai.")
                return
            }
            Auth.auth().currentUser?.link(with: with, completion: self.handleAuthSignInResult)
        case .reauthenticate:
            guard let user = Auth.auth().currentUser else {
                WLogger.shared.record(WellingLoginError.currentUserIsNilWhileReauthenticating)
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"current user is nil"])
                self.onLoginError("Uknown error, please try again or contact support@welling.ai.")
                return
            }
            
            user.reauthenticate(with: with, completion: self.handleAuthSignInResult)
        }
    }
    
    @MainActor
    private func handleAuthSignInResult(result: AuthDataResult?, error: Error?) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        WLogger.shared.log(Self.loggerCategory, "sign in with auth provider completed, user: \(result?.user.uid ?? "nil")")
        
        if let error = error as NSError? {
            self.isVerifyingPhoneNumber = false
            
            let errorCode: AuthErrorCode = AuthErrorCode(_nsError: error)
            switch  errorCode.code {
            case .credentialAlreadyInUse:
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"account already in use"])
                self.onLoginError("That account is already in use. Please use different credentials or go back and login.")
            case .emailAlreadyInUse:
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"email already in use"])
                self.onLoginError("That email is already in use.")
            default:
                WLogger.shared.record(error)
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"unknown sign in error code", "errorCode": errorCode.localizedDescription])
                self.onLoginError("Something went wrong, please try again or contact support@welling.ai.")
            }
            
            self.onLoginCompleted?(false)
            return
        }
        
        guard let user = result?.user else {
            WLogger.shared.error(Self.loggerCategory, "User is missing from non-error auth sign in result.")
            Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"user is missing from non-error result"])
            self.onLoginError("Please try again.")
            self.onLoginCompleted?(false)
            return
        }
        
        if self.isVerifyingPhoneNumber {
            Task {
                await self.completePhoneSignInFlow()
                await MainActor.run {
                    self.modalManager.hideLoadingModal()
                }
            }
            return
        }
        
        um.isLoggedInAnonymously = user.isAnonymous
        
        // If we're linking an anon account, we want to make sure the current user is up to date
        // and logged in.
        Task { @MainActor in
            if self.mode != .reauthenticate {
                let apiUserResult = await self.um.reloadUserFromAPI()
                
                if apiUserResult.notSignedUp {
                    self.onLoginError("Please sign up first.", "No Account")
                    Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"not signed up"])
                    if mode == .normal {
                        WLogger.shared.log(Self.loggerCategory, "Deleting non-signed up user so they can continue the signup flow successfully.")
                        try await self.um.deleteUser()
                    }
                    try self.um.logout()
                    self.onLoginCompleted?(false)
                    return
                }
                
                if apiUserResult.noProfile {
                    self.onLoginError("Please finish signing up.")
                    Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"user has no profile"])
                    self.onLoginCompleted?(false)
                    return
                }
                
                if !apiUserResult.success {
                    WLogger.shared.error(Self.loggerCategory, "Reload user from API result was not success.")
                    Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"reload user from API failed"])
                    self.onLoginError("Something went wrong, please try again later.")
                    try self.um.logout()
                    self.onLoginCompleted?(false)
                    return
                }
            }
            
            self.onLoginCompleted?(true)
            self.modalManager.hideLoadingModal()
        }
    }
    
    func completePhoneSignInFlow() async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        do {
            // check if we have a user id in the claims
            // if we do, we're good.
            // if we don't, we have to call sync and reload the id token.
            // Simplify flow by just syncing and refreshing.
            let syncResult = try await um.trySyncWhatsApp()
            if syncResult.statusCode == 401 {
                await MainActor.run {
                    self.onLoginError("Please sign up first.", "No Account")
                    self.isVerifyingPhoneNumber = false
                }
                return
            } else if syncResult.statusCode != 200 {
                await MainActor.run {
                    self.onLoginError("Please try again")
                    self.isVerifyingPhoneNumber = false
                }
                return
            }
            
            try await um.refreshIdToken()
            _ = await um.reloadUserFromAPI()
            
            await MainActor.run {
                self.isVerifyingPhoneNumber = false
            }
            
        } catch {
            WLogger.shared.record(error)
            await MainActor.run {
                self.onLoginError("Please try again")
            }
        }
    }
    
    @MainActor
    func handleGoogleLogin(viewController: UIViewController) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        self.modalManager.showLoadingModal()
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if error != nil {
                if let error = error as NSError? {
                    if error.domain == kGIDSignInErrorDomain && error.code == -5 {
                       // Not an error
                        self.onLoginCancelled()
                        return
                    }
                }
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"unknown google sign in failure: \(error?.localizedDescription ?? "")"])
                self.onLoginError(error?.localizedDescription ?? "")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken
            else {
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"google sign in returned no user"])
                self.onLoginError("Google sign in returned no user")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: user.accessToken.tokenString)
            self.finishSignIn(with: credential)
        }
    }
    
    @MainActor
    func handleAppleLogin() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        self.modalManager.showLoadingModal()
        let nonce: String = randomNonceString()
        self.currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request: ASAuthorizationAppleIDRequest = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    @MainActor
    func verifyPhoneNumberForLogn(verificationCode: String) {
        
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        self.isVerifyingPhoneNumber = true
        let verificationId = UserDefaults.standard.string(forKey: "authVerificationID")
        guard let vId = verificationId else {
            Self.logger.error("Error sending phone verification code, saved verification id is nil")
            self.modalManager.showErrorModal(title: "Something went wrong", message: "Please try again")
            self.modalManager.hideLoadingModal()
            return
        }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: vId, verificationCode: verificationCode)
        self.finishSignIn(with: credential)
    }
    
    @MainActor
    func signOut() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        do {
            try Auth.auth().signOut()
        } catch {
            WLogger.shared.record(error)
            self.onLoginError(error.localizedDescription, "Error logging out")
        }
    }
}

// MARK: - Apple Sign In Methods

extension SignInViewModel: ASAuthorizationControllerDelegate {
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential: ASAuthorizationAppleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                self.onLoginError("Invalid state: a login callback was received, but no login request was sent.")
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"apple sign in callback receieved unexpectedly"])
                fatalError(self.modalManager.errorModalMessage)
            }
            guard let appleIDToken: Data = appleIDCredential.identityToken else {
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"unable to fetch apple sign in identity token"])
                self.onLoginError("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"unable to serialize apple sign in token"])
                self.onLoginError("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential: OAuthCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                                       idToken: idTokenString,
                                                                       rawNonce: nonce)
            self.finishSignIn(with: credential)
        }
    }
    
    @MainActor
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.modalManager.hideLoadingModal()
        self.onLoginCompleted?(false)
    }
    
    @MainActor
    func updateDisplayName(for user: User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
        } else {
            let changeRequest: UserProfileChangeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = appleIDCredential.displayName()
            do {
                try await changeRequest.commitChanges()
            } catch {
                Mixpanel.mainInstance().track(event: "Sign In Failed", properties:["reason":"unable to update display name for apple sign in"])
                WLogger.shared.record(error)
                self.onLoginError(error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func verifySignInWithAppleAuthenticationState() {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            _Concurrency.Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        self.signOut()
                    default:
                        break
                    }
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
}

extension ASAuthorizationAppleIDCredential {
    func displayName() -> String {
        return [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

// Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength: Int = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode: Int32 = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError(
                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                )
            }
            return random
        }
        
        for random in randoms {
            if remainingLength == 0 {
                continue
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

enum WellingLoginError: Error {
    case currentUserIsNilWhileLinkingAnonymousAccount
    case currentUserIsNilWhileReauthenticating
}

extension WellingLoginError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .currentUserIsNilWhileLinkingAnonymousAccount:
            return "Finished signing in but current user is nil while linking anonymous account to new account."
        case .currentUserIsNilWhileReauthenticating:
            return "Finished signing in but current user is nul while reauthenticating."
        }
    }
}
