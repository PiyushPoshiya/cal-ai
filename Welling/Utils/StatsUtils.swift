//
//  StatsUtils.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-29.
//

import Foundation
import RealmSwift
import FirebaseCrashlytics
import os

@MainActor
class StatsUtils {
    static let loggerCategory =  String(describing: StatsUtils.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)
    
    static let AddCaloriesBurnedDefault: Bool = true
    
    static func getActivityLogStatsPerDay(dm: DM, from: Date, to: Date) throws -> ActivityLogStats {
        guard let numDays: Int = Calendar.current.dateComponents([.day], from: from, to: to).day else {
            throw StatsError.invalidDates
        }
        
        var stats: ActivityLogStats = .init(days: numDays, from: from)
        
        let messages: [MobileMessage] = Array(dm.listActivityLogs(from: from, to: to))
        for message in messages {
            guard let activityLog = message.activityLog else {
                continue
            }
            
            let day: Int = Int(floor(from.distance(to: activityLog.timestamp) / 60 / 60 / 24))
            if day < 0 || day >= stats.activityStats.count {
                WLogger.shared.error(Self.loggerCategory, "activity log stats index out of range: length: \(stats.activityStats.count), index: \(day)")
                continue
            }
            
            stats.activityStats[day].activities.append(message)
            stats.activityStats[day].hasData = true
            stats.activityStats[day].totalCaloriesBurned += activityLog.caloriesExpended
        }
        
        var totalExpended: Double = 0
        var daysWithData: Int = 0
        
        for stat in stats.activityStats {
            if !stat.hasData {
                continue
            }
            daysWithData += 1
            totalExpended += stat.totalCaloriesBurned
        }
        
        stats.averageCaloriesBurnedPerDay = daysWithData == 0 ? 0 : lround(totalExpended / Double(daysWithData))
        
        return stats
    }
    
    static func getWeightStatsPerDayFrom(weightLogsAscendingTimestamp: [MobileWeightLog], preferredUnits: MeasurementUnit?) -> WeightLogStats {
        if weightLogsAscendingTimestamp.isEmpty {
            return WeightLogStats()
        }
        
        let firstDay: Date = Calendar.current.startOfDay(for: weightLogsAscendingTimestamp[0].timestamp)
        let lastDay: Date = Calendar.current.startOfDay(for: weightLogsAscendingTimestamp[weightLogsAscendingTimestamp.count - 1].timestamp)
        
        var weightStats: [WeightStat?] = [WeightStat?](repeating: nil, count: Calendar.current.dateComponents([.day], from: firstDay, to: lastDay).day! + 1)

        for weightLog in weightLogsAscendingTimestamp {
            if weightLog.isDeleted {
                continue
            }

            let day: Int = Int(floor(firstDay.distance(to: weightLog.timestamp) / 60 / 60 / 24))
            
            if day < 0 || day >= weightStats.count {
                WLogger.shared.error(Self.loggerCategory, "weight stats index out of range: length: \(weightStats.count), index: \(day)")
                continue
            }
            
            let stat: WeightStat = WeightStat(day: day, weight: UnitUtils.weightValue(weightLog.weightInKg, preferredUnits), timestamp: weightLog.timestamp)

            weightStats[day] = stat
        }
        
        var weightLogStats = WeightLogStats()
        var minWeight: Double? = nil
        var maxWeight: Double? = nil
        for stat in weightStats {
            guard let stat = stat else {
                continue
            }

            if let _maxWeight = maxWeight {
                if stat.weight > _maxWeight {
                    maxWeight = stat.weight
                }
            } else {
                maxWeight = stat.weight
            }

            if let _minWeight = minWeight {
                if stat.weight < _minWeight {
                    minWeight = stat.weight
                }
            } else {
                minWeight = stat.weight
            }

            weightLogStats.weightStats.append(stat)
        }
        
        weightLogStats.minWeight = minWeight ?? 0
        weightLogStats.maxWeight = maxWeight ?? 30
        return weightLogStats
    }
    
    @MainActor
    static func getTodaysStats(dm: DM, profile: UserProfile) -> LoggingStats {
        let today: Date = Calendar.current.startOfDay(for: Date.now)
        let endOfToday: Date = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date.distantFuture
        
        return StatsUtils.getStats(from: today, to: endOfToday, dm: dm, profile: profile)
    }
    
    @MainActor
    static func getStats(from: Date, to: Date, dm: DM, profile: UserProfile) -> LoggingStats {
        var stats: LoggingStats = LoggingStats(day: from)
        
        let targetCalories: Int = ProfileUtils.getTargetCalories(profile: profile)
        
        let messagesResult: Results<MobileMessage> = dm.listMessagesWithFoodOrActivityLogs(from: from, to: to)
        
        for message in messagesResult {
            update(stats: &stats, message: message)
            stats.messages[message.id] = message
        }
        
        updateTargets(forLoggingStats: &stats, targetCalories: targetCalories, profile: profile)
        
        return stats
    }
    
    @MainActor
    static func getWeeklyStats(from: Date, to: Date, dm: DM, profile: UserProfile) throws -> WeeklyCaloriesStats {
        guard let numDays: Int = Calendar.current.dateComponents([.day], from: from, to: to).day else {
            throw StatsError.invalidDates
        }
        
        var weeklyStats: WeeklyCaloriesStats = WeeklyCaloriesStats(days: numDays, from: from)
        let targetCalories: Int = ProfileUtils.getTargetCalories(profile: profile)
        
        let messages: [MobileMessage] = Array(dm.listMessagesWithFoodOrActivityLogs(from: from, to: to))
        
        for message in messages {
            guard let timestampToUse = message.foodLog?.timestamp ?? message.activityLog?.timestamp else {
                continue
            }
            
            let idx: Int = Int(floor(from.distance(to: timestampToUse) / (60 * 60 * 24)))
            
            if idx < 0 || idx >= weeklyStats.stats.count {
                WLogger.shared.error(Self.loggerCategory, "Weekly stats index out of range: length: \(weeklyStats.stats.count), index: \(idx)")
                continue
            }
            
            update(stats: &weeklyStats.stats[idx], message: message)
            weeklyStats.stats[idx].messages[message.id] = message
        }
        
        var daysWithData: Int = 0
        for i in 0...weeklyStats.stats.count - 1 {
            updateTargets(forLoggingStats: &weeklyStats.stats[i], targetCalories: targetCalories, profile: profile)
            weeklyStats.hasData = weeklyStats.stats[i].hasData || weeklyStats.hasData
            
            if weeklyStats.stats[i].hasData {
                daysWithData += 1
            }
        }
        
        // Consolidate them in stats now.
        for i in 0...numDays-1 {
            var stat = weeklyStats.stats[i]
            
            updateTargets(forLoggingStats: &stat, targetCalories: targetCalories, profile: profile)
            
            weeklyStats.totalCaloriesRemaining += stat.caloriesRemaining
            weeklyStats.totalCaloriesBurned += stat.caloriesBurned
            weeklyStats.totalCaloriesConsumed += stat.caloriesConsumed
            
            weeklyStats.targetProtein += stat.targetProtein
            weeklyStats.targetCarbs += stat.targetCarbs
            weeklyStats.targetFat += stat.targetFat
            
            if !stat.hasData {
                continue
            }
            
            weeklyStats.averageProteinConsumed += stat.proteinConsumed
            
            weeklyStats.averageCarbsConsumed += stat.carbsConsumed
            
            weeklyStats.averageFatConsumed += stat.fatConsumed
            
            weeklyStats.totalDeficit += stat.caloriesRemaining
        }
        
        weeklyStats.targetCalories += weeklyStats.targetCalories / numDays
        
        weeklyStats.targetProtein = weeklyStats.targetProtein / numDays
        weeklyStats.averageProteinConsumed = weeklyStats.averageProteinConsumed / Double(daysWithData == 0 ? 1 : daysWithData)
        
        weeklyStats.targetCarbs = weeklyStats.targetCarbs / numDays
        weeklyStats.averageCarbsConsumed = weeklyStats.averageCarbsConsumed / Double(daysWithData == 0 ? 1 : daysWithData)
        
        weeklyStats.targetFat = weeklyStats.targetFat / numDays
        weeklyStats.averageFatConsumed = weeklyStats.averageFatConsumed / Double(daysWithData == 0 ? 1 : daysWithData)
        
        weeklyStats.averageDeficitPerDay = weeklyStats.totalDeficit / (daysWithData == 0 ? 1 : daysWithData)
        
        return weeklyStats
    }
    
    @MainActor
    static private func updateTargets(forLoggingStats stats: inout LoggingStats, targetCalories: Int, profile: UserProfile) {
        stats.targetCalories = profile.addBurnedCaloriesToDailyTotal ? targetCalories + Int(stats.caloriesBurned) : targetCalories
        
        stats.targetFat = getAdjustedTargetMacro(previousCalories: targetCalories, adjustedCalories: stats.targetCalories, previousMacro: profile.targetFat)
        stats.targetCarbs = getAdjustedTargetMacro(previousCalories: targetCalories, adjustedCalories: stats.targetCalories, previousMacro: profile.targetCarbs)
        stats.targetProtein = getAdjustedTargetMacro(previousCalories: targetCalories, adjustedCalories: stats.targetCalories, previousMacro: profile.targetProtein)
        
        stats.caloriesRemaining = stats.targetCalories - Int(stats.caloriesConsumed)
    }
    
    @MainActor
    static private func update(stats: inout LoggingStats, message: MobileMessage) {
        if let foodLogEntry = message.foodLog {
            update(stats: &stats, withFoodLogEntry: foodLogEntry)
        }
        
        if let activityLog = message.activityLog {
            update(stats: &stats, withActivityLog: activityLog)
        }
    }
    
    @MainActor
    static private func update(stats: inout LoggingStats, withFoodLogEntry foodLogEntry: MobileFoodLogEntry) {
        if foodLogEntry.isDeleted {
            return
        }
        
        stats.hasData = true
        stats.caloriesConsumed += foodLogEntry.calories
        stats.proteinConsumed += foodLogEntry.protein
        stats.fatConsumed += foodLogEntry.fat
        stats.carbsConsumed += foodLogEntry.carbs
        
        switch foodLogEntry.meal {
        case .breakfast:
            stats.breakfastCaloriesConsumed += foodLogEntry.calories
            stats.breakfastFoods.append(foodLogEntry)
        case .lunch:
            stats.lunchCaloriesConsumed += foodLogEntry.calories
            stats.lunchFoods.append(foodLogEntry)
        case .dinner:
            stats.dinnerCaloriesConsumed += foodLogEntry.calories
            stats.dinnerFoods.append(foodLogEntry)
        case .snack, nil:
            stats.snacksCaloriesConsumed += foodLogEntry.calories
            stats.snackFoods.append(foodLogEntry)
        }
    }
    
    static private func update(stats: inout LoggingStats, withActivityLog activityLog: MobilePhysicalActivityLog) {
        if activityLog.isDeleted {
            return
        }
        
        stats.hasData = true
        stats.caloriesBurned += activityLog.caloriesExpended
    }
    
    static private func getAdjustedTargetMacro(previousCalories: Int, adjustedCalories: Int, previousMacro: Int) -> Int {
        return lround((Double(previousMacro) / Double(previousCalories)) * Double(adjustedCalories))
    }
}

struct LoggingStatsResult {
    let stats: LoggingStats
}

@MainActor
struct WeeklyCaloriesStats {
    static let empty: WeeklyCaloriesStats = WeeklyCaloriesStats(days: 7, from: Date.distantPast)
    static let sample: WeeklyCaloriesStats = WeeklyCaloriesStats(stats: [.sample, .sample, .sample, .sample, .sample, .sample, .sample], targetCalories: 1500, totalCaloriesRemaining: 2108, totalCaloriesBurned: 4130, totalCaloriesConsumed: 5086, targetProtein: 90, averageProteinConsumed: 45.6, targetCarbs: 115, averageCarbsConsumed: 145.3, targetFat: 29, averageFatConsumed: 10.3, hasData: true, totalDeficit: 1200, averageDeficitPerDay: 156)
    
    var stats: [LoggingStats]
    
    var targetCalories: Int
    var totalCaloriesRemaining: Int
    var totalCaloriesBurned: Double
    var totalCaloriesConsumed: Double
    
    var targetProtein: Int
    var averageProteinConsumed: Double
    
    var targetCarbs: Int
    var averageCarbsConsumed: Double
    
    var targetFat: Int
    var averageFatConsumed: Double
    
    var hasData: Bool
    
    var totalDeficit: Int
    var averageDeficitPerDay: Int
    
    init(stats: [LoggingStats], targetCalories: Int, totalCaloriesRemaining: Int, totalCaloriesBurned: Double, totalCaloriesConsumed: Double, targetProtein: Int, averageProteinConsumed: Double, targetCarbs: Int, averageCarbsConsumed: Double, targetFat: Int, averageFatConsumed: Double, hasData: Bool, totalDeficit: Int, averageDeficitPerDay: Int) {
        self.stats = stats
        self.targetCalories = targetCalories
        self.totalCaloriesRemaining = totalCaloriesRemaining
        self.totalCaloriesBurned = totalCaloriesBurned
        self.totalCaloriesConsumed = totalCaloriesConsumed
        self.targetProtein = targetProtein
        self.averageProteinConsumed = averageProteinConsumed
        self.targetCarbs = targetCarbs
        self.averageCarbsConsumed = averageCarbsConsumed
        self.targetFat = targetFat
        self.averageFatConsumed = averageFatConsumed
        self.hasData = hasData
        self.totalDeficit = totalDeficit
        self.averageDeficitPerDay = averageDeficitPerDay
    }
    
    init(days: Int, from: Date) {
        self.stats = []
        for i in 1...days {
            self.stats.append(LoggingStats(day: from.advanced(by: Double((i - 1) * 60 * 60 * 24))))
        }
        self.targetCalories = 0
        self.totalCaloriesRemaining = 0
        self.totalCaloriesBurned = 0
        self.totalCaloriesConsumed = 0
        self.targetProtein = 0
        self.averageProteinConsumed = 0
        self.targetCarbs = 0
        self.averageCarbsConsumed = 0
        self.targetFat = 0
        self.averageFatConsumed = 0
        self.hasData = false
        self.totalDeficit = 0
        self.averageDeficitPerDay = 0
    }
}

@MainActor
struct LoggingStats {
    static let empty: LoggingStats = LoggingStats(day: Date.distantPast)
    static let sample: LoggingStats = LoggingStats(day: Date.init(timeIntervalSince1970: 0),targetCalories: 1800, caloriesRemaining: 1396, caloriesBurned: 2000, caloriesConsumed: 300, targetProtein: 90, proteinConsumed: 40.0, targetCarbs: 115, carbsConsumed: 145.0, targetFat: 29, fatConsumed: 13.0, breakfastCaloriesConsumed: 254, lunchCaloriesConsumed: 396, dinnerCaloriesConsumed: 195, snacksCaloriesConsumed: 986, hasData: true)
    
    var day: Date
    
    var targetCalories: Int
    var caloriesRemaining: Int
    var caloriesBurned: Double
    var caloriesConsumed: Double
    
    var targetProtein: Int
    var proteinConsumed: Double
    var targetCarbs: Int
    var carbsConsumed: Double
    var targetFat: Int
    var fatConsumed: Double
    
    var breakfastCaloriesConsumed: Double
    var lunchCaloriesConsumed: Double
    var dinnerCaloriesConsumed: Double
    var snacksCaloriesConsumed: Double
    
    var hasData: Bool
    var breakfastFoods: [MobileFoodLogEntry]
    var lunchFoods: [MobileFoodLogEntry]
    var dinnerFoods: [MobileFoodLogEntry]
    var snackFoods: [MobileFoodLogEntry]
    
    var messages: [String:MobileMessage]
    
    init(day: Date, targetCalories: Int, caloriesRemaining: Int, caloriesBurned: Double, caloriesConsumed: Double, targetProtein: Int, proteinConsumed: Double, targetCarbs: Int, carbsConsumed: Double, targetFat: Int, fatConsumed: Double, breakfastCaloriesConsumed: Double, lunchCaloriesConsumed: Double, dinnerCaloriesConsumed: Double, snacksCaloriesConsumed: Double, hasData: Bool) {
        self.day = day
        self.targetCalories = targetCalories
        self.caloriesRemaining = caloriesRemaining
        self.caloriesBurned = caloriesBurned
        self.caloriesConsumed = caloriesConsumed
        self.targetProtein = targetProtein
        self.proteinConsumed = proteinConsumed
        self.targetCarbs = targetCarbs
        self.carbsConsumed = carbsConsumed
        self.targetFat = targetFat
        self.fatConsumed = fatConsumed
        self.breakfastCaloriesConsumed = breakfastCaloriesConsumed
        self.lunchCaloriesConsumed = lunchCaloriesConsumed
        self.dinnerCaloriesConsumed = dinnerCaloriesConsumed
        self.snacksCaloriesConsumed = snacksCaloriesConsumed
        self.hasData = hasData
        self.breakfastFoods = []
        self.lunchFoods = []
        self.dinnerFoods = []
        self.snackFoods = []
        self.messages = [:]
    }
    
    init(day: Date) {
        self.day = day
        targetCalories = 0
        caloriesRemaining = 0
        caloriesBurned = 0
        caloriesConsumed = 0
        targetProtein = 0
        proteinConsumed = 0
        targetCarbs = 0
        carbsConsumed = 0
        targetFat = 0
        fatConsumed = 0
        breakfastCaloriesConsumed = 0
        lunchCaloriesConsumed = 0
        dinnerCaloriesConsumed = 0
        snacksCaloriesConsumed = 0
        hasData = false
        self.breakfastFoods = []
        self.lunchFoods = []
        self.dinnerFoods = []
        self.snackFoods = []
        self.messages = [:]
    }
    
}

enum StatsError: Error {
    case invalidDates
}

struct WeightLogStats {
    var weightStats: [WeightStat]
    var minWeight: Double
    var maxWeight: Double
    
    init(weightStats: [WeightStat], minWeight: Double, maxWeight: Double) {
        self.weightStats = weightStats
        self.minWeight = minWeight
        self.maxWeight = maxWeight
    }
    
    init() {
        weightStats = []
        minWeight = 100.0
        maxWeight = 0.0
    }
}

struct ActivityLogStats {
    static let empty: ActivityLogStats = ActivityLogStats(days: 1, from: Date.distantPast)
    
    var activityStats: [ActivityStat]
    var averageCaloriesBurnedPerDay: Int
    
    init(activityStats: [ActivityStat], averageCaloriesBurnedPerDay: Int) {
        self.activityStats = activityStats
        self.averageCaloriesBurnedPerDay = averageCaloriesBurnedPerDay
    }
    
    init(days: Int, from: Date) {
        activityStats = []
        for i in 1...days {
            self.activityStats.append(ActivityStat(day: from.advanced(by: Double((i - 1) * 60 * 60 * 24))))
        }
        averageCaloriesBurnedPerDay = 0
    }
    
    func hasData() -> Bool {
        return activityStats.contains {
            $0.hasData
        }
    }
}

struct ActivityStat {
    var day: Date
    var activities: [MobileMessage]
    var totalCaloriesBurned: Double
    var hasData: Bool
    
    init(day: Date, activities: [MobileMessage], totalCaloriesBurned: Double, hasData: Bool) {
        self.day = day
        self.activities = activities
        self.totalCaloriesBurned = totalCaloriesBurned
        self.hasData = hasData
    }
    
    init(day: Date) {
        self.day = day
        self.activities = []
        self.totalCaloriesBurned = 0.0
        self.hasData = false
    }
}
