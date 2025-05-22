//
//  ConversationMessageActivityLogPartView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-24.
//

import SwiftUI
import RealmSwift

struct ConversationMessageActivityLogPartView: View {
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    @ObservedRealmObject var message: MobileMessage
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if message.activityLog?.isDeleted ?? false {
                VStack {
                    Text("Activity log was deleted")
                        .fontWithLineHeight(Theme.Text.smallItalic)
                        .foregroundStyle(Theme.Colors.TextPrimary100)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.clear)
            } else {
                ConversationMessageFromSystemTextView(text: "Great, let me log that.")
                    .frame(alignment: .leading)
                
                ActivityLogBubble(activityLog: message.activityLog == nil ? .redacted : message.activityLog!, redacted: message.activityLog == nil)
                
                if let activityLog = message.activityLog {
                    if let eval = activityLog.evaluation {
                        ConversationMessageFromSystemTextView(text: eval)
                            .padding(.horizontal, Theme.Spacing.small * -1)
                    }
                }
            }
        }
    }
}

fileprivate struct ActivityLogBubble: View {
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    var activityLog: MobilePhysicalActivityLog
    var redacted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Image("gym")
                    .frame(width: 24, height: 24)
                Text("\(Self.getDateLoggedString(activityLog))")
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
                Text("\(lround(activityLog.caloriesExpended))")
                    .fontWithLineHeight(Theme.Text.d2)
                    .kerning(1.0)
                    .redacted(reason: redacted ? .placeholder : [])
                    .shimmering(active: redacted)
                Text("kcal")
                    .fontWithLineHeight(Theme.Text.mediumRegular)
                Spacer()
            }
            .frame(alignment: .leading)
            
            Text("\(activityLog.name), \(activityLog.amount)")
                .lineLimit(1)
                .truncationMode(.tail)
                .fontWithLineHeight(Theme.Text.largeRegular)
                .foregroundStyle(Theme.Colors.TextNeutral05)
                .redacted(reason: redacted ? .placeholder : [])
                .shimmering(active: redacted)
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
            
            self.conversationScreenViewModel.activityLogTapped(activityLogToEdit: activityLog)
        }
    }
    
    static func getDateLoggedString(_ activityLogged: MobilePhysicalActivityLog) -> String {
        return "Added to activity on \(Date.dateLoggedFormatter.string(from: activityLogged.timestamp))"
    }
}
