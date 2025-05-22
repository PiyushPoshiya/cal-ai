//
//  ConversationMessageFoodLogPartView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-19.
//

import SwiftUI
import RealmSwift
import Mixpanel

struct ConversationMessageFoodLogPartView: View {
    @ObservedRealmObject var message: MobileMessage
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if message.foodLog?.isDeleted ?? false {
                VStack {
                    ///MARK :- WEL-877: Update text for food log edit notifications and loading
                    ///Task :- change notice text "Food log was deleted" to “Food log was updated”
                    ///Date :- 24 August, 2024
                    ///By Piyush Poshiya

                    Text("Food log was updated.")
                        .fontWithLineHeight(Theme.Text.smallItalic)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.clear)
            } else {
                if message.image != nil {
                    // Render the preview
                    ConversationMessageFromSystemTextView(text: "Okay, hold on.")
                        .frame(alignment: .leading)
                    if let foodLog = message.foodLog {
                        ConversationMessageFromSystemTextView(text: foodLog.summaryDisplayString())
                            .frame(alignment: .leading)
                    }
                } else {
                    
                    ///MARK :- WEL-877: Update text for food log edit notifications and loading
                    ///Task :- change loading text "Got it, let me log that for you." to “Got it, let me update that”
                    ///Date :- 24 August, 2024
                    ///By Piyush Poshiya

                    ConversationMessageFromSystemTextView(text: "Got it, let me update that.")
                        .frame(alignment: .leading)
                }
                
                FoodLogBubble(
                    message: message,
                    foodLogEntry: message.foodLog == nil ? .redacted : message.foodLog!,
                    redacted: message.foodLog == nil)
                
               
                if let foodLog = message.foodLog {
                    if let eval = foodLog.evaluation {
                        ConversationMessageFromSystemTextView(text: eval)
                            .padding(.horizontal, Theme.Spacing.small * -1)
                    }
                }
            }
        }
    }
}

fileprivate struct FoodLogBubble: View {
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    var message: MobileMessage
    var foodLogEntry: MobileFoodLogEntry
    var redacted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium)  {
            HStack {
                Image("apple")
                    .frame(width: 24, height: 24)
                Text(getFoodLogTitle())
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .redacted(reason: redacted ? .placeholder : [])
                    .shimmering(active: redacted)
                Spacer()
                ColoredIconView(imageName: "edit", foregroundColor: Theme.Colors.TextNeutral9)
            }
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxsmall) {
                Text("\(lround(foodLogEntry.calories))")
                    .fontWithLineHeight(Theme.Text.d2)
                    .kerning(1.0)
                    .redacted(reason: redacted ? .placeholder : [])
                    .shimmering(active: redacted)
                Text("kcal estimated")
                    .fontWithLineHeight(Theme.Text.mediumRegular)
                Spacer()
            }
            Text(foodLogEntry.shortSummaryDisplayString())
                .lineLimit(1)
                .truncationMode(.tail)
                .fontWithLineHeight(Theme.Text.regularRegular)
                .opacity(redacted ? 1 : 0.5)
                .redacted(reason: redacted ? .placeholder : [])
                .shimmering(active: redacted)
            HStack(spacing: 0) {
                Spacer()
                ConversationMessageFoodLogMacroView(macroName: "fat", amount: foodLogEntry.fat, unit: "g", redacted: redacted)
                Spacer()
                Divider()
                    .frame(width: 1)
                    .overlay(Theme.Colors.TextPrimary100)
                Spacer()
                ConversationMessageFoodLogMacroView(macroName: "carbs", amount: foodLogEntry.carbs, unit: "g", redacted: redacted)
                Spacer()
                Divider()
                    .frame(width: 1)
                    .overlay(Theme.Colors.TextPrimary100)
                Spacer()
                ConversationMessageFoodLogMacroView(macroName: "protein", amount: foodLogEntry.protein, unit: "g", redacted: redacted)
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.xlarge)
        .padding(.vertical, Theme.Spacing.large)
        .background(Theme.Colors.SurfaceSecondary100)
        .foregroundStyle(Theme.Colors.TextPrimary100)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        .contextMenu {
            Button(action: {
                if redacted {
                    return
                }
                
                Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Food Log Bubble Context - Favorite", "screen":"ConversationMessagesView"])
                self.conversationScreenViewModel.showAddFavoriteSheet(foodLogMessageToFavorite: message)
            }) {
                Label("Favorite", image: "heart")
            }
        }
        .onTapGesture {
            if redacted {
                return
            }
            
            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Food Log Bubble", "screen":"ConversationMessagesView"])
            self.conversationScreenViewModel.foodLogTapped(foodLogEntryToEdit: self.foodLogEntry)
        }
    }
    
    func getFoodLogTitle() -> String {
        let dateString = Date.dateLoggedFormatter.string(from: foodLogEntry.timestamp)
        guard let meal = foodLogEntry.meal else {
            return "Added to your food log for \(dateString)"
        }
        
        if meal == .snack {
            return "Added to snacks on \(dateString)"
        }
        
        return "Added to \(meal.rawValue) on \(dateString)"
    }
}

fileprivate struct ConversationMessageFoodLogMacroView: View {
    var macroName: String
    var amount: Double
    var unit: String
    var redacted: Bool
    
    var body: some View {
        VStack {
            Text("\(Int(floor(amount))) \(unit)")
                .fontWithLineHeight(Theme.Text.largeSemiBold)
                .redacted(reason: redacted ? .placeholder : [])
                .shimmering(active: redacted)
            Text(macroName)
                .fontWithLineHeight(Theme.Text.tinyRegular)
                .opacity(0.5)
        }
    }
}

#Preview {
    ConversationMessageFoodLogPartView(message: .withFoodLog)
}
