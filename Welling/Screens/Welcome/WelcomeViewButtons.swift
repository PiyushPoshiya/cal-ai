//
//  WelcomeView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-12.
//

import SwiftUI

struct WelcomeViewButtons: View {
    @Binding var signIn: Bool
    @Binding var signUp: Bool
    
    var body: some View {
        VStack (spacing: Theme.Spacing.xsmall) {
            WBlobkButton("Get Started") {
                signUp = true
            }
            WBlobkButton("Sign In" ) {
                signIn = true
            }
        }
    }
}

#Preview {
    WelcomeViewButtons(signIn: .constant(true), signUp: .constant(true))
}
