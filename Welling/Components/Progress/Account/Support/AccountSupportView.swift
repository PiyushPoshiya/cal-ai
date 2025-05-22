//
//  AccountSupportView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-12.
//

import SwiftUI

struct AccountSupportView: View {
    @Environment(\.openURL) var openURL
    
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Support")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                HStack {
                    IconButtonView("xmark", showBackgroundColor: true) {
                        isPresented = false
                    }
                    Spacer()
                }
            }
            .navbar()
            
            VStack (spacing: Theme.Spacing.small) {
                Button {
                    openURL(URL(string: "https://www.site.welling.ai/faq")!)
                } label: {
                    HStack (spacing: Theme.Spacing.medium) {
                        ColoredIconView(imageName: "help-circle", foregroundColor: Theme.Colors.TextNeutral05)
                        Text("Read FAQ")
                            .fontWithLineHeight(Theme.Text.mediumMedium)
                            .foregroundStyle(Theme.Colors.TextNeutral9)
                        Spacer()
                        ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral05)
                    }
                    .card(small: true)
                }
                
                Button {
                    openURL(URL(string: "mailto:support@welling.ai")!)
                } label: {
                    HStack (spacing: Theme.Spacing.medium) {
                        ColoredIconView(imageName: "mail-out", foregroundColor: Theme.Colors.TextNeutral05)
                        Text("Email us at support@welling.ai")
                            .fontWithLineHeight(Theme.Text.mediumMedium)
                            .foregroundStyle(Theme.Colors.TextNeutral9)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Spacer()
                        ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral05)
                    }
                    .card(small: true)
                }
            }
            .padding(.horizontal, Theme.Spacing.horizontalPadding)
        }
    }
}

#Preview {
    AccountSupportView(isPresented: .constant(true))
}
