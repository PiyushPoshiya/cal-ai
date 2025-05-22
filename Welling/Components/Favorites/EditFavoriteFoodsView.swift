//
//  EditFavoriteFoodsView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-27.
//

import SwiftUI

struct EditFavoriteFoodsView: View {
    @EnvironmentObject var dataManager: DM
    @EnvironmentObject var um: UserManager
    
    @Binding var favorite: FavoriteWithFoodLogEntry
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text(favorite.favorite.key)
                        .fontWithLineHeight(Theme.Text.h5)
                }
                HStack {
                    IconButtonView("arrow-left-long", showBackgroundColor: true) {
                        isPresented = false
                    }
                    
                    Spacer()
                }
            }
            .navbar()
            
            QuickEditFoodLogSheetView(foodLogEntry: favorite.foodLogEntry, isPresented: .constant(true), showNavBar: false, allowEditMealTime: false, isFavorite: true)
                .padding(.top, Theme.Spacing.medium)
                .padding(.horizontal, Theme.Spacing.small)
        }
        .background(Theme.Colors.SurfaceNeutral05)
    }
}

#Preview {
    EditFavoriteFoodsView(favorite: .constant(.empty), isPresented: .constant(true))
}
