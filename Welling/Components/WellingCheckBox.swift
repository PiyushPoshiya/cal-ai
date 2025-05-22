//
//  WellingCheckBox.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-20.
//

import SwiftUI

struct WellingCheckBox: View {
    @Binding var isOn: Bool
    var text: String
    
    var body: some View {
        Button() {
            isOn = !isOn
        } label: {
            HStack(alignment: .center, spacing: Theme.Spacing.xsmall) {
                VStack {
                    if isOn {
                        ColoredIconView(imageName: "check")
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 18, height: 18)
                .padding(1)
                .background(Theme.Colors.SurfacePrimary120)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xxsmall))
                
                Text(text)
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral9)
                Spacer()
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var checked: Bool = false
        
        var body: some View {
            VStack {
                WellingCheckBox(isOn: .constant(true), text: "Save for next time")
                Toggle(isOn: $checked) {
                    Text("hi")
                        .foregroundStyle(Theme.Colors.TextNeutral9)
                }
                .toggleStyle(WellingCheckboxStyle())
            }
            .card()
        }
    }
    return PreviewWrapper()
}

struct WellingCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        return Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(Theme.Colors.SurfaceNeutral05)
                        .frame(width: 18, height: 18)
                        .overlay(configuration.isOn ? RoundedRectangle(cornerRadius: 4).inset(by: 1)
                            .foregroundStyle(Theme.Colors.SurfaceSecondary100) : nil)
                }
            }
        }
    }
}
