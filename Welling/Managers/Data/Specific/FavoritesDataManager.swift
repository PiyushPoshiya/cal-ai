//
//  FavoritesDataManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import os
import RealmSwift

extension DM {
    @MainActor
    func update(foodLogFavorite: MobileUserFavorite, key: String, forUser: WellingUser) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "Updating food log favorite.")
        try await realm.asyncWrite {
            foodLogFavorite.key = key
        }
        
        let newFavorites: [FirebaseMobileUserFavorite] = forUser.favorites.map({FirebaseMobileUserFavorite(favorite: $0)})
            
        Task { @MainActor in
            do {
                try await firestore.update(favorites: newFavorites, forUser: forUser.uid)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    @MainActor
    func delete(foodLogFavorite: MobileUserFavorite, forUser:  WellingUser) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "Deleting food log favorite.")
        
        let now: Date = Date.now
        
        let indexToRemove = forUser.favorites.index(matching: { $0.key == foodLogFavorite.key })
        if let indexToRemove = indexToRemove {
            try await realm.asyncWrite {
                realm.delete(foodLogFavorite)
                forUser.dateUpdated = now
            }
        } else {
            WLogger.shared.log(Self.loggerCategory, "Food log favorite not found in user favorites to delete.")
        }
        
        let newFavorites: [FirebaseMobileUserFavorite] = forUser.favorites.map({FirebaseMobileUserFavorite(favorite: $0)})
            
        Task { @MainActor in
            do {
                try await firestore.update(favorites: newFavorites, forUser: forUser.uid)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    @MainActor
    func listFavoritesWithFoods(favorites: List<MobileUserFavorite>) -> [FavoriteWithFoodLogEntry] {
        WLogger.shared.log(Self.loggerCategory, "List favorites with foods.")
        let messageIds: [String] = favorites.map({$0.messageId})
        
        let messages = realm
            .objects(MobileMessage.self)
            .where {
                $0.id.in(messageIds)
            }
        var favoritesByMessageId: [String: MobileFoodLogEntry] = [:]
        for message in messages {
            if let favoriteFood = message.favoriteFood {
                favoritesByMessageId[message.id] = favoriteFood
            }
        }
        
        var result: [FavoriteWithFoodLogEntry] = []
        for favorite in favorites {
            if let favoriteFood = favoritesByMessageId[favorite.messageId] {
                result.append(FavoriteWithFoodLogEntry(favorite: favorite, foodLogEntry: favoriteFood))
            }
        }
        
        return result
    }
    
    // add favorite to user
    @MainActor
    func add(favorite: MobileUserFavorite, fromMessage: MobileMessage, forUser: WellingUser) async throws {
        WLogger.shared.log(Self.loggerCategory, "Add a favorite.")
        
        guard let foodLog = fromMessage.foodLog else {
            return
        }
        
        let now: Date = Date.now
        if let fromMessage = fromMessage.thaw(), let foodLog = foodLog.thaw() {
            let clonsedFoodLog = clone(existingFoodLog: foodLog, forMessageId: fromMessage.id, withTimestamp: now)
            try await realm.asyncWrite {
                fromMessage.favoriteFood = clonsedFoodLog
                forUser.favorites.append(favorite)
            }
            
            /**
             set favoriteFood
             - create new collection of favorite foods list?
             */
            Task { @MainActor in
                
                do {
                    try await firestore.add(favorite: favorite, foodLog: clonsedFoodLog, fromMessageId: fromMessage.id, forUser: forUser.uid)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
    
    @MainActor
    func log(favorite: MobileUserFavorite) async throws -> FetchResult<Bool> {
        WLogger.shared.log(Self.loggerCategory, "Logging favorite.")
        
        do {
            // First, get message with id locally.
            // Append new message with food log and completed status to firebase
            // This will trigger a listener to update the realm and UI
            
            if let message = getMobileMessageFromLocal(withId: favorite.messageId), let foodLog = message.favoriteFood {
                return try await logFoodFrom(existingFoodLog: foodLog, withFavorite: favorite)
            }
            
            // Try to get it remotely
            let existingMessageResult = try await firestore.getMessage(withId: favorite.messageId)
            if let error = existingMessageResult.error {
                return FetchResult(value: nil, error: error, statusCode: existingMessageResult.statusCode, unauthenticated: existingMessageResult.unauthenticated)
            }
            
            guard let existingMessage = existingMessageResult.value else {
                return FetchResult(value: nil, error: existingMessageResult.error, statusCode: existingMessageResult.statusCode, unauthenticated: existingMessageResult.unauthenticated)
            }
            
            // Save the message locally.
            try await self.saveMessage(message: existingMessage)
            
            guard let existingFoodLog = existingMessage.favoriteFood else {
                return FetchResult(value: nil, error: nil, statusCode: 500, unauthenticated: false)
            }
            
            return try await logFoodFrom(existingFoodLog: existingFoodLog, withFavorite: favorite)
        } catch {
            WLogger.shared.record(error)
            return FetchResult(value: nil, error: ResultError(title: "Unknown Error", message: "Please try again later.", cause: error), statusCode: 500, unauthenticated: false)
        }
    }
    
    private func getMobileMessageFromLocal(withId: String) -> MobileMessage? {
        return realm.object(ofType: MobileMessage.self, forPrimaryKey: withId)
    }
    
    @MainActor
    private func logFoodFrom(existingFoodLog: MobileFoodLogEntry, withFavorite: MobileUserFavorite) async throws -> FetchResult<Bool> {
        WLogger.shared.log(Self.loggerCategory, "Log favorite food.")
        
        let messageId: String = UUID().uuidString
        let now = Date()
        
        let newFoodLog: MobileFoodLogEntry = self.clone(existingFoodLog: existingFoodLog, forMessageId: messageId, withTimestamp: now)
        
        let newMessage = MobileMessage(
            _version: 1,
            id: messageId,
            state: MessageProcessingState.completed,
            classification: MobileMessageClassification.foodEaten,
            messageType: MobileMessageType.foodLogged,
            fromSystem: false,
            text: "Log my favorite \"\(withFavorite.key)\"",
            image: nil,
            replyingToMessageId: nil,
            foodLog: newFoodLog,
            activityLog: nil,
            weightLog: nil,
            favoriteFood: nil,
            logTimestamp: newFoodLog.timestamp,
            replies: List(),
            ignoreForPrompt: false,
            timestamp: now
        )
        
        if let withFavorite = withFavorite.thaw() {
            try await realm.asyncWrite {
                withFavorite.timesLogged = withFavorite.timesLogged + 1
            }
        }
        
        let favorites = realm.objects(MobileUserFavorite.self)
        
        try await firestore.log(newMessage: newMessage, withFoods: Array(newFoodLog.foods), withFavorites:  favorites.map({FirebaseMobileUserFavorite(favorite: $0)}))
        try await saveMessage(message: newMessage)
        
        return FetchResult(value: true, error: nil, statusCode: 200, unauthenticated: false)
    }
    
    private func clone(existingFoodLog: MobileFoodLogEntry, forMessageId: String, withTimestamp: Date) -> MobileFoodLogEntry {
        let foodLogId: String = UUID().uuidString
        
        let foods: List<FoodLogFood> = List()
        for food in existingFoodLog.foods {
            foods.append(FoodLogFood(from: food, messageId: forMessageId, foodLogId: foodLogId, withId: UUID().uuidString))
        }
        
        return MobileFoodLogEntry(
            _version: 1,
            id: foodLogId,
            messageId: forMessageId,
            userDescription: existingFoodLog.userDescription,
            meal: existingFoodLog.meal,
            calories: existingFoodLog.calories,
            fat: existingFoodLog.fat,
            carbs: existingFoodLog.carbs,
            protein: existingFoodLog.protein,
            foods: foods,
            timestamp: withTimestamp
        )
    }
}

extension FirestoreDataManager {
    
    @MainActor
    func add(favorite: MobileUserFavorite, foodLog: MobileFoodLogEntry, fromMessageId: String, forUser: String) async throws {
        WLogger.shared.log(Self.loggerCategory, "Add favorite food log to firebase.")
        
        let batch = db.batch()
        
        let userRef = db.collection("users").document(forUser)
        let messageRef = userRef.collection("messages").document(fromMessageId)
        let foodLogFoodsRef = userRef.collection("food_log_foods")
        
        try batch.updateData([
            "favorites": FieldValue.arrayUnion([encoder.encode(FirebaseMobileUserFavorite(favorite: favorite))])
        ], forDocument: userRef)
        
        batch.updateData([
            "favoriteFood": try encoder.encode(FirebaseMobileFoodLogEntry(from: foodLog))
        ], forDocument: messageRef)
        
        for food in foodLog.foods {
            let firebaseFood: FirebaseFoodLogFood = FirebaseFoodLogFood(from: food)
            try batch.setData(
                from: firebaseFood,
                forDocument: foodLogFoodsRef.document(food.id))
        }
        
        try await batch.commit()
    }
    
    @MainActor
    func log(newMessage: MobileMessage, withFoods: [FoodLogFood], withFavorites: [FirebaseMobileUserFavorite]) async throws {
        WLogger.shared.log(Self.loggerCategory, "Log new message with foods and favorite.")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }
        
        let batch = db.batch()
        let firebaseMessage: FirebaseMobileMessage = .init(from: newMessage)
        
        let userRef = db.collection("users").document(uid)
        
        try batch.setData(
            from: firebaseMessage,
            forDocument: userRef.collection("messages").document(firebaseMessage.id))
        
        batch.updateData([
            "favorites": try withFavorites.map({try encoder.encode($0)})
        ], forDocument: userRef)
        
        for food in withFoods {
            let firebaseFood: FirebaseFoodLogFood = FirebaseFoodLogFood(from: food)
            try batch.setData(
                from: firebaseFood,
                forDocument: userRef.collection("food_log_foods").document(food.id))
        }
        
        try await batch.commit()
    }
    
    @MainActor
    func update(favorites: [FirebaseMobileUserFavorite], forUser: String) async throws {
        WLogger.shared.log(Self.loggerCategory, "Update favorites.")
        
        try await db
            .collection("users")
            .document(forUser)
            .updateData([
                "favorites": try favorites.map({try encoder.encode($0)})
            ])
    }
}


struct FavoriteWithFoodLogEntry {
    static let empty: FavoriteWithFoodLogEntry = FavoriteWithFoodLogEntry(favorite: .empty, foodLogEntry: .redacted)
    
    let favorite: MobileUserFavorite
    let foodLogEntry: MobileFoodLogEntry
}
