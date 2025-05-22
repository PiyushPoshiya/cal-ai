//
//  AddFavoriteView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-05.
//

import os
import SwiftUI

struct AddFavoriteView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AddFavoriteView.self))

    @EnvironmentObject var dataManager: DM
    @EnvironmentObject var modalManager: ModalManager
    @EnvironmentObject var um: UserManager
    @FocusState var focused: Bool
    @Binding var isPresented: Bool
    @State var favoriteName: String = ""
    @State var errorMessage: String = ""
    var foodLogMessageToFavorite: MobileMessage

    var body: some View {
        Group {
            if let foodLog = foodLogMessageToFavorite.foodLog {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxsmall) {
                            Text("Name Your Favorite")
                                .fontWithLineHeight(Theme.Text.h5)
                        }

                        Text(foodLog.userDescription)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral8)

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
                            if favoriteName.isEmpty {
                                errorMessage = "Please enter a name for your favorite."
                                return
                            }

                            for fav in um.user.favorites {
                                if fav.key.compare(favoriteName, options: .caseInsensitive) == .orderedSame {
                                    errorMessage = "A favorite by that name already exists"
                                    return
                                }
                            }
                            
                            Task {
                                do {
                                    try await dataManager.add(favorite: MobileUserFavorite(id: UUID().uuidString, key: favoriteName, messageId: foodLogMessageToFavorite.id), fromMessage: foodLogMessageToFavorite, forUser: um.user)
                                } catch {
                                    WLogger.shared.record(error)
                                    modalManager.showErrorToast(title: "Could not save", message: "I had a problem trying to save your favorite, please try again later")
                                }
                            }
                            isPresented = false
                        }

                        Text("Favorites appear in your keyboard shortcuts and can be managed in your Profile.")
                            .lineLimit(.none)
                            .multilineTextAlignment(.center)
                            .fontWithLineHeight(Theme.Text.smallRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral05)
                            .padding(.vertical, Theme.Spacing.medium)
                    }
                }
                .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .onAppear {
            favoriteName = ""
            focused = true
        }
    }
}

#Preview {
    AddFavoriteView(isPresented: .constant(true), foodLogMessageToFavorite: .sample)
        .environmentObject(UserManager.sample)
}
