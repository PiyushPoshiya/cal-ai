//
//  AccountProfileView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

struct AccountProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Profile")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                HStack {
                    IconButtonView("arrow-left-long", showBackgroundColor: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
            }
            .navbar()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.small) {
                    VStack(spacing: Theme.Spacing.medium) {
                        NavigationLink {
                            AccountProfilePersonalInfoView()
                                .withoutDefaultNavBar()
                        } label: {
                            AccountListItem(icon: "user-circle", name: "Personal Info")
                        }
                        
                        NavigationLink {
                            AccountProfileFavoritesView()
                                .withoutDefaultNavBar()
                        } label: {
                            AccountListItem(icon: "star", name: "Favorites")
                        }
                    }
                    .accountListSection()
                    
                    VStack(spacing: Theme.Spacing.medium) {
                        NavigationLink {
                            GoalsAndTargetView()
                                .withoutDefaultNavBar()
                        } label: {
                            AccountListItem(icon: "compass", name: "Goal and Calorie Targets")
                        }
                        
                        NavigationLink {
                            DietAndMacrosView()
                                .withoutDefaultNavBar()
                        } label: {
                            AccountListItem(icon: "orange-half", name: "Diet and Macro Ratios")
                        }
                        
                        NavigationLink {
                            RestrictionsView()
                                .withoutDefaultNavBar()
                        } label: {
                            AccountListItem(icon: "triangle", name: "Allergies and Restrictions")
                        }
                    }
                    .accountListSection()
                }
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
    }
}

#Preview {
    AccountProfileView()
}
