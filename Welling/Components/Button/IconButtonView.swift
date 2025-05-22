//
//  IconButtonView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import SwiftUI

struct IconButtonView: View {
    let systemImageName: String
    let action: () -> Void
    let showBackgroundColor: Bool
    let backgroundColor: Color
    let foregroundColor: Color
    let defaultPadding: Bool
    let text: String?

    init(_ systemImageName: String, showBackgroundColor: Bool = false, backgroundColor: Color = Theme.Colors.SurfaceNeutral2, foregroundColor: Color = Theme.Colors.TextNeutral9, defaultPadding: Bool = true, text: String? = nil, action: @escaping () -> Void) {
        self.systemImageName = systemImageName
        self.showBackgroundColor = showBackgroundColor
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.defaultPadding = defaultPadding
        self.text = text
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Theme.Spacing.small) {
                ColoredIconView(imageName: systemImageName, foregroundColor: foregroundColor)
                
                if let text = text {
                    Text(text)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                }
            }
            .padding(.horizontal, defaultPadding ? Theme.Spacing.medium : 0)
            .padding(.vertical, defaultPadding ? Theme.Spacing.xsmall : 0)
            .background(showBackgroundColor ? backgroundColor : .clear)
            .clipShape(RoundedRectangle(cornerRadius: defaultPadding ? Theme.Radius.full : 0))
        }
    }
}

#Preview {
    IconButtonView("edit", showBackgroundColor: true) {}
}
