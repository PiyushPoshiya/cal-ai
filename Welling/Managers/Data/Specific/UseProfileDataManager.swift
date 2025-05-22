//
//  UseProfileDataManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-26.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import os
import RealmSwift

extension DM {
    func update(user: WellingUser, appVersion: StructAppVersion) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            user.appVersion = AppVersion(major: appVersion.major, minor: appVersion.minor, patch: appVersion.patch)
            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(appVersion: appVersion, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }

    func update(user: WellingUser, fcmToken: String) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            user.fcmToken = fcmToken
            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(fcmToken: fcmToken, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    func update(user: WellingUser, timezone: String) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            user.timezone = timezone
            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(timezone: timezone, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }

    func update(user: WellingUser, notificationSettings: UserNotificationsUpdate) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now
        guard let existingSettings = user.notificationSettings else {
            return
        }

        try await realm.asyncWrite {
            user.notificationSettings = WellenUserNotificationSettings(
                id: existingSettings.id,
                allNotifications: notificationSettings.allNotifications,
                lunchFoodLogReminder: notificationSettings.lunchFoodLogReminder,
                endOfDayCheckIn: notificationSettings.endOfDayCheckIn,
                consistentLoggingReward: notificationSettings.consistentLoggingReward,
                educationalContent: notificationSettings.educationalContent,
                logWeightReminder: notificationSettings.logWeightReminder,
                dailyMorningCheckIn: notificationSettings.dailyMorningCheckIn,
                whatsAppMarketing: notificationSettings.whatsAppMarketing,
                lunch: Self.notificationSettingFrom(update: notificationSettings.lunch),
                endOfDay: Self.notificationSettingFrom(update: notificationSettings.endOfDay),
                weight: Self.notificationSettingFrom(update: notificationSettings.weight)
            )

            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(userNotificationSettings: notificationSettings, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
    
    static func notificationSettingFrom(update: NotificationUpdate) -> NotificationSetting {
        return NotificationSetting(enabled: update.enabled, hour: update.hour, minute: update.minute, daysOfWeek: update.daysOfWeek)
    }

    @MainActor
    func update(user: WellingUser, profile: UserProfile, update: UserProfilePersonalInfoUpdate, macroProfile: ComputedMacroProfile) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            profile.name = update.name
            profile.gender = update.gender
            profile.preferredUnits = update.preferredUnits
            profile.age = update.age
            profile.height = update.height

            if let geo = user.geo {
                geo.city = update.city
                geo.country = update.country
            } else {
                user.geo = UserGeo(city: update.city, country: update.country)
            }

            profile.targetCalories = macroProfile.targetCalories
            profile.calorieOverride = macroProfile.calorieOverride

            profile.targetFat = macroProfile.targetFat
            profile.targetFatPercentOverride = macroProfile.targetFatPercentOverride

            profile.targetCarbs = macroProfile.targetCarbs
            profile.targetCarbsPercentOverride = macroProfile.targetCarbsPercentOverride

            profile.targetProtein = macroProfile.targetProtein
            profile.targetProteinPercentOverride = macroProfile.targetProteinPercentOverride

            if let range = macroProfile.proteinRange {
                profile.targetProteins = TargetMacroRange(min: range.min, max: range.max)
            }

            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(userProfile: update, macroProfile: macroProfile, forUser: user.uid, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }

    func update(user: WellingUser, profile: UserProfile, restrictions: UserProfileRestrictionsUpdate) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            profile.intolerances = List()
            for intolerance in restrictions.intolerances {
                profile.intolerances.append(intolerance)
            }

            profile.foodAllergies = List()
            for allergy in restrictions.foodAllergies {
                profile.foodAllergies.append(allergy)
            }

            profile.dietaryRestrictions = restrictions.dietaryRestrictions
            profile.foodsToAvoid = restrictions.foodsToAvoid
            profile.otherConsiderations = restrictions.otherConsiderations

            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(restrictions: restrictions, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }

    func update(user: WellingUser, profile: UserProfile, update: UserDietAndMacrosUpdate, macroProfile: ComputedMacroProfile) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            profile.dietaryPreference = update.dietaryPreference

            profile.targetCalories = macroProfile.targetCalories
            profile.calorieOverride = macroProfile.calorieOverride

            profile.targetFat = macroProfile.targetFat
            profile.targetFatPercentOverride = macroProfile.targetFatPercentOverride

            profile.targetCarbs = macroProfile.targetCarbs
            profile.targetCarbsPercentOverride = macroProfile.targetCarbsPercentOverride

            profile.targetProtein = macroProfile.targetProtein
            profile.targetProteinPercentOverride = macroProfile.targetProteinPercentOverride

            if let range = macroProfile.proteinRange {
                profile.targetProteins = TargetMacroRange(min: range.min, max: range.max)
            }

            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(dietAndMacros: update, macroProfile: macroProfile, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }

    @MainActor
    func update(user: WellingUser, profile: UserProfile, update: UserProfileGoalsAndTargetUpdate, macroProfile: ComputedMacroProfile) async throws -> Void {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        let now = Date.now

        try await realm.asyncWrite {
            profile.goal = update.goal
            profile.currentWeight = update.currentWeight
            profile.targetWeight = update.targetWeight
            profile.activityLevel = update.activityLevel
            profile.exerciseLevel = update.exerciseLevel
            profile.addBurnedCaloriesToDailyTotal = update.addBurnedCaloriesToDailyTotal

            profile.targetCalories = macroProfile.targetCalories
            profile.calorieOverride = macroProfile.calorieOverride

            profile.targetFat = macroProfile.targetFat
            profile.targetFatPercentOverride = macroProfile.targetFatPercentOverride

            profile.targetCarbs = macroProfile.targetCarbs
            profile.targetCarbsPercentOverride = macroProfile.targetCarbsPercentOverride

            profile.targetProtein = macroProfile.targetProtein
            profile.targetProteinPercentOverride = macroProfile.targetProteinPercentOverride

            if let range = macroProfile.proteinRange {
                profile.targetProteins = TargetMacroRange(min: range.min, max: range.max)
            }

            user.dateUpdated = now
        }

        Task {
            do {
                try await firestore.update(goalsAndTarget: update, macroProfile: macroProfile, dateUpdated: now)
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
}

extension FirestoreDataManager {
    func update(appVersion: StructAppVersion, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "appVersion": self.encoder.encode(appVersion),
                            "dateUpdated": dateUpdated
                        ])
    }

    func update(fcmToken: String, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "fcmToken": fcmToken,
                            "dateUpdated": dateUpdated
                        ])
    }
    
    func update(timezone: String, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "timezone": timezone,
                            "dateUpdated": dateUpdated
                        ])
    }

    func update(userNotificationSettings: UserNotificationsUpdate, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "notificationSettings.allNotifications": userNotificationSettings.allNotifications,
                            "notificationSettings.lunchFoodLogReminder": userNotificationSettings.lunchFoodLogReminder,
                            "notificationSettings.endOfDayCheckIn": userNotificationSettings.endOfDayCheckIn,
                            "notificationSettings.consistentLoggingReward": userNotificationSettings.consistentLoggingReward,
                            "notificationSettings.educationalContent": userNotificationSettings.educationalContent,
                            "notificationSettings.logWeightReminder": userNotificationSettings.logWeightReminder,
                            "notificationSettings.dailyMorningCheckIn": userNotificationSettings.dailyMorningCheckIn,
                            "notificationSettings.whatsAppMarketing": userNotificationSettings.whatsAppMarketing,
                            "notificationSettings.lunch": encoder.encode(userNotificationSettings.lunch),
                            "notificationSettings.endOfDay": encoder.encode(userNotificationSettings.endOfDay),
                            "notificationSettings.weight": encoder.encode(userNotificationSettings.weight),

                            "dateUpdated": dateUpdated
                        ])
    }

    func update(userProfile: UserProfilePersonalInfoUpdate, macroProfile: ComputedMacroProfile, forUser: String, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "profile.name": userProfile.name,
                            "profile.gender": userProfile.gender.rawValue,
                            "profile.preferredUnits": userProfile.preferredUnits.rawValue,
                            "profile.age": userProfile.age,
                            "profile.height": userProfile.height,

                            "geo.city": userProfile.city,
                            "geo.country": userProfile.country,

                            "profile.targetCalories": macroProfile.targetCalories,
                            "profile.calorieOverride": macroProfile.calorieOverride,

                            "profile.targetFat": macroProfile.targetFat,
                            "profile.targetFatPercentOverride": macroProfile.targetFatPercentOverride,

                            "profile.targetCarbs": macroProfile.targetCarbs,
                            "profile.targetCarbsPercentOverride": macroProfile.targetCarbsPercentOverride,

                            "profile.targetProtein": macroProfile.targetProtein,
                            "profile.targetProteinPercentOverride": macroProfile.targetProteinPercentOverride,

                            "profile.targetProteins": macroProfile.proteinRange == nil ? nil : encoder.encode(TargetMacroRange(min: macroProfile.proteinRange!.min, max: macroProfile.proteinRange!.max)),

                            "dateUpdated": dateUpdated
                        ])
    }

    func update(restrictions: UserProfileRestrictionsUpdate, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "profile.dietaryRestrictions": restrictions.dietaryRestrictions,
                            "profile.foodsToAvoid": restrictions.foodsToAvoid,
                            "profile.otherConsiderations": restrictions.otherConsiderations,
                            "profile.foodAllergies": restrictions.foodAllergies,
                            "profile.intolerances": restrictions.intolerances,
                        ])
    }

    func update(dietAndMacros: UserDietAndMacrosUpdate, macroProfile: ComputedMacroProfile, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "profile.dietaryPreference": dietAndMacros.dietaryPreference,

                            "profile.targetCalories": macroProfile.targetCalories,
                            "profile.calorieOverride": macroProfile.calorieOverride,

                            "profile.targetFat": macroProfile.targetFat,
                            "profile.targetFatPercentOverride": macroProfile.targetFatPercentOverride,

                            "profile.targetCarbs": macroProfile.targetCarbs,
                            "profile.targetCarbsPercentOverride": macroProfile.targetCarbsPercentOverride,

                            "profile.targetProtein": macroProfile.targetProtein,
                            "profile.targetProteinPercentOverride": macroProfile.targetProteinPercentOverride,

                            "profile.targetProteins": macroProfile.proteinRange == nil ? nil : encoder.encode(TargetMacroRange(min: macroProfile.proteinRange!.min, max: macroProfile.proteinRange!.max)),

                            "dateUpdated": dateUpdated
                        ])
    }

    func update(goalsAndTarget: UserProfileGoalsAndTargetUpdate, macroProfile: ComputedMacroProfile, dateUpdated: Date) async throws {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirestoreDataManagerError.runtimeError("Current user must be logged in before you can listen to updates")
        }

        try await db
            .collection("users")
            .document(uid)
            .updateData([
                            "profile.goal": goalsAndTarget.goal.rawValue,
                            "profile.currentWeight": goalsAndTarget.currentWeight,
                            "profile.targetWeight": goalsAndTarget.targetWeight,
                            "profile.activityLevel": goalsAndTarget.activityLevel.rawValue,
                            "profile.exerciseLevel": goalsAndTarget.exerciseLevel?.rawValue,
                            "profile.addBurnedCaloriesToDailyTotal": goalsAndTarget.addBurnedCaloriesToDailyTotal,

                            "profile.targetCalories": macroProfile.targetCalories,
                            "profile.calorieOverride": macroProfile.calorieOverride,

                            "profile.targetFat": macroProfile.targetFat,
                            "profile.targetFatPercentOverride": macroProfile.targetFatPercentOverride,

                            "profile.targetCarbs": macroProfile.targetCarbs,
                            "profile.targetCarbsPercentOverride": macroProfile.targetCarbsPercentOverride,

                            "profile.targetProtein": macroProfile.targetProtein,
                            "profile.targetProteinPercentOverride": macroProfile.targetProteinPercentOverride,

                            "profile.targetProteins": macroProfile.proteinRange == nil ? nil : encoder.encode(TargetMacroRange(min: macroProfile.proteinRange!.min, max: macroProfile.proteinRange!.max)),

                            "dateUpdated": dateUpdated
                        ])
    }
}

struct UserProfilePersonalInfoUpdate {
    var name: String
    var gender: Gender
    var preferredUnits: MeasurementUnit
    var age: Int
    var height: Int
    var country: String
    var city: String
}

struct UserProfileGoalsAndTargetUpdate {
    var goal: UserGoal
    var currentWeight: Double
    var targetWeight: Double?
    var activityLevel: ActivityLevel
    var exerciseLevel: ExerciseLevel?
    var addBurnedCaloriesToDailyTotal: Bool
}

struct UserDietAndMacrosUpdate {
    var dietaryPreference: String
}

struct UserProfileRestrictionsUpdate {
    let intolerances: [String]
    let foodAllergies: [String]
    let dietaryRestrictions: String?
    let foodsToAvoid: String?
    let otherConsiderations: String?
}

struct UserNotificationsUpdate: Codable {
    var allNotifications: Bool

    var lunchFoodLogReminder: Bool
    var endOfDayCheckIn: Bool
    var consistentLoggingReward: Bool
    var educationalContent: Bool
    var logWeightReminder: Bool
    var dailyMorningCheckIn: Bool
    var whatsAppMarketing: Bool

    var lunch: NotificationUpdate
    var endOfDay: NotificationUpdate
    var weight: NotificationUpdate
}

struct NotificationUpdate: Codable {
    var enabled: Bool
    var hour: Int
    var minute: Int
    var daysOfWeek: [Bool]
    
    init(enabled: Bool, hour: Int, minute: Int, daysOfWeek: [Bool] = []) {
        self.enabled = enabled
        self.hour = hour
        self.minute = minute
        self.daysOfWeek = daysOfWeek
    }
    
    init(setting: NotificationSetting) {
        self.enabled = setting.enabled
        self.hour = setting.hour
        self.minute = setting.minute
        self.daysOfWeek = Array(setting.daysOfWeek)
    }
}
