//
//  ConversationInputViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//
import Foundation
import os
import RealmSwift
import SuperwallKit

/**
 States
 - typing -> open extras, open camera, close typing
 - Tap anywhere else like chat scroll view, close keyboard
 - open extras -> open camera, start typing, close extras, close
 - Tap anywhere else like chat scroll view, close extras
 - Open camera
 */

enum ConversationinputViewState: Equatable {
    case idle
    case keyboard
    case extras
    case camera
}

extension ConversationInputView {
    @Observable
    @MainActor
    class ViewModel {
        static let loggerCategory =  String(describing: ViewModel.self)
        private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: ViewModel.self)
        )
        
        var inputText: String = ""
        var viewState: ConversationinputViewState = .idle
        var inputTextFieldHasFocus: Bool = false
        var presentCameraInput: Bool = false
        @ObservationIgnored private var lastMealHint: Meal?
        
        func onAppear(conversationScreenViewModel: ConversationScreenViewModel) {
            conversationScreenViewModel.logFoodOnListener = logFoodOn
            conversationScreenViewModel.logWeightListener = onLogWeightShortcut
        }
        
        func logFoodOn(day: Date, forMeal: Meal) {
            viewState = .keyboard
            inputTextFieldHasFocus = true
            //        lastMealHint = forMeal
            switch forMeal {
            case .breakfast, .lunch, .dinner:
                inputText = "On \(Date.logFoodForMealFormatter.string(from: day)) for \(forMeal.rawValue), I had "
            case .snack:
                inputText = "On \(Date.logFoodForMealFormatter.string(from: day)), for a snack I had "
            }
        }
        
        func onLogWeightShortcut() {
            viewState = .keyboard
            inputTextFieldHasFocus = true
            inputText = "I weigh "
        }
        
        @MainActor
        func onFavorited() {
            viewState = .idle
            inputTextFieldHasFocus = false
            presentCameraInput = false
        }
        
        func onCameraButtonTapped() {
            viewState = .camera
            inputTextFieldHasFocus = false
            presentCameraInput = true
        }
        
        func onExtrasButtonTapped() {
            if viewState == .extras {
                viewState = .idle
                inputTextFieldHasFocus = false
                
            } else {
                viewState = .extras
                inputTextFieldHasFocus = false
            }
        }
        
        func onTextFieldGainedFocus(focused: Bool) {
            if focused {
                viewState = .keyboard
            }
            inputTextFieldHasFocus = focused
        }
        
        func onTappedOutsideInput() {
            viewState = .idle
            inputTextFieldHasFocus = false
        }
        
        @MainActor
        func handleSendButton(realmDataManager: DM, text: String, meal: Meal?, localImagePath: String?, onMessageSaved: @escaping () -> Void) {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
            
            Task { @MainActor in
                do {
                    let message = MobileMessage()
                    message._version = 1
                    message.id = UUID().uuidString
                    message.text = text.trimmingCharacters(in: .whitespaces)
                    message.state = MessageProcessingState.saved
                    message.messageType = MobileMessageType.other
                    message.mealHint = meal ?? lastMealHint
                    message.fromSystem = false
                    message.replies = List()
                    message.timestamp = Date()
                    
                    try await realmDataManager.saveMessageForSending(message: message, localImagePath: localImagePath)
                    
                    // If we don't do this, sometimes the TextView continues to render the old value, and we end up having the value overlapping the placeholder
                    // https://stackoverflow.com/a/71259886
                    DispatchQueue.main.async {
                        self.inputText = ""
                        self.viewState = .idle
                        DispatchQueue.main.async {
                            self.inputText = ""
                            DispatchQueue.main.async {
                                self.inputText = ""
                            }
                        }
                    }
                    onMessageSaved()
                    
                    await self.sendMessage(dm: realmDataManager, message: message)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
        
        func paywallHandler(um: UserManager, feature: @escaping () -> Void) -> PaywallPresentationHandler {
            let handler: PaywallPresentationHandler = PaywallPresentationHandler()
            
            handler.onDismiss { paywallInfo in
                Task { @MainActor in
                    await um.reloadUserFromAPI()
                    feature()
                }
            }
            
            handler.onSkip { reason in
                switch reason {
                case .holdout(let experiment):
                    return
                case .noRuleMatch:
                    return
                case .eventNotFound:
                    return
                case .userIsSubscribed:
                    feature()
                    return
                }
            }
            
            return handler
        }
        
        @MainActor
        func sendMessage(dm: DM, message: MobileMessage) async -> Void {
            do {
                let result = try await dm.sendMessage(message: message)
                
                if let error = result.error {
                    Self.logger.error("Error sending message, updating local state: \(error.cause)")
                    try await dm.updateMessageState(message: message, state: MessageProcessingState.sendingFailed)
                } else if result.statusCode != 200 {
                    Self.logger.error("Something went wrong sending message. Status code: \(result.statusCode)")
                    try await dm.updateMessageState(message: message, state: messageProcessingStateFrom(statusCode: result.statusCode))
                }
            } catch {
                Self.logger.error("Something went wrong sending the message: \(error)")
            }
        }
        
        func messageProcessingStateFrom(statusCode: Int) -> MessageProcessingState {
            if statusCode == 402 {
                // TODO, if this happens, check locally if we actually do have a subscription.
                // if we do, reload current user, and re-send the message!
                return .subscriptionExpired
            } else if statusCode == 432 {
                return .dailyOnTrialMessageRateLimitExceeded
            } else if statusCode == 433 {
                return .dailyOnTrialImageRateLimitExceeded
            } else if statusCode == 434 {
                return .dailySubscribedMessageRateLimitExceeded
            } else {
                return .sendingFailed
            }
        }
    }
}
