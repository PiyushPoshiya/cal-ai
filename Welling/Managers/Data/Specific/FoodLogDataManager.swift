//
//  FoodLogDataManager.swift
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
    func update(foodLogEntry: MobileFoodLogEntry, meal: Meal?) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        // Kick off an update to FB, async
        let id = foodLogEntry.messageId
        
        if let foodLogEntry = foodLogEntry.thaw() {
            try await realm.asyncWrite {
                foodLogEntry.meal = meal
                foodLogEntry.dateUpdated = now
            }
            
            Task {
                do {
                    try await firestore.update(foodLogEntryWithId: id, meal: meal, dateUpdated: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
   
    @MainActor
    func delete(foodLogEntry: MobileFoodLogEntry) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        let id = foodLogEntry.messageId
        
        if let foodLogEntry = foodLogEntry.thaw() {
            try await realm.asyncWrite {
                foodLogEntry.dateDeleted = now
            }
            
            Task {
                do {
                    try await firestore.delete(foodLogEntryWithId: id, dateDeleted: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
    
    @MainActor
    func delete(foodLogFood: FoodLogFood, inFoodLogEntry: MobileFoodLogEntry, isFavorite: Bool) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        
        if let foodLogFood = foodLogFood.thaw(), let foodLogEntry = inFoodLogEntry.thaw() {
            try await realm.asyncWrite {
                foodLogFood.dateDeleted = now
                foodLogEntry.recomputeTotals()
            }
            
            Task {
                do {
                    try await firestore.update(foodLogFood: .init(from: foodLogFood), inFoodLogEntry: .init(from: foodLogEntry), isFavorite: isFavorite, dateUpdated: now)
                } catch {
                    WLogger.shared.record(error)
                    DM.logger.error("Error updating firestore: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func update(foodLogFood: FoodLogFood, inFoodLogEntry: MobileFoodLogEntry, with: FoodLogFoodUpdate, isFavorite: Bool) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        let now = Date.now
        
        if let foodLogFood = foodLogFood.thaw(), let foodLogEntry = inFoodLogEntry.thaw() {
            try await realm.asyncWrite {
                foodLogFood.apply(update: with, date: now)
                foodLogEntry.recomputeTotals()
            }
            
            Task {
                do {
                    try await firestore.update(foodLogFood: .init(from: foodLogFood), inFoodLogEntry: .init(from: foodLogEntry), isFavorite: isFavorite, dateUpdated: now)
                } catch {
                    WLogger.shared.record(error)
                }
            }
        }
    }
    
    @MainActor
    func getFoodsFor(foodLogEntry: MobileFoodLogEntry) async throws -> FetchResult<[String:Food]> {
        // First, check in the cache for each food.
        // for any foods not found, fetch them
        // cache the fetched foods
        // then merge the results
        
        var ids: Set<String> = []
        for food in foodLogEntry.foods {
            guard let id = food.foodId else {
                continue
            }
            
            ids.insert(id)
        }
        
        var foods: Dictionary<String, Food> = Dictionary()
        
        let foundFoods = realm.objects(Food.self).where( {
            $0.id.in(ids)
        })
        
        for foundFood in foundFoods {
            foods[foundFood.id] = foundFood
            ids.remove(foundFood.id)
        }
        
        if ids.isEmpty {
            return FetchResult(value: foods, error: nil, statusCode: 200, unauthenticated: false)
        }
        
        let fetchResult = await fetchManager.getFoods(ids: Array(ids))
        if let error = fetchResult.error {
            return FetchResult(value: nil, error: error, statusCode: fetchResult.statusCode, unauthenticated: fetchResult.unauthenticated)
        }
        
        guard let fetchedFoods = fetchResult.value else {
            return FetchResult(value: nil, error: nil, statusCode: fetchResult.statusCode, unauthenticated: fetchResult.unauthenticated)
        }
        
        for fetchedFood in fetchedFoods {
            foods[fetchedFood.id] = fetchedFood
        }
        
        try await realm.asyncWrite {
            for fetchedFood in fetchedFoods {
                realm.add(fetchedFood)
            }
        }
        
        return FetchResult(value: foods, error: nil, statusCode: 200, unauthenticated: false)
    }
}

extension FirestoreDataManager {
    func update(foodLogEntryWithId: String, meal: Meal?, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(foodLogEntryWithId)
            .updateData([
                "foodLog.meal": meal?.rawValue as Any,
                "foodLog.dateUpdated": dateUpdated
            ])
    }
    
    func delete(foodLogEntryWithId: String, dateDeleted: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        try await db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(foodLogEntryWithId)
            .updateData([
                "foodLog.dateDeleted": dateDeleted
            ])
    }
    
    func update(foodLogFood: FoodLogFoodUpdate, inFoodLogEntry: FoodLogEntryUpdate, isFavorite: Bool, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged")
        }
        
        let foodLogPath: String = isFavorite ? "favoriteFood" : "foodLog"
        
        let batch = db.batch()
        
        let foodLogEntry = db
            .collection("users")
            .document(uid)
            .collection("messages")
            .document(inFoodLogEntry.messageId)
        batch.updateData([
            "\(foodLogPath).calories": inFoodLogEntry.calories,
            "\(foodLogPath).fat": inFoodLogEntry.fat,
            "\(foodLogPath).carbs": inFoodLogEntry.carbs,
            "\(foodLogPath).protein": inFoodLogEntry.protein,
            "\(foodLogPath).dateUpdated": dateUpdated
        ], forDocument: foodLogEntry)
        
        let foodLogFoodDoc = db
            .collection("users")
            .document(uid)
            .collection("food_log_foods")
            .document(foodLogFood.id)
       
        if foodLogFood.deleted {
            batch.updateData([
                "dateDeleted": dateUpdated], forDocument: foodLogFoodDoc)
        } else {
            batch.updateData([
                "amount": foodLogFood.amount,
                "calories": foodLogFood.calories,
                "fat": foodLogFood.fat,
                "carbs": foodLogFood.carbs,
                "protein":foodLogFood.protein,
                "portionSizeName": foodLogFood.portionSizeName as Any,
                "portionSizeAmount": foodLogFood.portionSizeAmount as Any,
                "dateUpdated": dateUpdated
            ], forDocument: foodLogFoodDoc)
        }
        
        try await batch.commit()
    }
}
