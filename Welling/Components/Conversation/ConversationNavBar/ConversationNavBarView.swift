//
//  ConversationNavBarView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-27.
//

import SwiftUI
import RealmSwift
import Mixpanel

struct ConversationNavBarView: View {
    static let AnalyticsScreen: String = "Conversation"
    
    @Environment(ConversationScreenViewModel.self) var conversationViewMode: ConversationScreenViewModel
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @StateObject var viewModel: ConversationNavBarViewModel = ConversationNavBarViewModel()
    @Binding var showProgressView: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            IconButtonView("menu-scale", defaultPadding: false) {
                Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Progress View Icon", "screen": Self.AnalyticsScreen])
                showProgressView = true
            }
            .padding(.leading, Theme.Spacing.xxsmall)
            .padding(.trailing, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.xsmall)
            
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(viewModel.caloriesRemaining)
                    .fontWithLineHeight(Theme.Text.h4)
                    .padding(.leading, 0)
                Text("kcal remaining")
                    .fontWithLineHeight(Theme.Text.navBarSubheading)
                    .padding(.leading, Theme.Spacing.xxsmall)
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.small)
        .onAppear() {
            viewModel.onAppear(realmDataManager: dm, um: um)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
            viewModel.refresh()
       }
    }
}

#Preview {
    ConversationNavBarView(showProgressView: .constant(false))
        .environment(ConversationScreenViewModel())
        .environmentObject(UserManager.sample)
}
