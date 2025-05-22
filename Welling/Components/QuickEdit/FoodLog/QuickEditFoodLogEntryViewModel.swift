//
//  QuickEditFoodLogViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-18.
//

import Foundation
import os
import SwiftUI

@MainActor
class QuickEditFoodLogEntryViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: QuickEditFoodLogEntryViewModel.self)
    )
    
    @Published var foodsLoading: Bool = true
    @Published var foods: [String:Food] = [:]
    @Published var presentDeleteSheet: Bool = false
    @Published var presentEditFoodLogFood: Bool = false
    var isFavorite: Bool = false
    var foodLogFoodToDelete: FoodLogFood?
    var foodLogFoodToEdit: FoodLogFood = .empty
    var foodOfFoodLogFoodToEdit: Food?
    
    var dm: DM?
    var foodLogEntry: MobileFoodLogEntry?
    var deletingFoodLog: Bool = false
    var deletingFoodLogFood: Bool = false
    
    @MainActor
    func onAppear(dm: DM, foodLogEntry: MobileFoodLogEntry, isFavorite: Bool) async {
        do {
            let results = try await dm.getFoodsFor(foodLogEntry: foodLogEntry)
            if let _foods = results.value {
                self.foods = _foods
            }
            
            self.foodsLoading = false
            
            self.dm = dm
            self.foodLogEntry = foodLogEntry
            self.isFavorite = isFavorite
        } catch {
            WLogger.shared.record(error)
        }
    }
   
    func onPresentDeleteFoodLog() {
        self.deletingFoodLogFood = false
        self.deletingFoodLog = true
        self.presentDeleteSheet = true
        self.presentEditFoodLogFood = false
    }
    
    func onPresentEditFoodLogFood(foodLogFoodToEdit: FoodLogFood) {
        self.deletingFoodLogFood = false
        self.deletingFoodLog = false
        self.presentDeleteSheet = false
        
        self.presentEditFoodLogFood = true
        self.foodLogFoodToEdit = foodLogFoodToEdit
        self.foodOfFoodLogFoodToEdit = foodLogFoodToEdit.foodId != nil ? foods[foodLogFoodToEdit.foodId!] : nil
    }
    
    func onHideEditFoodLogFood() {
        self.presentEditFoodLogFood = false
        self.foodLogFoodToEdit = .empty
        self.foodOfFoodLogFoodToEdit = nil
    }
    
    func onPresentDeleteFoodLogFood(foodLogFoodToDelete: FoodLogFood) {
        self.foodLogFoodToDelete = foodLogFoodToDelete
        self.deletingFoodLogFood = true
        self.deletingFoodLog = false
        self.presentDeleteSheet = true
        self.presentEditFoodLogFood = false
    }
    
    func handleDeleteConfirmed() async -> Bool {
        if deletingFoodLog {
            return await deleteFoodLog()
        } else if deletingFoodLogFood {
            return await deleteFoodLogFood()
        }
        
        return false
    }
    
    private func deleteFoodLog() async -> Bool {
        guard let dm = dm, let foodLogEntry = foodLogEntry else {
            return false
        }
        
        do {
            _ = try await dm.delete(foodLogEntry: foodLogEntry)
        } catch {
            Self.logger.error("Error deleting food log entry: \(error)")
            return false
        }
        
        presentDeleteSheet = false
        
        return true
    }
    
    private func deleteFoodLogFood() async -> Bool {
        guard let foodLogEntry = foodLogEntry else {
            return false
        }
        
        var count = 0
        for food in foodLogEntry.foods {
            if food.dateDeleted != nil {
                continue
            }
            count += 1
        }
        
        if count == 1 && !isFavorite {
            self.deletingFoodLogFood = false
            self.deletingFoodLog = true
            return await deleteFoodLog()
        }
        
        guard let dm = dm, let foodLogFoodToDelete = foodLogFoodToDelete else {
            return false
        }
        
        do {
            try await dm.delete(foodLogFood: foodLogFoodToDelete, inFoodLogEntry: foodLogEntry, isFavorite: isFavorite)
        } catch {
            WLogger.shared.record(error)
            return false
        }
        
        presentDeleteSheet = false
        
        return true
    }
    /*
     If we have portion size, increase/decrease that.
     For portion sizes, we can just increase/decrease by 1, keep it simple.
     
     If not, increase/decrease by grams. Do we increase by the original amount or do we increase by 50% every time?
     Or something static? Let's keep it simple, static.
     */
    
    func onIncreaseServing(foodLogFood: FoodLogFood) {
        guard let dm = dm, let foodLogEntry = foodLogEntry else {
            return
        }
        
        var update: FoodLogFoodUpdate = .init(from: foodLogFood)
        update.increasePortion(food: foodLogFood.foodId == nil ? nil : foods[foodLogFood.foodId!])
        
        Task { @MainActor in
            do {
                try await dm.update(foodLogFood: foodLogFood, inFoodLogEntry: foodLogEntry, with: update, isFavorite: isFavorite)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    func onDecreaseServing(foodLogFood: FoodLogFood) {
        guard let dm = dm, let foodLogEntry = foodLogEntry else {
            return
        }
        
        var update: FoodLogFoodUpdate = .init(from: foodLogFood)
        update.decreasePortion(food: foodLogFood.foodId == nil ? nil : foods[foodLogFood.foodId!])
        
        Task { @MainActor in
            do {
                try await dm.update(foodLogFood: foodLogFood, inFoodLogEntry: foodLogEntry, with: update, isFavorite: isFavorite)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    func update(foodLogFood: FoodLogFood?, with: FoodLogFoodUpdate) -> Bool {
        guard let dm = dm, let foodLogEntry = foodLogEntry, let foodLogFood = foodLogFood else {
            return false
        }
        
        if foodLogFood == .empty {
            return false
        }
        
        Task { @MainActor in
            do {
                try await dm.update(foodLogFood: foodLogFood, inFoodLogEntry: foodLogEntry, with: with, isFavorite: isFavorite)
            } catch {
                WLogger.shared.record(error)
            }
        }
        
        return true
    }
    
    func onMealPicked(dm: DM, foodLogEntry: MobileFoodLogEntry, meal: Meal) {
        Task { @MainActor in
            do {
                _ = try await dm.update(foodLogEntry: foodLogEntry, meal: meal)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
}
