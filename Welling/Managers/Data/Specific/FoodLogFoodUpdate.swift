//
//  Models.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-17.
//

import Foundation

struct FoodLogFoodUpdate {
    static let empty: FoodLogFoodUpdate = .init(id: "", deleted: false, amount: 0, calories: 0, fat: 0, carbs: 0, protein: 0, portionSizeName: nil, portionSizeAmount: nil)
    
    var id: String
    var deleted: Bool
    var amount: Double
    var calories: Double
    var fat: Double
    var carbs: Double
    var protein: Double
    var portionSizeName: String?
    var portionSizeAmount: Double?
    
    init(id: String, deleted: Bool, amount: Double, calories: Double, fat: Double, carbs: Double, protein: Double, portionSizeName: String?, portionSizeAmount: Double?) {
        self.id = id
        self.deleted = deleted
        self.amount = amount
        self.calories = calories
        self.fat = fat
        self.carbs = carbs
        self.protein = protein
        self.portionSizeName = portionSizeName
        self.portionSizeAmount = portionSizeAmount
    }
    
    init(from: FoodLogFood) {
        self.id = from.id
        self.deleted = from.dateDeleted != nil
        self.amount = from.amount
        self.calories = from.calories
        self.fat = from.fat
        self.carbs = from.carbs
        self.protein = from.protein
        self.portionSizeName = from.portionSizeName
        self.portionSizeAmount = from.portionSizeAmount
    }
    
    mutating func increasePortion(food: Food?) {
        let newAmount: Double
        var newPortionSizeAmount: Double? = nil
        if let portionSizeAmount = portionSizeAmount, let servingSize = getServingSizeFrom(food: food), servingSize.amount > 0 {
            let tempPortionSize: Double
            if portionSizeAmount < 1 {
                tempPortionSize = portionSizeAmount + 0.25
            } else {
                tempPortionSize = portionSizeAmount + 1
            }
            newPortionSizeAmount = tempPortionSize
            newAmount = (tempPortionSize * (servingSize.size / servingSize.amount))
        } else {
            if amount < 50 {
                newAmount = amount + 10
            } else {
                newAmount = amount + 50
            }
        }
        
        recomputeValuesFrom(newAmount: newAmount, newPortionSizeAmount: newPortionSizeAmount)
    }
    
    mutating func decreasePortion(food: Food?) {
        let newAmount: Double
        var newPortionSizeAmount: Double? = nil
        if let portionSizeAmount = portionSizeAmount, let servingSize = getServingSizeFrom(food: food) {
            let tempPortionSize: Double
            if portionSizeAmount <= 1 {
                tempPortionSize = portionSizeAmount - 0.25
            } else {
                tempPortionSize = portionSizeAmount - 1
            }
            newPortionSizeAmount = tempPortionSize
            newAmount = (tempPortionSize * (servingSize.size / servingSize.amount))
        } else {
            if amount <= 50 {
                newAmount = amount - 10
            } else {
                newAmount = amount - 50
            }
        }
        
        recomputeValuesFrom(newAmount: newAmount, newPortionSizeAmount: newPortionSizeAmount)
    }
    
    mutating func update(portionSizeAmount: Double, food: Food?) {
        if let servingSize = getServingSizeFrom(food: food) {
            let newAmount: Double = (portionSizeAmount * (servingSize.size / servingSize.amount))
            recomputeValuesFrom(newAmount: (portionSizeAmount * (servingSize.size / servingSize.amount)), newPortionSizeAmount: portionSizeAmount)
        }
    }
    
    mutating func update(amount: Double) {
        recomputeValuesFrom(newAmount: amount, newPortionSizeAmount: nil)
    }
    
    private mutating func recomputeValuesFrom(newAmount: Double, newPortionSizeAmount: Double?) {
        // Easy protection against overflows
        if newAmount <= 0 {
            return
        }
        
        if let newPortionSizeAmount = newPortionSizeAmount, newPortionSizeAmount <= 0 {
            return
        }
        
       
        let calsPerG: Double = calories / amount
        let fatPerG: Double = fat / amount
        let carbsPerG: Double = carbs / amount
        let proteinPerG: Double = protein / amount
        
        amount = newAmount
        portionSizeAmount = newPortionSizeAmount
        
        calories = newAmount * calsPerG
        fat = newAmount * fatPerG
        carbs = newAmount * carbsPerG
        protein = newAmount * proteinPerG
    }
    
    private func getServingSizeFrom(food: Food?) -> ServingSize? {
        guard let portionSizeName = self.portionSizeName, let food = food else {
            return nil
        }
        
        let lowered = portionSizeName.lowercased()
        
        for servingSize in food.servingSizes {
            if servingSize.name.lowercased() == lowered {
                return servingSize
            }
        }
        
        return nil
    }
}

struct FoodLogEntryUpdate {
    let id: String
    let messageId: String
    let calories: Double
    let fat: Double
    let carbs: Double
    let protein: Double
    
    init(id: String, messageId: String, calories: Double, fat: Double, carbs: Double, protein: Double) {
        self.id = id
        self.messageId = messageId
        self.calories = calories
        self.fat = fat
        self.carbs = carbs
        self.protein = protein
    }
    
    init(from: MobileFoodLogEntry) {
        self.id = from.id
        self.messageId = from.messageId
        self.calories = from.calories
        self.fat = from.fat
        self.carbs = from.carbs
        self.protein = from.protein
    }
}
