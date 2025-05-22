//
//  FacebookLoginButton.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-14.
//

import FBSDKLoginKit
import SwiftUI

struct FacebookLoginButton: UIViewRepresentable {
    typealias UIViewType = FBLoginButton
    
    func makeUIView(context: Context) -> UIViewType {
        FBLoginButton()
    }

    func updateUIView(_ uiView: FBLoginButton, context: Context) { }
}

#Preview {
    FacebookLoginButton()
}
