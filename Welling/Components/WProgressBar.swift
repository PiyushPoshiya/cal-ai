//
//  WProgressBar.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-12.
//

import SwiftUI

struct WProgressBar: View {
    let value: CGFloat

    var body: some View {
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Rectangle()
            .frame(width: geometry.size.width, height: 4)
            .foregroundColor(.white)

          Rectangle()
            .frame(
              width: min(value * geometry.size.width,
                         geometry.size.width),
              height:4
            )
            .foregroundColor(Theme.Colors.SurfaceSecondary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
      }
      .frame(height: 4)
    }
}

#Preview {
    WProgressBar(value: 0.75)
}
