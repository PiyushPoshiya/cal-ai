//
//  ConversationMessageWeightLogPartView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-24.
//

import SwiftUI
import RealmSwift

struct ConversationMessageWeightLogPartView: View {
    @ObservedRealmObject var message: MobileMessage
    
    var body: some View {
        VStack {
            if message.weightLog?.isDeleted ?? false {
                VStack {
                    Text("Weight log was deleted")
                        .fontWithLineHeight(Theme.Text.smallItalic)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.clear)
            } else {
                ConversationMessageFromSystemTextView(text: "Okay, hold on.")
                    .frame(alignment: .leading)
                
                WeightLogBubble(weightLog: message.weightLog == nil ? .redacted : message.weightLog!, redacted: message.weightLog == nil)
                
                if let weightLog = message.weightLog {
                    if let eval = weightLog.evaluation {
                        ConversationMessageFromSystemTextView(text: eval)
                            .padding(.horizontal, Theme.Spacing.small * -1)
                    }
                }
            }
        }
    }
}

fileprivate struct WeightLogBubble: View {
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    @EnvironmentObject var um: UserManager
    var weightLog: MobileWeightLog
    var redacted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Image("graph-down")
                    .frame(width: 24, height: 24)
                Text("\(Self.getDateLoggedString(weightLog))")
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral05)
                    .redacted(reason: redacted ? .placeholder : [])
                    .shimmering(active: redacted)
                Spacer()
                ColoredIconView(imageName: "edit", foregroundColor: Theme.Colors.TextNeutral9)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxsmall) {
                Text("\(UnitUtils.getWeightString(weightLog.weightInKg, um.user.profile?.preferredUnits))")
                    .fontWithLineHeight(Theme.Text.h1)
                    .redacted(reason: redacted ? .placeholder : [])
                    .shimmering(active: redacted)
                Text(um.user.profile?.preferredUnits == MeasurementUnit.imperial ? "lb" : "kg")
                    .fontWithLineHeight(Theme.Text.mediumRegular)
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.xlarge)
        .padding(.vertical, Theme.Spacing.large)
        .background(Theme.Colors.SurfaceSecondary100)
        .foregroundStyle(Theme.Colors.TextPrimary100)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        .onTapGesture {
            if redacted {
                return
            }
            self.conversationScreenViewModel.weightLogTapped(weightLogToEdit: self.weightLog)
        }
    }
    
    static func getDateLoggedString(_ weightLog: MobileWeightLog) -> String {
        return "Added to weight on \(Date.dateLoggedFormatter.string(from: weightLog.timestamp))"
    }
}
