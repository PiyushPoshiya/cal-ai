//
//  SettingsCheckboxView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-20.
//

import SwiftUI

struct SettingsCheckboxView: View {
    var title: String
    @Binding var isOn: Bool
    var font: FontWithLineHeightProps = Theme.Text.mediumRegular
    var onTap: (_ selected: String) -> Void
    
    var body: some View {
        Button {
            onTap(title)
        } label: {
            HStack {
                Text(title)
                    .fontWithLineHeight(font)
                    .foregroundStyle(Theme.Colors.TextNeutral9)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(Theme.Colors.SurfaceNeutral05)
                        .frame(width: 18, height: 18)
                        .overlay(isOn ? RoundedRectangle(cornerRadius: 4).inset(by: 1)
                            .foregroundStyle(Theme.Colors.SurfaceSecondary100) : nil)
                }
            }
        }
    }
}
