//
//  LoadingModalView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-13.
//

import SwiftUI

struct LoadingModalView: View {
    var title: String = ""
    var progressView: Bool = true
    var message: String = ""

    var body: some View {
        VStack (spacing: Theme.Spacing.medium) {
            Spacer()
            if title.count > 0 {
                Text(title)
                    .fontWithLineHeight(Theme.Text.largeRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral9)
            }
            if message.count > 0 {
                Text(message)
                    .fontWithLineHeight(Theme.Text.mediumRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral2)
                    .multilineTextAlignment(.center)
            }
            if progressView {
                WellingBreathingIndicatorView()
            }
            Spacer()
        }
        .padding(Theme.Spacing.xlarge)
        .frame(maxWidth: .infinity)
    }
}

struct LoadingModalView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingModalView(title: "Thanks!", message: "Blending up a smoothie before we chat about your goals...")
    }
}

