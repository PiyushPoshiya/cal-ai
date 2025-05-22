//
//  ConversationExtrasView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-07.
//

import RealmSwift
import SwiftUI
import Mixpanel

struct ConversationExtrasView: View {
    
    @State private var presentEditFavouriteSheet: Bool = false

    @ObservedResults(
        MobileUserFavorite.self,
        sortDescriptor: SortDescriptor(keyPath: "timesLogged", ascending: false)
    ) var favorites
    var onFavorited: () -> Void
    
    var body: some View {
        Group {
            ScrollView(.vertical) {
                VStack (spacing: 0) {
                    HStack {
                        HStack {
                            Text("Favorites")
                                .fontWithLineHeight(Theme.Text.regularSemiBold)
                                .frame(alignment: .leading)
                            Spacer()
                            
                            ///MARK :- WEL-829: Add "manage favorites" button in Favorites drawer
                            ///Task :- Add Edit Button, open Edit Favorite Screen
                            ///Date :- 14 August, 2024
                            ///By Piyush Poshiya
                            
                            IconButtonView("edit", showBackgroundColor: true) {
                                Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Edit Favorites", "screen":"ConversationExtrasView"])
                                presentEditFavouriteSheet = true
                            }
                        }
                    }
                    if favorites.count == 0 {
                        Text("Long press on a food log inside the chat to add as favorite.")
                            .fontWithLineHeight(Theme.Text.smallRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral05)
                    } else {
                        WrappingHStack(
                            alignment: .topLeading,
                            horizontalSpacing: Theme.Spacing.small,
                            verticalSpacing: Theme.Spacing.large
                        ) {
                            ForEach(favorites, id: \.id) { favorite in
                                FavoriteShortcutView(favorite: favorite, onFavorited: onFavorited)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $presentEditFavouriteSheet) {
            AccountProfileFavoritesView()
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.medium)
        .background(Theme.Colors.SurfacePrimary100)
        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .move(edge: .bottom)))
    }
    
    func wrappingStackViewGenerator(favorite: MobileUserFavorite) -> FavoriteShortcutView {
        return FavoriteShortcutView(favorite: favorite, onFavorited: onFavorited)
    }
}

struct FavoriteShortcutView: View {
    @EnvironmentObject var realmDataManager: DM
    var favorite: MobileUserFavorite
    var onFavorited: () -> Void
    
    var body: some View {
        Text(favorite.key)
            .fontWithLineHeight(Theme.Text.regularSemiBold)
            .foregroundColor(Theme.Colors.TextPrimary100)
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, 9.5)
            .background(Theme.Colors.SurfaceNeutral05)
            .cornerRadius(Theme.Radius.full)
            .onTapGesture {
                Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Log Favorite", "screen":"FavoriteShortcutView"])
                Task {
                    try await realmDataManager.log(favorite: favorite)
                }
                onFavorited()
            }
//            .contextMenu {
//                Button(action: {
//                    // TODO: open profile
//                }) {
//                    Label("Edit", image: "edit")
//                }
//            }
    }
}

#Preview {
    ConversationExtrasView(onFavorited: {})
}

#Preview("Favorite Shortcut") {
    FavoriteShortcutView(favorite: MobileUserFavorite(id: "", key: "lunch1", messageId: "123"), onFavorited: {})
        .environmentObject(DM())
}
