//
//  ConfirmDeleteAccountSheetView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

struct ConfirmDeleteAccountSheetView: View {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    
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
                    Text("Delete Account")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                
                Text("Are you sure? This cannot be undone and all your data will be lost.")
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral8)
                    .fixedSize(horizontal: false, vertical: true)
                
                WBlobkButton("Delete", imageName: "trash", imagePosition: .right) {
                    onConfirm()
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
    ConfirmDeleteAccountSheetView(isPresented: .constant(true)) {
        
    }
}
