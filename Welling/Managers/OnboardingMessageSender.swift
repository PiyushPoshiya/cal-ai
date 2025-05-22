//
//  OnboardingMessageSender.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-17.
//

import Foundation
import RealmSwift
import os

fileprivate struct OnboardingMessage {
    let message: String
    let secondsDelayUntilNextMessage: Int
    let ignoreForPrompt: Bool
    
    init(_ message: String, _ secondsDelayUntilNextMessage: Int, _ ignoreForPrompt: Bool = false) {
        self.message = message
        self.secondsDelayUntilNextMessage = secondsDelayUntilNextMessage
        self.ignoreForPrompt = ignoreForPrompt
    }
}

@MainActor
class OnboardingMessageSender {
    static let loggerCategory =  String(describing: OnboardingMessageSender.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )
    
    static let C1MessagesCount: Int = 1
    static let semaphore = AsyncSemaphore(value: 1)
    
    @MainActor
    private static func getWelcomeMessagesSent(toUid: String, groupIndex: Int) -> Int {
        return UserDefaults.standard.integer(forKey: "\(toUid)/groupIndex.c1MessageGroupsSent.\(groupIndex)")
    }
    
    @MainActor
    private static func setWelcomeMessagesSent(toUid: String, groupIndex: Int, count: Int) {
        UserDefaults.standard.set(count, forKey: "\(toUid)/groupIndex.c1MessageGroupsSent.\(groupIndex)")
    }
    
    @MainActor
    static func sendWelcomeMessage(dm: DM, um: UserManager) async -> Bool {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        await semaphore.wait() // Acquire the semaphore
        defer { semaphore.signal() } // Release the semaphore when done
        
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line) - Semaphore passed.")
        
        guard let profile = um.user.profile else {
            return false
        }
        
        guard let onboardingState: WellingUserOnboardingState = um.user.onboardingState else {
            return false
        }
        
        if onboardingState.c1MessageGroupsSent >= C1MessagesCount {
            return false
        }
        
        do {
            let messageBody: String = """
Welcome \(profile.name)! Let's work on your **\(Self.goalString(withProfile: profile))**. Here's how:

 • Simply chat to track your daily **food intake, activity, and weight**.
 • Ask any nutritional questions or help with meal planning
 • Aim for **\(profile.targetCalories.formatted()) calories daily**. The more protein the better.
 • Expect to start seeing **results in 1-2 weeks**.

You’re all set now! What did you eat today?
"""
            
            await Self.sendMessage(dm: dm, user: um.user, message: OnboardingMessage(messageBody, 0, false))
            
            var onboardingStateUpdate: OnboardingStateUpdate = um.user.onboardingState == nil || um.user.onboardingState!.isInvalidated
                            ? OnboardingStateUpdate()
                        : OnboardingStateUpdate(from: um.user.onboardingState!)
            onboardingStateUpdate.c1MessageGroupsSent += 1
            
            try await dm.update(onboardingState: onboardingStateUpdate, forUser: um.user)
        } catch {
            WLogger.shared.record(error)
        }
        
        return false
    }
    
    private static func goalString(withProfile: UserProfile) -> String {
        switch withProfile.goal {
        case .loseWeight:
            return "goal to reach \(UnitUtils.getWeightStringWithUnit(withProfile.targetWeight ?? 0, withProfile.preferredUnits))"
        case .buildMuscle:
            return "goal to gain muscle"
        case .keepfit:
            return "goal to keep fit"
        }
    }
    
    private static func goalString(goal: UserGoal) -> String {
        switch goal {
        case .buildMuscle:
            return "muscle gain"
        case .keepfit:
            return "keeping fit"
        case .loseWeight:
            return "weight loss"
        }
    }
    
    private static func howToAchieveGoalString(profile: UserProfile) -> String {
        switch profile.goal {
        case .buildMuscle:
            return "**Tell me what you've eaten** and I will estimate the calories and macros to ensure you hit your targets every day and get enough energy and protein to build muscle."
        case .keepfit:
            return "**Tell me what you've eaten** and I will estimate the calories to help you stay within \(profile.targetCalories) calories a day to achieve your goal of staying fit."
        case .loseWeight:
            return "**Tell me what you've eaten** and I will estimate the calories to help you stay within \(profile.targetCalories.formatted()) calories a day and reach \(UnitUtils.getWeightStringWithUnit(profile.targetWeight ?? 0, profile.preferredUnits))."
        }
    }
    
    @MainActor
    fileprivate static func sendMessage(dm: DM, user: WellingUser, message: OnboardingMessage) async {
        do {
            let m: MobileMessage = MobileMessage()
            m._version = 1
            m.id = UUID().uuidString
            m.text = message.message
            m.state = MessageProcessingState.completed
            m.messageType = MobileMessageType.onboarding
            m.fromSystem = true
            m.replies = List()
            m.ignoreForPrompt = message.ignoreForPrompt
            m.timestamp = Date()
            
            try await dm.sendFromSystem(message: m, forUser: user)
        } catch {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        }
    }
    
    @MainActor
    fileprivate static func sendMessagesOneByOne(dm: DM, user: WellingUser, messages: [OnboardingMessage], groupIndex: Int, messagesAlreadySent: Int) async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        do {
            for i in 0...messages.count - 1 {
                
                if i + 1 <= messagesAlreadySent {
                    continue
                }
                
                let message = messages[i]
                
                let m: MobileMessage = MobileMessage()
                m._version = 1
                m.id = UUID().uuidString
                m.text = message.message
                m.state = MessageProcessingState.completed
                m.messageType = MobileMessageType.onboarding
                m.fromSystem = true
                m.replies = List()
                m.ignoreForPrompt = message.ignoreForPrompt
                m.timestamp = Date()
                
                try await dm.sendFromSystem(message: m, forUser: user)
                Self.setWelcomeMessagesSent(toUid: user.uid, groupIndex: groupIndex, count: i+1)
                
                if message.secondsDelayUntilNextMessage > 0 {
                    try await Task.sleep(for: .seconds(message.secondsDelayUntilNextMessage))
                }
            }
        } catch {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        }
    }
}
