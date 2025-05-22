//
//  AccountProfileFavoritesView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-27.
//

import SwiftUI
import os

struct AccountProfileFavoritesView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var dm: DM
    @State private var sheetHeight: CGFloat = .zero
    @StateObject var viewModel: AccountProfileFavoritesViewModel = AccountProfileFavoritesViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Favorites")
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
                VStack (spacing: Theme.Spacing.small) {
                    ForEach($viewModel.favorites, id: \.favorite.id) { favorite in
                        AccountProfileFavoritesListView(favorite: favorite, onDelete: viewModel.onDelete)
                            .onTapGesture {
                                viewModel.onEdit(favorite: favorite.wrappedValue)
                            }
                    }
                    
                    Spacer()
                        .frame(height: Theme.Spacing.xxlarge)
                    
                    Text("Long press on a food log inside the chat to add as favorite.")
                        .fontWithLineHeight(Theme.Text.smallRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral05)
                }
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            viewModel.onAppear(dm: dm, user: userManager.user)
        }
        .sheet(isPresented: $viewModel.presentConfirmDeleteSheet) {
            ConfirmDeleteSheetView(isPresented: $viewModel.presentConfirmDeleteSheet) {
                Task { @MainActor in
                    await viewModel.handleDeleteConfirmed(dm: self.dm, um: self.userManager)
                }
            }
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $viewModel.presentEditSheet) {
            EditFavoriteView(isPresented: $viewModel.presentEditSheet, favorite: $viewModel.favoriteToEdit)
                .modifier(GetHeightModifier(height: $sheetHeight))
                .presentationDetents([.height(sheetHeight)])
        }
    }
}

fileprivate struct AccountProfileFavoritesListView: View {
    @Binding var favorite: FavoriteWithFoodLogEntry
    var onDelete: (_ favorite: FavoriteWithFoodLogEntry) -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            ColoredIconView(imageName: "edit", foregroundColor: Theme.Colors.Neutral7)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(favorite.favorite.key)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
                    .lineLimit(1)
                
                Text(favorite.foodLogEntry.shortSummaryDisplayString())
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.Neutral7)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            IconButtonView("trash", showBackgroundColor: false, foregroundColor: Theme.Colors.Neutral7) {
                onDelete(favorite)
            }
        }
        .detailCard()
    }
}

#Preview {
    AccountProfileFavoritesView()
}

@MainActor
class AccountProfileFavoritesViewModel: ObservableObject {
    static let loggerCategory =  String(describing: AccountProfileFavoritesViewModel.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)
    
    @Published var favorites: [FavoriteWithFoodLogEntry] = []
    @Published var presentConfirmDeleteSheet: Bool = false
    @Published var presentEditSheet: Bool = false
    
    var favoriteToEdit: FavoriteWithFoodLogEntry = .empty
    var favoriteToDelete: FavoriteWithFoodLogEntry? = nil
    
    @MainActor
    func onAppear(dm: DM, user: WellingUser) {
        favorites = dm.listFavoritesWithFoods(favorites: user.favorites)
    }
    
    func onDelete(favorite: FavoriteWithFoodLogEntry) {
        favoriteToDelete = favorite
        presentConfirmDeleteSheet = true
    }
    
    func onEdit(favorite: FavoriteWithFoodLogEntry) {
        favoriteToEdit = favorite
        presentEditSheet = true
    }
    
    @MainActor
    func handleDeleteConfirmed(dm: DM, um: UserManager) async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let favorite = favoriteToDelete?.favorite else {
            presentConfirmDeleteSheet = false
           return
        }
       
        do {
            try await dm.delete(foodLogFavorite: favorite, forUser: um.user)
            favorites = dm.listFavoritesWithFoods(favorites: um.user.favorites)
            presentConfirmDeleteSheet = false
        } catch {
            WLogger.shared.record(error)
        }
    }
}
