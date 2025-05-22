//
//  ConverstionMessageParts.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import Shimmer
import SwiftUI
import UniformTypeIdentifiers
import NukeUI
import SuperwallKit

struct ConversationMessageFromUserTextView: View {
    var text: String
    
    var body: some View {
        HStack {
            Text(text)
                .fontWithLineHeight(Theme.Text.largeRegular)
                .foregroundStyle(Theme.Colors.TextPrimary100)
                .padding(Theme.Spacing.medium)
                .background(Theme.Colors.SurfaceNeutral2)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Theme.Radius.large))
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.setValue(self.text,
                                                      forPasteboardType: UTType.plainText.identifier)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
        }
        .padding(.leading, Theme.Spacing.xxlarge)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct ConversationMessageFromUserImageView: View {
    @Environment(\.displayScale) private var displayScale
    @Binding var image: MobileMessageImage
    
    var body: some View {
        HStack {
            Spacer()
            ConversationImageView(image: $image)
        }
    }
}

struct ConversationMessageFromSystemTextView: View {
    var text: String
    
    var body: some View {
        VStack {
            textView(text)
                .fontWithLineHeight(Theme.Text.largeRegular)
                .foregroundStyle(Theme.Colors.TextPrimary100)
                .padding(.horizontal, Theme.Spacing.small)
                .padding(.vertical, Theme.Spacing.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.SurfaceNeutral05)
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Theme.Radius.large))
        .contextMenu {
            Button(action: {
                UIPasteboard.general.setValue(self.text,
                                              forPasteboardType: UTType.plainText.identifier)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
    
    @ViewBuilder
    private func textView(_ text: String) -> some View {
        if let attributed = try? AttributedString(markdown: text, options: String.markdownOptions) {
            Text(attributed)
        } else {
            Text(text)
        }
    }
}

struct ConversationSomethingWentWrongView: View {
    var title: String
    var message: String
    
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                HStack {
                    Text(title)
                        .fontWithLineHeight(Theme.Text.h5)
                    Spacer()
                }
                Text(message)
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            .padding(.horizontal, Theme.Spacing.xlarge)
            .padding(.vertical, Theme.Spacing.large)
            .background(Theme.Colors.SemanticWarning)
            .foregroundStyle(Theme.Colors.TextPrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        }
        .padding(.horizontal, Theme.Spacing.small)
    }
}

struct ConversationTrialLimitView: View {
    @EnvironmentObject var modalManager: ModalManager
    @EnvironmentObject var userManager: UserManager
    
    var title: String
    var message: String
    
    var body: some View {
        Button {
            Task { @MainActor in
                switch Superwall.shared.subscriptionStatus {
                case .active:
                    modalManager.showAlertModal(title: "Already Subscribed")
                case .inactive, .unknown:
                    Superwall.shared.register(event: "trial_expired_message_tap") {
                        // Reload user.
                        Task { @MainActor in
                            await userManager.reloadUserFromAPI()
                        }
                    }
                }
            }
        } label: {
            HStack (alignment: .top, spacing: Theme.Spacing.xxsmall) {
                VStack (alignment: .leading, spacing: Theme.Spacing.xxxsmall) {
                    Text(title)
                        .fontWithLineHeight(Theme.Text.h5)
                    Text(message)
                        .fontWithLineHeight(Theme.Text.regularRegular)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                ColoredIconView(imageName: "arrow-right", foregroundColor: Theme.Colors.TextNeutral9)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .padding(.vertical, Theme.Spacing.xsmall)
                    .background(Theme.Colors.SurfaceNeutral2)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
            }
            .padding(.horizontal, Theme.Spacing.xlarge)
            .padding(.vertical, Theme.Spacing.large)
            .background(Theme.Colors.SemanticValidated)
            .foregroundStyle(Theme.Colors.TextNeutral9)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        }
    }
}

struct ConversationMessageFavoritedFoodPartView: View {
    var favoritedFood: MobileFoodLogEntry
    
    var body: some View {
        VStack {
            Text(favoritedFood.description)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.medium) {
            ConversationMessageFromSystemTextView(text: "How is coffee in the morning")
        }
    }
}
