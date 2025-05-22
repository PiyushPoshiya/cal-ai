//
//  ColoredIconView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-18.
//

import SwiftUI

struct ColoredIconView: View {
    let imageName: String
    let foregroundColor: Color
    
    init(imageName: String, foregroundColor: Color = Theme.Colors.TextNeutral9) {
        self.imageName = imageName
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Image(imageName)
            .renderingMode(.template)
            .foregroundStyle(foregroundColor)
            .frame(width: 24, height: 24)
    }
}

#Preview {
    ColoredIconView(imageName: "apple.logo")
}
