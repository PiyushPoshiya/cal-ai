//
//  WBlobkButton.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-01.
//

import SwiftUI

enum ImagePosition {
    case left
    case right
    case farRight
}

struct WBlobkButton: View {
    @Binding var isDisabled: Bool
    let title: LocalizedStringKey
    let imageName: String?
    let imagePosition: ImagePosition?
    let action: () -> Void
    let backgroundColor: Color

    init(_ title: LocalizedStringKey, isDisabled: Binding<Bool> = .constant(false), imageName: String? = nil, imagePosition: ImagePosition? = nil, backgroundColor: Color = Theme.Colors.SurfaceSecondary100, action: @escaping () -> Void) {
        self._isDisabled = isDisabled
        self.title = title
        self.imageName = imageName
        self.imagePosition = imagePosition
        self.action = action
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        Button(action: action, label: {
            HStack(alignment: .center, spacing: Theme.Spacing.small) {
                if imagePosition == .left {
                    if let _img = imageName {
                        ColoredIconView(imageName: _img)
                    }
                }
                Text(title)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
                    .foregroundStyle(Theme.Colors.TextNeutral9)
                if imagePosition == .right {
                    if let _img = imageName {
                        ColoredIconView(imageName: _img)
                    }
                } else if imagePosition == .farRight {
                    if let _img = imageName {
                        Spacer()
                        ColoredIconView(imageName: _img)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        })
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(backgroundColor)
        .cornerRadius(Theme.Radius.full)
    }
}

#Preview {
    WBlobkButton("Save", imageName: "trash", imagePosition: .right) {}
}
