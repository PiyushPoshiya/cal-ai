//
//  ProgressView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-01.
//

import SwiftUI

struct StatsScreenView: View {
    @Binding var showProgressView: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0){
                HStack(alignment: .center, spacing: Theme.Spacing.xsmall) {
                    IconButtonView("xmark", showBackgroundColor: true) {
                        showProgressView = false
                    }
                    Spacer()
                    Text("Progress")
                        .fontWithLineHeight(Theme.Text.h5)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                    Spacer()
                    NavigationLink {
                       AccountView()
                            .withoutDefaultNavBar()
                    } label: {
                        ColoredIconView(imageName: "user-circle", foregroundColor: Theme.Colors.TextNeutral9)
                            .iconButton()
                    }
                }
                .navbar()
                
                ProgressOverviewView()
                Spacer()
            }
            .background(Theme.Colors.SurfaceNeutral05)
        }
    }
}

#Preview {
    StatsScreenView(showProgressView: .constant(false))
}
