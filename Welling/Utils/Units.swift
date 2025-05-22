//
//  Units.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-03.
//

import Foundation

class UnitUtils {
    static func kgToLb(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    static func lbToKg(_ lb: Double) -> Double {
        return (lb / 2.20462) * 10 / 10
    }
    
    static func cmToImperial(_ cm: Int) -> ImperialHeight {
        let inches: Int = lround(Double(cm) / 2.54)
        return ImperialHeight(inches: inches % 12, feet: lround(Double(inches / 12)))
    }
    
    static func imperialToCm(_ feet: Int, _ inches: Int) -> Int {
        return lround(Double(feet * 12 + inches) * 2.54)
    }
    
    static func getWeightStringWithUnit(_ weightInKg: Double, _ preferredUnits: MeasurementUnit?) -> String {
        return "\(getWeightString(weightInKg, preferredUnits)) \(weightUnitString(preferredUnits))"
    }
    
    static func getWeightString(_ weightInKg: Double, _ preferredUnits: MeasurementUnit?) -> String {
        let str: String
        
        switch preferredUnits {
        case .metric:
            str = String(format: "%.1f", weightInKg)
        case .imperial, nil:
            str = String(lround(kgToLb(weightInKg)))
        }
        
        if str.hasSuffix(".0") {
            return str.replacingOccurrences(of: ".0", with: "")
        }
        
        return str
    }
    
    static func weightUnitString(_ preferredUnits: MeasurementUnit?) -> String {
        guard let preferredUnits = preferredUnits else {
            return "kg"
        }
        
        switch preferredUnits {
        case .metric:
            return "kg"
        case .imperial:
            return "lb"
        }
    }

    static func weightValue(_ weightInKg: Double, _ preferredUnits: MeasurementUnit?) -> Double {
        guard let preferredUnits = preferredUnits else {
            return round(weightInKg * 10) / 10
        }
        
        switch preferredUnits {
        case .metric:
            return round(weightInKg * 10) / 10
        case .imperial:
            return (weightInKg * 2.20462).rounded()
        }
    }
}

struct ImperialHeight {
    let inches: Int
    let feet: Int
}
