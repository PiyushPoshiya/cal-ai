//
//  FoodCalculator.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-19.
//

import Foundation

extension MobileFoodLogEntry {
    func recomputeTotals() {
        var totalCals: Double = 0.0
        var totalFat: Double  = 0.0
        var totalCarbs: Double  = 0.0
        var totalProtein: Double  = 0.00
        
        for food in foods {
            if food.dateDeleted != nil {
                continue
            }
            
            totalCals += food.calories
            totalFat += food.fat
            totalCarbs += food.carbs
            totalProtein += food.protein
        }
        
        self.calories = totalCals
        self.fat = totalFat
        self.carbs = totalCarbs
        self.protein = totalProtein
    }
}

extension FoodLogFood {
    func apply(update: FoodLogFoodUpdate, date: Date) {
        if update.deleted {
            self.dateDeleted = date
            return
        }
        
        self.amount = update.amount
        self.calories = update.calories
        self.fat = update.fat
        self.carbs = update.carbs
        self.protein = update.protein
        self.portionSizeName = update.portionSizeName
        self.portionSizeAmount = update.portionSizeAmount
    }
}
