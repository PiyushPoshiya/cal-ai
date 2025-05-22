//
//  WellingBreathingIndicatorView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-20.
//

import SwiftUI

struct WellingBreathingIndicatorView: View {
    @State private var size: CGFloat = 1
    @State private var opacity: CGFloat = 1
    
    var body: some View {
        Image("logo-icon")
            .opacity(opacity)
            .scaleEffect(size)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    size = 0.9
                    opacity = 0.5
                }
            }
    }
}

#Preview {
    WellingBreathingIndicatorView()
}
