//
//  ConfirmSignOutSheetView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

struct ConfirmSignOutSheetView: View {
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
                    Text("Sign Out")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                
                Text("Are you sure?")
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral8)
                
                WBlobkButton("Sign Out", imageName: "running", imagePosition: .right) {
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
    ConfirmSignOutSheetView(isPresented: .constant(true)) {
        
    }
}
