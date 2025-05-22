//
//  ErrorToastView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-06.
//

import PopupView
import SwiftUI

struct ErrorToastView: View {
    @Binding var title: String
    @Binding var message: String

    var body: some View {
        HStack {
            Group {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxxsmall) {
                    Text(title)
                        .fontWithLineHeight(Theme.Text.h5)
                    Text(message)
                        .fontWithLineHeight(Theme.Text.regularRegular)
                }
            }
            .padding(Theme.Spacing.xlarge)
            Spacer()
        }
        .background(Theme.Colors.SemanticWarning)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        .shadowedModalStyle()
        .padding(Theme.Spacing.small)
    }
}

#Preview {
    ErrorToastView(title: .constant("Error"), message: .constant("We could not save your favorite, please try again later"))
}
