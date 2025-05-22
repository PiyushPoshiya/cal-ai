//
//  ChatViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-18.
//

import Foundation
import os

@Observable
class ConversationScreenViewModel {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ConversationScreenViewModel.self)
    )
    
    var showProgressView: Bool = false
    
    var messageAppended: Bool = false
    var presentAddFavoriteSheet: Bool = false
    var foodLogMessageToFavorite: MobileMessage = .sample
    
    var editFoodLogEntry: Bool = false
    var foodLogEntryToEdit: MobileFoodLogEntry = .sample
    
    var editActivityLog: Bool = false
    var activityLogToEdit: MobilePhysicalActivityLog = .sample
    
    var editWeightLog: Bool = false
    var weightLogToEdit: MobileWeightLog = .sample
    
    var onTappedOutsideInput: Bool = false
    
    var logFoodOnListener: ((_ day: Date, _ forMeal: Meal) -> Void)?
    var logWeightListener: (() -> Void)?
    
    func onAppear(dm: DM, um: UserManager) {
        Task { @MainActor in
            
            if let onboardingState = um.user.onboardingState {
                if onboardingState.c1MessageGroupsSent == 0 {
                    try await Task.sleep(for: .milliseconds(800))
                    await OnboardingMessageSender.sendWelcomeMessage(dm: dm, um: um)
                }
            }
            
            try await dm.loadLatestChatHistory()
        }
    }
    
    func foodLogTapped(foodLogEntryToEdit: MobileFoodLogEntry) {
        self.foodLogEntryToEdit = foodLogEntryToEdit
        editFoodLogEntry = true
    }
    
    func activityLogTapped(activityLogToEdit: MobilePhysicalActivityLog) {
        self.editActivityLog = true
        self.activityLogToEdit = activityLogToEdit
    }
    
    func weightLogTapped(weightLogToEdit: MobileWeightLog) {
        self.editWeightLog = true
        self.weightLogToEdit = weightLogToEdit
    }
    
    func showAddFavoriteSheet(foodLogMessageToFavorite: MobileMessage) {
        self.foodLogMessageToFavorite = foodLogMessageToFavorite
        presentAddFavoriteSheet = true
    }
    
    @MainActor
    func logFoodOn(day: Date, forMeal: Meal) {
        showProgressView = false
        if let logFoodOnListener = logFoodOnListener {
            logFoodOnListener(day, forMeal)
        }
    }
    
    @MainActor
    func logWeight() {
        showProgressView = false
        if let logWeightListener = logWeightListener {
            logWeightListener()
        }
    }
}
