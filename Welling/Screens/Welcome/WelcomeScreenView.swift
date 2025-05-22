//
//  WelcomeView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-14.
//

import SwiftUI
import os
import Mixpanel

struct WelcomeScreenView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: WelcomeScreenView.self))
    static let AnalyticsScreen: String =  "Welcome"
    
    @EnvironmentObject var um: UserManager
    
    @State private var signIn: Bool = false
    @State private var signUp: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack (spacing: 0) {
                Spacer()
                    .frame(height: Theme.Spacing.xsmall)
                WelcomeCarouselView()
                Spacer()
                
                VStack {
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Get Started", "screen": Self.AnalyticsScreen])
                        signUp = true
                    } label: {
                        HStack {
                            Text("Get started")
                                .fontWithLineHeight(Theme.Text.h5)
                                .kerning(-0.8)
                            Spacer()
                            
                            Image("arrow-right-long")
                                .frame(width: 56, height: 40)
                                .background(Theme.Colors.SurfacePrimary100)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
                            
                        }
                        .padding(Theme.Spacing.xlarge)
                        .background(Theme.Colors.SurfaceSecondary100)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
                    }
                }
                .padding(.horizontal, Theme.Spacing.xsmall)
                
                Button {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Sign In"])
                    signIn = true
                } label: {
                    HStack (spacing: 0) {
                        Text("Already have an account? **Sign in**")
                            .fontWithLineHeight(Theme.Text.mediumRegular)
                    }
                    .padding(.top, Theme.Spacing.large)
                    .padding(.bottom, 20.0)
                }
            }
            .padding(.horizontal, Theme.Spacing.xsmall)
            .navigationDestination(isPresented: $signUp, destination: {
                SignUpView()
                    .withoutDefaultNavBar()
            })
            .navigationDestination(isPresented: $signIn, destination: {
                SignInView(titleMessage: "Log In", mode: .normal)
                    .withoutDefaultNavBar()
            })
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .onAppear {
            switch um.authState {
            case .none:
                signUp = false
            case .creatingTempUser:
                signUp = true
            case .userEnteringForm:
                signUp = true
            case .signupFormSubmitted:
                signUp = true
            case .prewall:
                signUp = true
            case .prewallSeen:
                signUp = true
            case .paid:
                signUp = true
            case .loggedIn:
                Self.logger.error("Unexpected auth state in welcome screen")
            }
        }
    }
}

#Preview {
    WelcomeScreenView()
        .environmentObject(ModalManager.empty)
        .environmentObject(UserManager.sample)
}
