//
//  ProfileUtils.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import Foundation

class ProfileUtils {
    static let DefaultActivityLevel: ActivityLevel = .SittingMostOfTheTime
    static let DefaultDietPreference: String = "Balanced Diet"

    static func getMacroProfile(macroProfile: PMacroProfile) -> ComputedMacroProfile {
        var computedProfile: ComputedMacroProfile = ComputedMacroProfile(bmr: 0, tdee: 0, targetCalories: 0, calorieOverride: macroProfile.calorieOverride, targetFat: 0, fatPercent: 0, targetFatPercentOverride: macroProfile.targetFatPercentOverride, targetCarbs: 0, carbsPercent: 0, targetCarbsPercentOverride: macroProfile.targetCarbsPercentOverride, targetProtein: 0, proteinPercent: 0, targetProteinPercentOverride: macroProfile.targetProteinPercentOverride)
        
        let isBuildMuscle = macroProfile.goal == .buildMuscle
        computedProfile.tdee = getTDEE(profile: macroProfile)

        computedProfile.targetCalories = computedProfile.tdee + Self.getCaloriesDelta(profile: macroProfile)
        switch macroProfile.gender {
        case .male:
            computedProfile.targetCalories = max(1500, computedProfile.targetCalories)
        case .female:
            computedProfile.targetCalories = max(1200, computedProfile.targetCalories)
        }

        let caloriesForComputation = Utils.valueIfPresent(value: macroProfile.calorieOverride, defaultValue: computedProfile.targetCalories)

        Self.updateTargetForMuscleBuilders(profile: macroProfile, computedProfile: &computedProfile)

        if isBuildMuscle {
            let midRange: Double = Double((computedProfile.proteinRange?.max ?? 0) + (computedProfile.proteinRange?.min ?? 0)) / 2.0;
            let calories = midRange * MacroConstants.CaloriesPerProtein
        computedProfile.proteinPercent = lround(calories / Double(caloriesForComputation) * 100.0)
        }

        if computedProfile.proteinPercent >= 100 {
            computedProfile.proteinPercent = 99
        }

        if (macroProfile.dietaryPreference == "Low carb diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(50 / 70, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(20 / 70, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "High protein diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 40;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(35 / 60, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(25 / 60, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "Vegetarian diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(25 / 70, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(45 / 70, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "Vegan diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(25 / 70, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(45 / 70, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "Keto diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 20;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(70 / 80, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(10 / 80, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "Paleo diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(50 / 70, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(20 / 70, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "Mediterranean diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(25 / 70, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(45 / 70, computedProfile.proteinPercent);
        } else if (macroProfile.dietaryPreference == "Pescatarian diet") {
          computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
          computedProfile.fatPercent = Self.getRemainingMacroPercent(25 / 70, computedProfile.proteinPercent);
          computedProfile.carbsPercent = Self.getRemainingMacroPercent(45 / 70, computedProfile.proteinPercent);
        } else {
            computedProfile.proteinPercent = computedProfile.proteinPercent != 0 ? computedProfile.proteinPercent : 30;
            computedProfile.fatPercent = Self.getRemainingMacroPercent(25 / 70, computedProfile.proteinPercent);
            computedProfile.carbsPercent = Self.getRemainingMacroPercent(45 / 70, computedProfile.proteinPercent);
        }
        
        if computedProfile.fatPercent + computedProfile.carbsPercent + computedProfile.proteinPercent != 100 {
            print("Computed macro percentages do not add up to 100")
        }
        
        let caloriesFromFat: Double = Double(Utils.valueIfPresent(value: computedProfile.targetFatPercentOverride, defaultValue: computedProfile.fatPercent)) / 100.0 * Double(caloriesForComputation)
        computedProfile.targetFat = lround(caloriesFromFat / MacroConstants.CaloriesPerFat)
        
        let caloriesFromCarbs: Double = Double(Utils.valueIfPresent(value: computedProfile.targetCarbsPercentOverride, defaultValue: computedProfile.carbsPercent)) / 100.0 * Double(caloriesForComputation)
        computedProfile.targetCarbs = lround(caloriesFromCarbs  / MacroConstants.CaloriesPerCarb)
       
        let caloriesFromProtein: Double = Double(Utils.valueIfPresent(value: computedProfile.targetProteinPercentOverride, defaultValue: computedProfile.proteinPercent)) / 100.0 * Double(caloriesForComputation)
        computedProfile.targetProtein = lround(caloriesFromProtein / MacroConstants.CaloriesPerProtein)
        
        return computedProfile
    }
    
    static func macrosFrom(percent: Int, totalCalories: Int, caloriesPerMacro: Double) -> Int {
        let caloriesFromMacro: Double = Double(percent) / 100.0 * Double(totalCalories)
        return lround(caloriesFromMacro / caloriesPerMacro)
    }

    static private func getRemainingMacroPercent(_ ratio: Double, _ percentUsed: Int) -> Int {
        return lround(ratio * (100.0 - Double(percentUsed)))
    }

    static private func updateTargetForMuscleBuilders(profile: PMacroProfile, computedProfile: inout ComputedMacroProfile) {
        if profile.goal != .buildMuscle {
            return
        }

        computedProfile.proteinRange = MinMax(min: 0, max: 0)

        let weight: Double  = profile.currentWeight
        let exerciseLevel: ExerciseLevel? = profile.exerciseLevel

        switch exerciseLevel {
        case .LittleToNoExercise, .LightExerciseOrSports1To3DaysPerWeek, .ModerateExerciseOrSports3To5DaysPerWeek, nil:
            computedProfile.proteinRange!.min = lround(weight * 0.8)
            computedProfile.proteinRange!.max = lround(weight * 1.2)
        case .HardExerciseOrSports6To7DaysPerWeek, .VeryHardExerciseOrTrainingTwicePerDay:
            computedProfile.proteinRange!.min = lround(weight * 1.2)
            computedProfile.proteinRange!.max = lround(weight * 1.8)
        }
    }

    static func getTargetCalories(profile: PMacroProfile?) -> Int {
        guard let profile: PMacroProfile = profile else {
            return getDefaultTargetCalories(gender: nil)
        }

        return profile.calorieOverride ?? profile.targetCalories
    }

    static func getBMRMultiplier(activityLevel: ActivityLevel?) -> Double {
        let _activityLevel: ActivityLevel = activityLevel ?? DefaultActivityLevel
        switch _activityLevel {
        case .SittingMostOfTheTime:
            return 1.2
        case .OnMyFeetAllDay:
            return 1.4
        case .HardPhysicalJob:
            return 1.6
        }
    }

    static func getDisplayFor(activityLevel: ActivityLevel?) -> String {
        let _activityLevel: ActivityLevel = activityLevel ?? DefaultActivityLevel
        switch _activityLevel {
        case .SittingMostOfTheTime:
            return "Sedentary"
        case .OnMyFeetAllDay:
            return "Active"
        case .HardPhysicalJob:
            return "Hard"
        }
    }

    static func getTDEE(profile: PMacroProfile?) -> Int {
        let bmr: Int = getBMR(profile: profile)

        if bmr == 0 {
            return getDefaultTargetCalories(gender: nil)
        }

        return lround(getBMRMultiplier(activityLevel: profile?.activityLevel) * Double(bmr))
    }

    static func getBMR(profile: PMacroProfile?) -> Int {
        guard let profile: PMacroProfile = profile else {
            return 0
        }

        let w: Double = profile.currentWeight * 10
        let h: Double = 6.25 * Double(profile.height)
        let a = Double(5 * profile.age)
        if profile.gender == .male {
            return lround(w + h - a + 5)
        }

        if profile.gender == .female {
            return lround(w + h - a - 161)
        }

        return 0
    }

    static func getDefaultTargetCalories(gender: Gender?) -> Int {
        guard let gender = gender else {
            return 2000
        }

        if gender == .male {
            return 2200
        }

        if gender == .female {
            return 1800
        }

        return 2000
    }

    static func getCaloriesDelta(profile: PMacroProfile) -> Int {
        switch profile.goal {
        case .loseWeight:
            return -500
        case .buildMuscle:
            return 250
        case .keepfit:
            return 0
        }
    }
    
    static func computeMacroPercent(grams: Int, caloriesPerGram: Double, totalCalories: Int) -> Int {
        if grams == 0 || totalCalories == 0 {
            return  0
        }
        
        return lround(Double(grams) * caloriesPerGram / Double(totalCalories) * 100.0)
    }
}

struct ComputedMacroProfile {
    static let empty: ComputedMacroProfile = ComputedMacroProfile(bmr: 0, tdee: 0, targetCalories: 0, targetFat: 0, fatPercent: 0, targetCarbs: 0, carbsPercent: 0, targetProtein: 0, proteinPercent: 0)
    
    var bmr: Int
    var tdee: Int
    
    var targetCalories: Int
    var calorieOverride: Int?
    
    var targetFat: Int
    var fatPercent: Int
    var targetFatPercentOverride: Int?
    
    var targetCarbs: Int
    var carbsPercent: Int
    var targetCarbsPercentOverride: Int?
    
    var targetProtein: Int
    var proteinPercent: Int
    var targetProteinPercentOverride: Int?
    
    var proteinRange: MinMax?
}

struct MinMax {
    var min: Int
    var max: Int
}

struct MacroConstants {
    static let CaloriesPerFat: Double = 9
    static let CaloriesPerCarb: Double = 4
    static let CaloriesPerProtein: Double = 4
    static let CaloriesPerKg: Double = 7700
}
