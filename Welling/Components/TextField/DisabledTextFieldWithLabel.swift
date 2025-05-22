//
//  DisabledTextFieldWithLabel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-27.
//

import SwiftUI

struct DisabledTextFieldWithLabel: View {
    var label: String
    var value: String
    
    var body: some View {
        VStack {
            VStack(spacing: Theme.Spacing.xxsmall * -1) {
                HStack {
                    Text(label)
                        .fontWithLineHeight(Theme.Text.tinyMedium)
                        .opacity(0.75)
                        .frame(alignment: .leading)
                    Spacer()
                }
                HStack {
                    Text(value)
                        .fontWithLineHeight(Theme.Text.mediumMedium)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .wellingTextFieldStyleWithTitle(focused: false, disabled: true)
        }
    }
}


fileprivate enum Field: Hashable {
    case A
}

#Preview {
    HStack {
        TextFieldWithLabel<Field>(label: "Name", placeholder: "Name", value: .constant("Irwin"), focused: FocusState<Field?>().projectedValue, field: .A, keyboardType: .numberPad)
        
        DisabledTextFieldWithLabel(label: "Email", value: "irwin.billing@gmail.com")
    }
}
