//
//  SnapPictureButton.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-13.
//

import SwiftUI

struct SnapPictureButton: View {
    var disabled: Bool
    var action: () -> Void
    
    init(disabled: Bool, action: @escaping () -> Void) {
        self.disabled = disabled
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(disabled ? Theme.Colors.BorderNeutral3 : Theme.Colors.SurfaceSecondary100)
                Circle()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Theme.Colors.SurfacePrimary100)
            }
        }.disabled(disabled)

    }
}

#Preview {
    SnapPictureButton(disabled: false) {
        
    }
}
