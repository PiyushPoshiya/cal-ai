//
//  TextFieldStyles.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-05.
//

import Foundation
import SwiftUI

struct WellingTextFeldStyle: TextFieldStyle {
    @FocusState private var focused: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .fontWithLineHeight(Theme.Text.mediumMedium)
            .padding(.vertical, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(Theme.Colors.SurfaceNeutral05)
            .foregroundStyle(Theme.Colors.TextPrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .inset(by: 1)
                .stroke(focused ? Theme.Colors.SemanticInfoFocus : Theme.Colors.BorderNeutral2, lineWidth: 2))
            .focused($focused)
    }
}
