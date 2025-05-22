//
//  ConfirmDeleteFoodLogView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-18.
//

import SwiftUI

struct ConfirmDeleteSheetView: View {
    @Binding var isPresented: Bool
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            HStack {
                IconButtonView("xmark", showBackgroundColor: true, text: "Cancel") {
                    isPresented = false
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxsmall) {
                    Text("Confirm")
                        .fontWithLineHeight(Theme.Text.h5)
                }

                Text("This cannot be undone.")
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral8)

                WBlobkButton("Delete", imageName: "trash", imagePosition: .right) {
                    onDelete()
                }
            }
            .card()
        }
        .padding(.top, Theme.Spacing.medium)
        .padding(.horizontal, Theme.Spacing.small)
        .background(Theme.Colors.SurfaceNeutral05)
    }
}

#Preview {
    ConfirmDeleteSheetView(isPresented: .constant(false)) {
    }
}
