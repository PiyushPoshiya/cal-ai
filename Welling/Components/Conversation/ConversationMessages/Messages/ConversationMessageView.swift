//
//  ConversationMessageView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import RealmSwift
import SwiftUI

struct ConversationMessageView: View {
    @ObservedRealmObject var message: MobileMessage

    var body: some View {
        VStack {
            if message.fromSystem {
                ConversationMessageFromSystemView(message: message)
            } else {
                ConversationMessageFromUserView(message: message)
                    .padding(.leading, Theme.Spacing.small)
                    .padding(.trailing, message.state == .saved ? 0.0 : Theme.Spacing.small)
            }
        }
    }
}

struct ConversationMessageFromUserView: View {
    @ObservedRealmObject var message: MobileMessage
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if let _ = message.image {
                HStack (spacing: 3) {
                    ConversationMessageFromUserImageView(image: Binding<MobileMessageImage>($message.image)!)
                    if message.state == .saved {
                        Circle()
                            .fill(Theme.Colors.BorderNeutral3)
                            .frame(width: 6, height: 6)
                            .padding(.trailing, 3)
                    }
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            
            if let text = message.text {
                if !String.isNullOrEmpty(text) {
                    HStack (spacing: 3) {
                        ConversationMessageFromUserTextView(text: text)
                        if message.state == .saved {
                            Circle()
                                .fill(Theme.Colors.BorderNeutral3)
                                .frame(width: 6, height: 6)
                                .padding(.trailing, 3)
                        }
                    }
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                }
            }
            
            if message.state == .queued || message.state == .processing || message.state == .completed {
                if message.classification == .foodEaten || message.classification == .foodLogEdit {
                    ConversationMessageFoodLogPartView(message: message)
                } else if message.classification == MobileMessageClassification.activity {
                    ConversationMessageActivityLogPartView(message: message)
                } else if message.classification == MobileMessageClassification.weightLog {
                    ConversationMessageWeightLogPartView(message: message)
                } else if message.classification == MobileMessageClassification.logFavoriteFood {
                    if let favoriteFood = message.favoriteFood {
                        ConversationMessageFavoritedFoodPartView(favoritedFood: favoriteFood)
                    } else {
                        ConversationMessageFavoritedFoodPartView(favoritedFood: MobileFoodLogEntry.redacted)
                    }
                }
                
                if message.state != .completed {
                    HStack {
                        WellingBreathingIndicatorView()
                        Spacer()
                    }
                }
            } else if message.state == .sendingFailed {
                ConversationSomethingWentWrongView(title: "Something went wrong", message: "There seems to be an issue trying to process that message. Please try again later.")
            } else if message.state == .dailyOnTrialImageRateLimitExceeded {
                ConversationTrialLimitView(title: "You've hit your trial limit", message: "Your trial allows sending 3 photos a day. Please subscribe to a plan to send more or wait until tomorrow.")
            } else if message.state == .dailyOnTrialMessageRateLimitExceeded {
                ConversationTrialLimitView(title: "You've hit your trial limit", message: "Your trial allows sending 100 messages a day. Please subscribe to a plan to send more or wait until tomorrow.")
            } else if message.state == .dailySubscribedMessageRateLimitExceeded {
                ConversationSomethingWentWrongView(title: "You've hit your daily message limit", message: "Your plan allows sending up to 200 messages per day. Please wait until tomorrow to send more messages.")
            } else if message.state == .subscriptionExpired {
                ConversationTrialLimitView(title: "No active subscription", message: "You do not have an active subscription. Please subscribe to a plan to send messages.")
            } else {
                // Don't need to worry about this state on a user's msesage
                EmptyView()
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.medium) {
            ConversationMessageView(message: .saved)
        }
        .environmentObject(UserManager.sample)
    }
}

struct ConversationMessageFromSystemView: View {
    @ObservedRealmObject var message: MobileMessage
    
    var body: some View {
        VStack {
            if message.state != MessageProcessingState.error && message.messageType != MobileMessageType.error {
                if let text = message.text {
                    if !String.isNullOrEmpty(text) {
                        ConversationMessageFromSystemTextView(text: text)
                    }
                }
            } else {
                ConversationSomethingWentWrongView(title: "Something went wrong", message: message.text ?? "There seems to be an issue trying to process that message. Please try again later.")
            }
        }
    }
}
