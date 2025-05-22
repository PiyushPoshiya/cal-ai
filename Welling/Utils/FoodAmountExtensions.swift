//
//  FoodAmountUtils.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-10.
//

import Foundation

extension MobileFoodLogEntry {
    func summaryDisplayString() -> String {
        var display = "I estimate..."
        
        for foodLogFood in foods {
            display.append("\n")
            display.append("• ")
            display.append(foodLogFood.summaryDisplayString())
        }
        
        return display
    }
    
    func shortSummaryDisplayString() -> String {
        return Array(foods).shortSummaryDisplayString()
    }
}

extension [MobileFoodLogEntry] {
    
    func shortSummaryDisplayString() -> String {
        var foods: [FoodLogFood] = []
        for foodLogEntry in self {
            for food in foodLogEntry.foods {
                foods.append(food)
            }
        }
        
        return foods.shortSummaryDisplayString()
    }
}

extension [FoodLogFood] {
    func shortSummaryDisplayString() -> String {
        if self.count == 0 {
            return ""
        }
        
        var display = self[0].getFoodNameDisplayString()
        
        
        if self.count > 2 {
            for i in 1...self.count - 2 {
                display.append(", ")
                display.append(self[i].getFoodNameDisplayString())
            }
        }
        
        if self.count > 1 {
            if self.count == 2 {
                display.append(" and ")
            } else {
                display.append(", and ")
            }
            display.append(self[self.count - 1].getFoodNameDisplayString())
        }
        
        return display
    }
}

extension FoodLogFood {
    func getServingSizeString() -> String {
        guard let portionSizeName = portionSizeName else {
            return "\(lround(amount))\(unit)"
        }

        guard let portionSizeAmount = portionSizeAmount else {
            return "\(lround(amount))\(unit)"
        }

        let amountString = portionSizeAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", portionSizeAmount)
            : String(portionSizeAmount)

        return "\(amountString) \(portionSizeName) (\(lround(amount)) \(unit))"
    }
    
    func summaryDisplayString() -> String {
        return "\(getFoodNameDisplayString()), \(getFoodAmountInBasicUnitsDisplayString()), \(lround(calories)) kcal"
    }
    
    func getFoodNameDisplayString() -> String {
        let normalizedBrand: String = brand.lowercased()
        let normalizedName: String = name.lowercased()
        let brandGeneric: Bool = normalizedBrand == "generic"
        
        let brandUnknown: Bool = normalizedBrand == "unknown"
        let nameUnknown: Bool = normalizedName == "unknown"
        
        if (brandUnknown && nameUnknown) {
            return "unknown food"
        } else if (brandUnknown) {
            return name
        } else if (nameUnknown) {
            return "unknown \(brand) food"
        } else {
            return brandGeneric ? name : "\(name) (\(brand))"
        }
    }
    
    func getFoodAmountInBasicUnitsDisplayString() -> String {
        if unit == "g" || unit == "ml" {
            return "\(lround(amount))\(unit)"
        }
        
        return "\(lround(amount)) \(unit)"
    }
}
