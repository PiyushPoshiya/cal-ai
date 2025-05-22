//
//  EditFavoriteView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-27.
//

import SwiftUI
import os

fileprivate enum Field {
    case description
    case keyword
}

struct EditFavoriteView: View {
    static let loggerCategory =  String(describing: EditFavoriteView.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)
    
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    
    @Binding var isPresented: Bool
    @State var favoriteName: String = ""
    @State var errorMessage: String = ""
    @FocusState var focused: Bool
    @Binding var favorite: FavoriteWithFoodLogEntry
    @State var presentEditFoodLogSheet: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconButtonView("xmark", showBackgroundColor: true, text: "Cancel") {
                    isPresented = false
                }
                Spacer()
            }
            .sheetNavbar()
            
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxsmall) {
                    Text("Favorite")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                
                Button {
                    presentEditFoodLogSheet = true
                } label: {
                    HStack {
                        Text(favorite.foodLogEntry.shortSummaryDisplayString())
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral8)
                        Spacer()
                        
                        ColoredIconView(imageName: "edit", foregroundColor: Theme.Colors.Neutral7)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    TextField("Name", text: $favoriteName)
                        .focused($focused)
                        .textFieldStyle(WellingTextFeldStyle())
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit {
                            focused = false
                        }
                    Text(errorMessage)
                        .lineLimit(1, reservesSpace: true)
                        .fontWithLineHeight(Theme.Text.smallRegular)
                        .foregroundStyle(Theme.Colors.TextSecondary100)
                        .padding(.top, Theme.Spacing.xxsmall)
                }
                .padding(.top, Theme.Spacing.small)
                .padding(.bottom, Theme.Spacing.small)

                WBlobkButton("Save", imageName: "check", imagePosition: .right) {
                    WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
                    
                    if favoriteName.isEmpty {
                        errorMessage = "Please enter a name for your favorite."
                        return
                    }

                    for fav in um.user.favorites {
                        if fav.messageId != favorite.favorite.messageId && fav.key.compare(favoriteName, options: .caseInsensitive) == .orderedSame {
                            errorMessage = "A favorite by that name already exists"
                            return
                        }
                    }
                    
                    Task { @MainActor in
                        do {
                            try await dm.update(foodLogFavorite: favorite.favorite, key: favoriteName, forUser: um.user)
                        } catch {
                            WLogger.shared.record(error)
                        }
                    }
                    isPresented = false
                }
            }
            .card()
        }
        .padding(.top, Theme.Spacing.medium)
        .padding(.horizontal, Theme.Spacing.small)
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            favoriteName = favorite.favorite.key
        }
        .sheet(isPresented: $presentEditFoodLogSheet) {
            EditFavoriteFoodsView(favorite: $favorite,  isPresented: $presentEditFoodLogSheet)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    EditFavoriteView(isPresented: .constant(false), favorite: .constant(FavoriteWithFoodLogEntry(favorite: .sample, foodLogEntry: .sample)))
}

class EditFavoriteViewModel: ObservableObject {
    
}
