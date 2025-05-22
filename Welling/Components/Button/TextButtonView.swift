//
//  TextButtonView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-05.
//

import SwiftUI

struct TextButtonView: View {
    var text: String
    var foregroundColor: Color
    var action: () -> Void

    init(_ text: String, foregroundColor: Color = Theme.Colors.SurfaceSecondary100, action: @escaping () -> Void) {
        self.text = text
        self.foregroundColor = foregroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .fontWithLineHeight(Theme.Text.smallMedium)
                .foregroundStyle(foregroundColor)
                .padding(.vertical, Theme.Spacing.xsmall)
                .padding(.horizontal, Theme.Spacing.medium)
                .background(Theme.Colors.SurfacePrimary100)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
        }
    }
}

struct PrimaryTextButtonView: View {
    var text: String
    var foregroundColor: Color
    var action: () -> Void
    var disabled: Bool

    init(_ text: String, disabled: Bool = false, action: @escaping () -> Void, foregroundColor: Color = Theme.Colors.SurfaceSecondary100) {
        self.text = text
        self.foregroundColor = foregroundColor
        self.action = action
        self.disabled = disabled
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .fontWithLineHeight(Theme.Text.smallMedium)
                .foregroundStyle(Theme.Colors.TextPrimary100.opacity(disabled ? 0.8 : 1.0))
                .padding(.vertical, Theme.Spacing.xsmall)
                .padding(.horizontal, Theme.Spacing.medium)
                .background(disabled ? Theme.Colors.SurfaceNeutral3 : Theme.Colors.SurfaceSecondary100)
                .cornerRadius(Theme.Radius.full)
                .opacity(disabled ? 0.65 : 1.0)
        }.disabled(disabled)
    }
}


#Preview {
    VStack {
        TextButtonView("Test") {}
        PrimaryTextButtonView("Primary", disabled: false) {}
    }
}
