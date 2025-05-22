//
//  SendButton.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-13.
//

import SwiftUI

struct SendButton: View {
    @Binding var isSaving: Bool
    let action: () -> Void
    
    init(isSaving: Binding<Bool>, action: @escaping () -> Void) {
        self.action = action
        self._isSaving = isSaving
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image("send-diagonal")
                .frame(width: 24, height: 24)
                .padding(0)
        }
        .disabled(isSaving)
        .primaryButton()
    }
}

#Preview {
    SendButton(isSaving: .constant(false)) {}
}
