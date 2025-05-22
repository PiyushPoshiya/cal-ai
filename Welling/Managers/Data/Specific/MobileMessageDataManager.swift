//
//  MobileMessageDataManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import RealmSwift

extension DM {
    
    func getMostRecentMessageY(messageType: MobileMessageType) -> MobileMessage? {
        return realm.objects(MobileMessage.self)
            .sorted(by: \.timestamp, ascending: false)
            .first {
                $0.messageType == messageType
            }
    }
    
    func listMessagesWithFoodOrActivityLogs(from: Date, to: Date) -> Results<MobileMessage> {
        return realm
            .objects(MobileMessage.self)
            .where {
                ($0.foodLog != nil && $0.foodLog.timestamp >= from && $0.foodLog.timestamp < to)
                || ($0.activityLog != nil && $0.activityLog.timestamp >= from && $0.activityLog.timestamp < to)
            }
            .sorted(by: \.timestamp, ascending: true)
            .freeze()
    }
    
    func listWeightLogs(from: Date, to: Date) -> Results<MobileWeightLog> {
        return realm.objects(MobileWeightLog.self)
            .where {
                $0.dateDeleted == nil && $0.timestamp.contains(from ..< to)
            }
            .sorted(by: \.timestamp, ascending: true)
        
            .freeze()
    }
    
    func listActivityLogs(from: Date, to: Date) -> Results<MobileMessage> {
            return realm
                .objects(MobileMessage.self)
                .where {
                    $0.activityLog != nil && $0.activityLog.dateDeleted == nil && $0.activityLog.timestamp >= from  && $0.activityLog.timestamp < to
                }
                .sorted(by: \.timestamp, ascending: true)
                .freeze()
    }
    
    func getLastMessageDate() -> Date {
        let first = realm
            .objects(MobileMessage.self)
            .sorted(by: \.timestamp, ascending: false)
            .first
        
        if let first = first {
            return first.timestamp
        }
        
        return Date.now
    }
   
    @MainActor
    func sendFromSystem(message: MobileMessage, forUser: WellingUser) async throws -> Void {
        try await realm.asyncWrite {
            realm.add(message)
        }
        
        Task { @MainActor in
            do {
                try await firestore.sendOnboarding(message: FirebaseMobileMessage(from: message))
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    @MainActor
    func update(onboardingState: OnboardingStateUpdate, forUser: WellingUser) async throws -> Void {
        let now = Date.now
        
        try await realm.asyncWrite {
            forUser.onboardingState = WellingUserOnboardingState(from: onboardingState)
            forUser.dateUpdated = now
        }
        
        Task { @MainActor in
            do {
                try await firestore.update(onboardingState: onboardingState, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
}

extension FirestoreDataManager {
    func sendOnboarding(message: FirebaseMobileMessage) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .addDocument(data: encoder.encode(message))
    }
    
    func update(onboardingState: OnboardingStateUpdate, dateUpdated: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .updateData([
                "onboardingState.c1MessageGroupsSent": onboardingState.c1MessageGroupsSent,
                "onboardingState.firstReminder": onboardingState.firstReminder,
                "onboardingState.photoLogging": onboardingState.photoLogging,
                "onboardingState.loggedFirstFood": onboardingState.loggedFirstFood,
                "onboardingState.loggedSecondFood": onboardingState.loggedSecondFood,
                "onboardingState.loggedFirstActivity": onboardingState.loggedFirstActivity,
                "onboardingState.loggedSecondActivity": onboardingState.loggedSecondActivity,
                
                "dateUpdated": dateUpdated,
            ])
    }
}

struct OnboardingStateUpdate: PWellingUserOnboardingState {
    var version: Int
    var c1MessageGroupsSent: Int
    var firstReminder: Bool
    var photoLogging: Bool
    var loggedFirstFood: Bool?
    var loggedSecondFood: Bool
    var loggedFirstActivity: Bool?
    var loggedSecondActivity: Bool
    
    init() {
        version = 2
        c1MessageGroupsSent = 0
        firstReminder = false
        photoLogging = false
        loggedFirstFood = false
        loggedSecondFood = false
        loggedFirstActivity = false
        loggedSecondActivity = false
    }
    
    @MainActor
    init(from: WellingUserOnboardingState) {
        self.version = from.version
        self.c1MessageGroupsSent = from.c1MessageGroupsSent
        self.firstReminder = from.firstReminder
        self.photoLogging = from.photoLogging
        self.loggedFirstFood = from.loggedFirstFood
        self.loggedSecondFood = from.loggedSecondFood
        self.loggedFirstActivity = from.loggedFirstActivity
        self.loggedSecondActivity = from.loggedSecondActivity
    }
}
