//
//  SwiftUIView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-12.
//

import SwiftUI
import Mixpanel

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var modalManager: ModalManager
    @EnvironmentObject var um: UserManager
    @StateObject var viewModel: SignInViewModel = .init()
    @State var signInWithPhneNumber: Bool = false
    @FocusState var emailFocus: Bool
    
    let titleMessage: String
    let mode: SignInMode
    let onLoginCompleted: ((_ success: Bool) -> Void)?
    
    init(titleMessage: String, mode: SignInMode, onLoginCompleted: ((_: Bool) -> Void)? = nil) {
        self.titleMessage = titleMessage
        self.mode = mode
        self.onLoginCompleted = onLoginCompleted
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if mode == .normal {
                    HStack(alignment: .center, spacing: Theme.Spacing.xsmall) {
                        IconButtonView("arrow-left-long", showBackgroundColor: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        Spacer()
                    }
                    .navbar()
                } else {
                    Spacer()
                        .frame(height: Theme.Spacing.xxlarge)
                }
                
                Spacer()
                    .frame(height: Theme.Spacing.xxxlarge)
                
                Image("logo-text-right-red")
                    .resizable()
                    .scaledToFit()
                    .frame(height: Theme.Spacing.xlarge)
                
                Spacer()
                
                VStack (alignment: .leading, spacing: Theme.Spacing.large) {
                    HStack {
                        switch mode {
                        case .normal:
                            Text("Sign In")
                                .fontWithLineHeight(Theme.Text.h2)
                        case .linkAnonymousAccountAndFinishSignUp:
                            Text("Create an account for your custom plan")
                                .fontWithLineHeight(Theme.Text.h2)
                        case .reauthenticate:
                            Text("Confirm your identity before deleting")
                                .fontWithLineHeight(Theme.Text.h2)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: Theme.Spacing.medium) {
                        Button {
                            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Continue With Apple", "screen":"SignInView"])
                            viewModel.handleAppleLogin()
                        } label: {
                            HStack(alignment: .center) {
                                Text("Continue with Apple")
                                    .fontWithLineHeight(Theme.Text.mediumSemiBold)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image("AppleSignInLogo")
                            }
                            .padding(.horizontal, Theme.Spacing.large)
                            .frame(height: 46)
                            .background(.black)
                            .cornerRadius(Theme.Radius.full)
                        }
                        
                        Button {
                            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Continue With Google", "screen":"SignInView"])
                            viewModel.handleGoogleLogin(viewController: getRootViewController())
                        } label: {
                            HStack(alignment: .center) {
                                Text("Continue with Google")
                                    .fontWithLineHeight(Theme.Text.mediumSemiBold)
                                    .foregroundStyle(.black)
                                Spacer()
                                Image("GoogleSignInLogo")
                                    .padding(.trailing, Theme.Spacing.small)
                            }
                            .padding(.horizontal, Theme.Spacing.large)
                            .frame(height: 46)
                            .background(.white)
                            .cornerRadius(Theme.Radius.full)
                        }
                    }
                }
                .card()
                
                //                VStack (spacing: 18) {
                //                    Text("Or")
                //                        .fontWithLineHeight(Theme.Text.mediumMedium)
                //
                //                    Button {
                //                        viewModel.handleGoogleLogin(viewController: getRootViewController())
                //                    } label: {
                //                        HStack(alignment: .center) {
                //                            Text("Sign up with email")
                //                                .fontWithLineHeight(Theme.Text.mediumSemiBold)
                //                                .foregroundStyle(.black)
                //                            Spacer()
                //                        }
                //                        .padding(.horizontal, Theme.Spacing.large)
                //                        .padding(.vertical, Theme.Spacing.medium)
                //                        .background(.white)
                //                        .overlay(
                //                            RoundedRectangle(cornerRadius: Theme.Radius.full)
                //                            .inset(by: 0.5)
                //                            .stroke(Theme.Colors.TextNeutral9, lineWidth: 1)
                //                        )
                //                    }
                //                }
                //                .padding(.vertical, 18)
                //                .padding(.horizontal, Theme.Spacing.xlarge)
                
                Spacer()
                
                if mode == .linkAnonymousAccountAndFinishSignUp {
                    Text("If you are having issues signing up, please contact support@welling.ai, or [start again](https://startagain).")
                        .environment(\.openURL, OpenURLAction { url in
                            if url.absoluteString.starts(with: "mailto") {
                                return .systemAction
                            }
                            
                            modalManager.showConfirmModal(title: "Start Again", message: "Your subscription is saved and you will not have to subscribe again.") { confirmed in
                                if !confirmed {
                                    return
                                }
                                
                                um.setAuthState(authState: .none)
                                presentationMode.wrappedValue.dismiss()
                            }
                            return .handled
                        })
                        .multilineTextAlignment(.center)
                        .fontWithLineHeight(Theme.Text.smallRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral3)
                        .padding(.bottom, Theme.Spacing.medium)
                        .padding(.horizontal, Theme.Spacing.medium)
                } else {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.horizontalPadding)
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            viewModel.onAppear(modalManager: modalManager, um: um, mode: mode, onLoginCompleted: onLoginCompleted)
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var checked: Bool = false
        @StateObject var modalManager: ModalManager = ModalManager()
        
        var body: some View {
            VStack {
                SignInView(titleMessage: "Continue", mode: .linkAnonymousAccountAndFinishSignUp, onLoginCompleted: nil)
                    .environmentObject(UserManager.sample)
                
                ModalManagerView()
            }
            .environmentObject(modalManager)
        }
    }
    return PreviewWrapper()
}
