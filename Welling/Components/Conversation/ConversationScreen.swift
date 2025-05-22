//
//  ChatView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-18.
//

import SwiftUI
import Mixpanel

struct ConversationScreen: View {
    static let AnalyticsScreen: String = "Conversation"
    
    @EnvironmentObject var realmDataManager: DM
    @EnvironmentObject var um: UserManager
    @State var viewModel: ConversationScreenViewModel = .init()
    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        VStack {
            // Nav bar
            ConversationNavBarView(showProgressView: $viewModel.showProgressView)
                .onTapGesture {
                    viewModel.onTappedOutsideInput = !viewModel.onTappedOutsideInput
                }
            // Conversation messages
            ConversationMessagesView()
                .onTapGesture {
                    viewModel.onTappedOutsideInput = !viewModel.onTappedOutsideInput
                }
            ConversationInputView()
                .frame(alignment: .bottomTrailing)
        }
        .onChange(of: viewModel.showProgressView, self.handleOnSheetPresentationChanged)
        .onChange(of: viewModel.editFoodLogEntry, self.handleOnSheetPresentationChanged)
        .onChange(of: viewModel.editActivityLog, self.handleOnSheetPresentationChanged)
        .onChange(of: viewModel.editWeightLog, self.handleOnSheetPresentationChanged)
        .onChange(of: viewModel.presentAddFavoriteSheet, self.handleOnSheetPresentationChanged)
        .onAppear {
            viewModel.onAppear(dm: realmDataManager, um: um)
            NavigationState.shared.areConversationMessagesVisible = true
            if NavigationState.shared.areConversationMessagesScrolledToBottom {
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
        .onDisappear {
            NavigationState.shared.areConversationMessagesVisible = false
        }
        .sheet(isPresented: $viewModel.showProgressView) {
            StatsScreenView(showProgressView: $viewModel.showProgressView)
                .id(HomeViewScreen.stats)
        }
        .sheet(isPresented: $viewModel.editFoodLogEntry) {
            QuickEditFoodLogSheetView(foodLogEntry: viewModel.foodLogEntryToEdit, isPresented: $viewModel.editFoodLogEntry)
                .sheet()
        }
        .sheet(isPresented: $viewModel.editActivityLog) {
            QuickEditActivityLogView(activityLog: $viewModel.activityLogToEdit, isPresented: $viewModel.editActivityLog)
                .sheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.editWeightLog) {
            QuickEditWeightLogView(weightLog: viewModel.weightLogToEdit, isPresented: $viewModel.editWeightLog)
                .sheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.presentAddFavoriteSheet) {
            VStack {
                AddFavoriteView(isPresented: $viewModel.presentAddFavoriteSheet, foodLogMessageToFavorite: viewModel.foodLogMessageToFavorite)
                Spacer()
            }
            .sheet()
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.automatic)
            .environment(viewModel)
        }
        .environment(viewModel)
    }
    
    func handleOnSheetPresentationChanged(oldVal: Bool, newVal: Bool) {
        NavigationState.shared.areConversationMessagesVisible = !newVal
    }
}

#Preview {
    ConversationScreen()
        .environmentObject(DM())
        .environmentObject(UserManager.sample)
}
