//
//  SignUpView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-14.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var viewModel: SignUpViewModel

    var body: some View {
        VStack (spacing: 0) {
            if viewModel.state == .EnteringTypeform {
                HStack(alignment: .center, spacing: Theme.Spacing.xsmall) {
                    TextButtonView("Exit", foregroundColor: Theme.Colors.TextNeutral9) {
                        userManager.setAuthState(authState: .none)
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
                .navbar()
            }

            switch viewModel.state {
            case .CreatingUser:
                LoadingModalView(progressView: true, message: "Blending up a smoothie before we chat about your goals...")
            case .EnteringTypeform:
                SignUpWebView(formId: viewModel.signUpTypeFormId, handlers: viewModel, n: viewModel.signUpUserNanoId, tracking: viewModel.signUpTracking)
            case .Prewall, .Paywall:
                PrewallView(viewModel: viewModel)
            case .Login:
                SignInView(titleMessage: "Finish signing up", mode: .linkAnonymousAccountAndFinishSignUp)
            case .Error:
                Text("Sorry something went wrong, please try agian later.")
            }

            Spacer()

        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Color.clear
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit") {
                    presentationMode.wrappedValue.dismiss()
                }
                .offset(x: -25)
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            viewModel.onAppear(um: userManager, presentationMode: presentationMode)
            Task { @MainActor in
                await viewModel.startSignUpFlow()
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(UserManager.sample)
}
