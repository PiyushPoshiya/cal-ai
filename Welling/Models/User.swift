//
//  User.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-12.
//

import FirebaseFirestore
import Foundation
import RealmSwift

/*
 How do we know if there is a session and if the user is logged in?

 If a session exists, a user has logged in before.

 If a session exists, a user has logged in, but perhaps expired.

 Do we need to watch for the
 */

class Session {
    var sessionExpiration: Int
    var user: WellingUser

    init(sessionExpiration: Int, user: WellingUser) {
        self.sessionExpiration = sessionExpiration
        self.user = user
    }
}

class UserState: Codable {
    var uid: String
    var id: String
    var pendingMessageIds: [String]
    var processedMessageIds: [String]
}

class WellingUser: Object, Identifiable, Codable {
    static let empty = WellingUser(
        _version: 0,
        uid: "",
        id: "",
        nanoId: "",
        state: 2,
        skipSubscriptionCheck: false,
        messagesToCheckForSurvey: 0,
        surveyRespondingToName: nil,
        isRespondingToSurvey: false,
        geo: UserGeo.empty,
        timezone: "",
        profile: UserProfile.empty,
        notificationSettings: WellenUserNotificationSettings.empty,
        subscriptionState: nil,
        onboardingState: WellingUserOnboardingState.empty,
        tracking: nil,
        fcmToken: "",
        lastMessageTimestamp: nil,
        dateCreated: Date(),
        dateUpdated: Date(),
        dateDeleted: nil
    )

    static let sample = WellingUser(
        _version: 1,
        uid: "sampleUID123",
        id: "sampleID123",
        nanoId: "sampleNanoId",
        state: 1,
        skipSubscriptionCheck: true,
        messagesToCheckForSurvey: 5,
        surveyRespondingToName: "Sample Survey",
        isRespondingToSurvey: true,
        geo: UserGeo.sample,
        timezone: "PST",
        profile: UserProfile.sample,
        notificationSettings: WellenUserNotificationSettings.sample,
        subscriptionState: UserSubscriptionState.sample,
        onboardingState: WellingUserOnboardingState.sample,
        tracking: WellenUserTracking.sample,
        fcmToken: "sampleFCMToken123",
        lastMessageTimestamp: nil,
        dateCreated: Date(),
        dateUpdated: Date(),
        dateDeleted: nil
    )

    convenience init(_version: Int, uid: String, id: String, nanoId: String, state: Int, skipSubscriptionCheck: Bool, messagesToCheckForSurvey: Int, surveyRespondingToName: String? = nil, isRespondingToSurvey: Bool, geo: UserGeo, timezone: String, profile: UserProfile, notificationSettings: WellenUserNotificationSettings, subscriptionState: UserSubscriptionState? = nil, onboardingState: WellingUserOnboardingState, tracking: WellenUserTracking? = nil, fcmToken: String? = nil, lastMessageTimestamp: Date?, dateCreated: Date, dateUpdated: Date? = nil, dateDeleted: Date? = nil) {
        self.init()
        self._version = _version
        self.uid = uid
        self.id = id
        self.nanoId = nanoId
        self.state = state
        self.skipSubscriptionCheck = skipSubscriptionCheck
        self.messagesToCheckForSurvey = messagesToCheckForSurvey
        self.surveyRespondingToName = surveyRespondingToName
        self.isRespondingToSurvey = isRespondingToSurvey
        self.geo = geo
        self.timezone = timezone
        self.profile = profile
        self.notificationSettings = notificationSettings
        self.subscriptionState = subscriptionState
        self.onboardingState = onboardingState
        self.tracking = tracking
        self.fcmToken = fcmToken
        self.lastMessageTimestamp = lastMessageTimestamp
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
        self.dateDeleted = dateDeleted
    }

    @Persisted var _version: Int

    @Persisted(primaryKey: true) var uid: String

    @Persisted var id: String

    @Persisted var nanoId: String

    @Persisted var state: Int

    @Persisted var skipSubscriptionCheck: Bool

    @Persisted var messagesToCheckForSurvey: Int

    @Persisted var surveyRespondingToName: String?

    @Persisted var isRespondingToSurvey: Bool

    @Persisted var geo: UserGeo?

    @Persisted var timezone: String

    @Persisted var profile: UserProfile?

    @Persisted var notificationSettings: WellenUserNotificationSettings?

    @Persisted var subscriptionState: UserSubscriptionState?

    @Persisted var onboardingState: WellingUserOnboardingState?

    @Persisted var tracking: WellenUserTracking?

    @Persisted var fcmToken: String?

    @Persisted var favorites: List<MobileUserFavorite>

    @Persisted var appVersion: AppVersion?

    @Persisted var lastMessageTimestamp: Date?

    @Persisted var dateCreated: Date

    @Persisted var dateUpdated: Date?

    @Persisted var dateDeleted: Date?
}

protocol PAppVersion {
    var major: Int { get set }
    var minor: Int { get set }
    var patch: Int { get set }
}

struct StructAppVersion: PAppVersion, Equatable, Codable {
    var major: Int
    var minor: Int
    var patch: Int

    init(from: AppVersion) {
        self.major = from.major
        self.minor = from.minor
        self.patch = from.patch
    }

    init(fromString: String) {
        let split = fromString.split(separator: ".")
        major = 0
        minor = 0
        patch = 0

        if split.count >= 1 {
            major = Int(split[0]) ?? 0
            if split.count >= 2 {
                minor = Int(split[1]) ?? 0
                if split.count >= 3 {
                    patch = Int(split[2]) ?? 0
                }
            }
        }
    }

    static func ==(l: StructAppVersion, r: StructAppVersion) -> Bool {
        return l.major == r.major && l.minor == r.minor && l.patch == r.patch
    }
}

class AppVersion: EmbeddedObject, PAppVersion, Codable {
    @Persisted var major: Int
    @Persisted var minor: Int
    @Persisted var patch: Int

    convenience init(major: Int, minor: Int, patch: Int) {
        self.init()
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    func sameAs(s: StructAppVersion) -> Bool {
        return self.major == s.major && self.minor == s.minor && self.patch == s.patch
    }
}

protocol PMobileUserFavorite {
    var id: String { get set }
    var key: String { get set }
    var messageId: String { get set }
    var timesLogged: Int { get set }
}

class MobileUserFavorite: Object, ObjectKeyIdentifiable, PMobileUserFavorite, Codable {
    static let empty: MobileUserFavorite = MobileUserFavorite(id: "id", key: "", messageId: "", timesLogged: 0)
    static let sample: MobileUserFavorite = MobileUserFavorite(id: "id", key: "fruit", messageId: "1", timesLogged: 0)

    @Persisted(primaryKey: true) var id: String
    @Persisted var key: String
    @Persisted var messageId: String
    @Persisted var timesLogged: Int

    convenience init(id: String, key: String, messageId: String, timesLogged: Int = 0) {
        self.init()
        self.id = id
        self.key = key
        self.messageId = messageId
        self.timesLogged = timesLogged
    }
}

struct FirebaseMobileUserFavorite: PMobileUserFavorite, Codable {
    var id: String
    var key: String
    var messageId: String
    var timesLogged: Int

    init(favorite: MobileUserFavorite) {
        self.id = favorite.id
        self.key = favorite.key
        self.messageId = favorite.messageId
        self.timesLogged = favorite.timesLogged
    }
}

class WellenUserNotificationSettings: Object, Codable {
    static let empty = WellenUserNotificationSettings(
        id: nil,
        allNotifications: false,
        lunchFoodLogReminder: false,
        endOfDayCheckIn: false,
        consistentLoggingReward: false,
        educationalContent: false,
        logWeightReminder: false,
        dailyMorningCheckIn: false,
        whatsAppMarketing: false,
        lunch: nil,
        endOfDay: nil,
        weight: nil
    )

    static let sample = WellenUserNotificationSettings(
        id: "id",
        allNotifications: true,
        lunchFoodLogReminder: true,
        endOfDayCheckIn: true,
        consistentLoggingReward: true,
        educationalContent: true,
        logWeightReminder: true,
        dailyMorningCheckIn: true,
        whatsAppMarketing: true,
        lunch: .sample,
        endOfDay: .sample,
        weight: .sample
    )

    convenience init(id: String?, allNotifications: Bool, lunchFoodLogReminder: Bool, endOfDayCheckIn: Bool, consistentLoggingReward: Bool, educationalContent: Bool, logWeightReminder: Bool, dailyMorningCheckIn: Bool, whatsAppMarketing: Bool
        , lunch: NotificationSetting?, endOfDay: NotificationSetting?, weight: NotificationSetting?) {
        self.init()
        self.id = id
        self.allNotifications = allNotifications
        self.lunchFoodLogReminder = lunchFoodLogReminder
        self.endOfDayCheckIn = endOfDayCheckIn
        self.consistentLoggingReward = consistentLoggingReward
        self.educationalContent = educationalContent
        self.logWeightReminder = logWeightReminder
        self.dailyMorningCheckIn = dailyMorningCheckIn
        self.whatsAppMarketing = whatsAppMarketing
        self.lunch = lunch
        self.endOfDay = endOfDay
        self.weight = weight
    }

    @Persisted var id: String?
    @Persisted var allNotifications: Bool

    @Persisted var lunchFoodLogReminder: Bool

    @Persisted var endOfDayCheckIn: Bool

    @Persisted var consistentLoggingReward: Bool
    @Persisted var educationalContent: Bool

    @Persisted var logWeightReminder: Bool

    @Persisted var dailyMorningCheckIn: Bool
    @Persisted var whatsAppMarketing: Bool

    @Persisted var lunch: NotificationSetting?
    @Persisted var endOfDay: NotificationSetting?
    @Persisted var weight: NotificationSetting?
}

class NotificationSetting: Object, Codable {
    
    static let sample: NotificationSetting = .init(enabled: true, hour: 21, minute: 0, daysOfWeek: [false, false, false, false, false, true, false])

    @Persisted var enabled: Bool

    @Persisted var hour: Int

    @Persisted var minute: Int

    // Day of week, 1 - 7, 1 is Modnay
    @Persisted var daysOfWeek: List<Bool>
    
    convenience init(enabled: Bool, hour: Int, minute: Int, daysOfWeek: [Bool] = []) {
        self.init()
        self.enabled = enabled
        self.hour = hour
        self.minute = minute
        
        let l: List<Bool> = List<Bool>()
        l.append(objectsIn: daysOfWeek)
        self.daysOfWeek = l
    }
}

protocol PMacroProfile {
    var currentWeight: Double { get set }
    var height: Int { get set }
    var goal: UserGoal { get set }
    var activityLevel: ActivityLevel? { get set }
    var age: Int { get set }
    var gender: Gender { get set }
    var dietaryPreference: String { get set }
    var calorieOverride: Int? { get set }
    var targetCalories: Int { get set }
    var targetProteinPercentOverride: Int? { get set }
    var targetFatPercentOverride: Int? { get set }
    var targetCarbsPercentOverride: Int? { get set }
    var exerciseLevel: ExerciseLevel? { get set }
}

struct MacroProfile: PMacroProfile {
    static let empty: MacroProfile = MacroProfile(currentWeight: 0, height: 0, goal: .loseWeight, age: 0, gender: .female, dietaryPreference: "", targetCalories: 0)
    static let sample: MacroProfile = MacroProfile(currentWeight: 65, height: 165, goal: .buildMuscle, age: 35, gender: .female, dietaryPreference: "", targetCalories: 1500)

    var targetProteinPercentOverride: Int?

    var targetFatPercentOverride: Int?

    var targetCarbsPercentOverride: Int?

    var currentWeight: Double

    var height: Int

    var goal: UserGoal

    var activityLevel: ActivityLevel?

    var age: Int

    var gender: Gender

    var dietaryPreference: String

    var calorieOverride: Int?

    var targetCalories: Int

    var exerciseLevel: ExerciseLevel?

    init(targetProteinPercentOverride: Int? = nil, targetFatPercentOverride: Int? = nil, targetCarbsPercentOverride: Int? = nil, currentWeight: Double, height: Int, goal: UserGoal, activityLevel: ActivityLevel? = nil, age: Int, gender: Gender, dietaryPreference: String, calorieOverride: Int? = nil, targetCalories: Int, exerciseLevel: ExerciseLevel? = nil) {
        self.targetProteinPercentOverride = targetProteinPercentOverride
        self.targetFatPercentOverride = targetFatPercentOverride
        self.targetCarbsPercentOverride = targetCarbsPercentOverride
        self.currentWeight = currentWeight
        self.height = height
        self.goal = goal
        self.activityLevel = activityLevel
        self.age = age
        self.gender = gender
        self.dietaryPreference = dietaryPreference
        self.calorieOverride = calorieOverride
        self.targetCalories = targetCalories
        self.exerciseLevel = exerciseLevel
    }

    init(from: UserProfile) {
        self.targetProteinPercentOverride = from.targetProteinPercentOverride
        self.targetFatPercentOverride = from.targetFatPercentOverride
        self.targetCarbsPercentOverride = from.targetCarbsPercentOverride
        self.currentWeight = from.currentWeight
        self.height = from.height
        self.goal = from.goal
        self.activityLevel = from.activityLevel
        self.age = from.age
        self.gender = from.gender
        self.dietaryPreference = from.dietaryPreference
        self.calorieOverride = from.calorieOverride
        self.targetCalories = from.targetCalories
        self.exerciseLevel = from.exerciseLevel
    }
}

class UserProfile: Object, PMacroProfile, Codable {
    static let empty = UserProfile(
        email: nil,
        name: "",
        age: 30,
        height: 170,
        gender: .male,
        pregnant: nil,
        activityLevel: nil,
        exerciseLevel: nil,
        eatingDisorder: nil,
        currentWeight: 67.7,
        startingWeight: 67.7,
        dietaryPreference: "balanced",
        foodAllergies: List(),
        intolerances: List(),
        foodsToAvoid: nil,
        dietaryRestrictions: nil,
        otherConsiderations: nil,
        whyNeedCoach: nil,
        followDietChallenges: nil,
        whatIsValuableToUser: nil,
        usedNutritionCoachBefore: nil,
        usedCalorieCountingAppBefore: nil,
        mainReasonToBecomeHealthier: nil,
        importantEventComingUp: nil,
        howDidYouHearAboutWelling: nil,
        whichCommunityDidYouHearAboutFrom: nil,
        goal: UserGoal.loseWeight,
        targetWeight: 67.7,
        targetCalories: 2000,
        calorieOverride: nil,
        addBurnedCaloriesToDailyTotal: false,
        targetProteins: nil,
        targetProtein: 10,
        targetFat: 10,
        targetCarbs: 10,
        targetProteinPercentOverride: nil,
        targetFatPercentOverride: nil,
        targetCarbsPercentOverride: nil,
        remindersAndNotifications: false,
        preferredUnits: MeasurementUnit.metric
    )

    static let sample: UserProfile = {
        var allergies: List<String> = List()
        allergies.append("peanuts")

        var intolerances: List<String> = List()
        intolerances.append("alcohol")

        return UserProfile(
            email: "user@example.com",
            name: "Jane Doe",
            age: 30,
            height: 170,
            gender: .female,
            pregnant: false,
            activityLevel: ActivityLevel.HardPhysicalJob,
            exerciseLevel: .HardExerciseOrSports6To7DaysPerWeek,
            eatingDisorder: false,
            currentWeight: 65.0,
            startingWeight: 70.0,
            dietaryPreference: "Balanced diet",
            foodAllergies: allergies,
            intolerances: intolerances,
            foodsToAvoid: "sugar",
            dietaryRestrictions: "no dairy",
            otherConsiderations: "lactose intolerant",
            whyNeedCoach: "stay motivated",
            followDietChallenges: "yes",
            whatIsValuableToUser: "health",
            usedNutritionCoachBefore: "no",
            usedCalorieCountingAppBefore: "yes",
            mainReasonToBecomeHealthier: "overall wellness",
            importantEventComingUp: "marathon",
            howDidYouHearAboutWelling: "friend",
            whichCommunityDidYouHearAboutFrom: "online forum",
            goal: UserGoal.buildMuscle,
            targetWeight: 60.0,
            targetCalories: 1800,
            calorieOverride: nil,
            addBurnedCaloriesToDailyTotal: true,
            targetProteins: TargetMacroRange(min: 50, max: 150),
            targetProtein: 100,
            targetFat: 50,
            targetCarbs: 200,
            targetProteinPercentOverride: nil,
            targetFatPercentOverride: nil,
            targetCarbsPercentOverride: nil,
            remindersAndNotifications: true,
            preferredUnits: MeasurementUnit.metric
        )
    }()

    convenience init(email: String?, name: String, age: Int, height: Int, gender: Gender, pregnant: Bool?, activityLevel: ActivityLevel?, exerciseLevel: ExerciseLevel?, eatingDisorder: Bool?, currentWeight: Double, startingWeight: Double, dietaryPreference: String, foodAllergies: List<String>, intolerances: List<String>, foodsToAvoid: String?, dietaryRestrictions: String?, otherConsiderations: String?, whyNeedCoach: String?, followDietChallenges: String?, whatIsValuableToUser: String?, usedNutritionCoachBefore: String?, usedCalorieCountingAppBefore: String?, mainReasonToBecomeHealthier: String?, importantEventComingUp: String?, howDidYouHearAboutWelling: String?, whichCommunityDidYouHearAboutFrom: String?, goal: UserGoal, targetWeight: Double, targetCalories: Int, calorieOverride: Int?, addBurnedCaloriesToDailyTotal: Bool, targetProteins: TargetMacroRange?, targetProtein: Int, targetFat: Int, targetCarbs: Int, targetProteinPercentOverride: Int?, targetFatPercentOverride: Int?, targetCarbsPercentOverride: Int?, remindersAndNotifications: Bool, preferredUnits: MeasurementUnit) {
        self.init()
        self.email = email
        self.name = name
        self.age = age
        self.height = height
        self.gender = gender
        self.pregnant = pregnant
        self.activityLevel = activityLevel
        self.exerciseLevel = exerciseLevel
        self.eatingDisorder = eatingDisorder
        self.currentWeight = currentWeight
        self.startingWeight = startingWeight
        self.dietaryPreference = dietaryPreference
        self.foodAllergies = foodAllergies
        self.intolerances = intolerances
        self.foodsToAvoid = foodsToAvoid
        self.dietaryRestrictions = dietaryRestrictions
        self.otherConsiderations = otherConsiderations
        self.whyNeedCoach = whyNeedCoach
        self.followDietChallenges = followDietChallenges
        self.whatIsValuableToUser = whatIsValuableToUser
        self.usedNutritionCoachBefore = usedNutritionCoachBefore
        self.usedCalorieCountingAppBefore = usedCalorieCountingAppBefore
        self.mainReasonToBecomeHealthier = mainReasonToBecomeHealthier
        self.importantEventComingUp = importantEventComingUp
        self.howDidYouHearAboutWelling = howDidYouHearAboutWelling
        self.whichCommunityDidYouHearAboutFrom = whichCommunityDidYouHearAboutFrom
        self.goal = goal
        self.targetWeight = targetWeight
        self.targetCalories = targetCalories
        self.calorieOverride = calorieOverride
        self.addBurnedCaloriesToDailyTotal = addBurnedCaloriesToDailyTotal
        self.targetProteins = targetProteins
        self.targetProtein = targetProtein
        self.targetFat = targetFat
        self.targetCarbs = targetCarbs
        self.targetProteinPercentOverride = targetProteinPercentOverride
        self.targetFatPercentOverride = targetFatPercentOverride
        self.targetCarbsPercentOverride = targetCarbsPercentOverride
        self.remindersAndNotifications = remindersAndNotifications
        self.preferredUnits = preferredUnits
    }

    @Persisted var email: String?
    @Persisted var name: String
    @Persisted var age: Int
    @Persisted var height: Int
    @Persisted var gender: Gender
    @Persisted var pregnant: Bool?
    @Persisted var activityLevel: ActivityLevel?
    @Persisted var exerciseLevel: ExerciseLevel?
    @Persisted var eatingDisorder: Bool?
    @Persisted var currentWeight: Double
    @Persisted var startingWeight: Double
    @Persisted var dietaryPreference: String
    @Persisted var foodAllergies: List<String>
    @Persisted var intolerances: List<String>
    @Persisted var foodsToAvoid: String?
    @Persisted var dietaryRestrictions: String?
    @Persisted var otherConsiderations: String?
    @Persisted var whyNeedCoach: String?
    @Persisted var followDietChallenges: String?
    @Persisted var whatIsValuableToUser: String?
    @Persisted var usedNutritionCoachBefore: String?
    @Persisted var usedCalorieCountingAppBefore: String?
    @Persisted var mainReasonToBecomeHealthier: String?
    @Persisted var importantEventComingUp: String?
    @Persisted var howDidYouHearAboutWelling: String?
    @Persisted var whichCommunityDidYouHearAboutFrom: String?
    @Persisted var mainReasonToLoseWeight: String?
    @Persisted var mainReasonToBuildMuscle: String?
    @Persisted var mainReasonToKeepFit: String?
    @Persisted var goal: UserGoal
    @Persisted var targetWeight: Double?
    @Persisted var targetCalories: Int
    @Persisted var calorieOverride: Int?
    @Persisted var addBurnedCaloriesToDailyTotal: Bool
    @Persisted var targetProteins: TargetMacroRange?
    @Persisted var targetProtein: Int
    @Persisted var targetFat: Int
    @Persisted var targetCarbs: Int
    @Persisted var targetProteinPercentOverride: Int?
    @Persisted var targetFatPercentOverride: Int?
    @Persisted var targetCarbsPercentOverride: Int?
    @Persisted var remindersAndNotifications: Bool
    @Persisted var preferredUnits: MeasurementUnit
}

enum ExerciseLevel: String, PersistableEnum, Codable, Equatable, Identifiable {
    var id: Self {
        self
    }

    case LittleToNoExercise = "Little to no exercise"
    case LightExerciseOrSports1To3DaysPerWeek = "Light exercise or sports 1-3 times a week"
    case ModerateExerciseOrSports3To5DaysPerWeek = "Moderate exercise or sports 3-5 times a week"
    case HardExerciseOrSports6To7DaysPerWeek = "Hard exercise or sports 6-7 times a week"
    case VeryHardExerciseOrTrainingTwicePerDay = "Very hard exercise or training twice a day"

    var description: String {
        get {
            return self.rawValue
        }
    }
}


enum Gender: String, PersistableEnum, Codable, Equatable {
    case male = "male"
    case female = "female"
}

enum UserGoal: String, PersistableEnum, Codable, Equatable, Identifiable {
    var id: Self {
        self
    }

    case loseWeight = "lose weight"
    case buildMuscle = "build muscle"
    case keepfit = "keep fit"

    var description: String {
        get {
            switch self {
            case .loseWeight:
                "Lose weight"
            case .buildMuscle:
                "Build muscle"
            case .keepfit:
                "Keep fit"
            }
        }
    }

    var descriptionInSentence: String {
        get {
            switch self {
            case .loseWeight:
                "weight loss goal"
            case .buildMuscle:
                "goal to build muscle"
            case .keepfit:
                "goal to keep fit"
            }
        }
    }
}

enum MeasurementUnit: String, PersistableEnum, Codable, Equatable {
    case metric
    case imperial
}

enum ActivityLevel: String, PersistableEnum, Codable, Equatable, Identifiable {
    var id: Self {
        self
    }

    case SittingMostOfTheTime = "sittingMostOfTheTime"
    case OnMyFeetAllDay = "onMyFeetAllDay"
    case HardPhysicalJob = "hardPhysicalJob"

    var description: String {
        get {
            switch self {
            case .SittingMostOfTheTime:
                "Sitting most of the time"
            case .OnMyFeetAllDay:
                "On my feet all day"
            case .HardPhysicalJob:
                "Hard physical job"
            }
        }
    }

    var subDescription: String {
        get {
            switch self {
            case .SittingMostOfTheTime:
                "e.g. office job"
            case .OnMyFeetAllDay:
                "e.g. waiter or a nurse"
            case .HardPhysicalJob:
                "e.g. construction worker"
            }
        }
    }
}

class UserSubscriptionState: Object, Codable {
    static let empty = UserSubscriptionState(
        id: "",
        stripeCustomerId: nil as String?,
        stripeSubscriptionId: nil as String?,
        billingEmail: nil as String?,
        dateCreated: Date(),
        dateUpdated: Date(),
        userId: "",
        status: SubscriptionStatus.active,
        expiresAtUtc: 0,
        coupon: nil as String?,
        promoCode: nil as String?,
        coupon_utm_campaign: nil as String?,
        couponDescription: nil as String?,
        couponDuration: nil as String?,
        accountId: nil as String?
    )

    static let sample = UserSubscriptionState(
        id: "sampleId",
        stripeCustomerId: "sampleCustomerId",
        stripeSubscriptionId: "sampleSubscriptionId",
        billingEmail: "billing@example.com",
        dateCreated: Date(),
        dateUpdated: Date(),
        userId: "sampleUserId",
        status: SubscriptionStatus.active,
        expiresAtUtc: 1728000000, // A sample expiration timestamp
        coupon: "sampleCoupon",
        promoCode: "samplePromoCode",
        coupon_utm_campaign: "sampleCampaign",
        couponDescription: "Sample Coupon Description",
        couponDuration: "sampleDuration",
        accountId: "sampleAccountId"
    )

    convenience init(id: String, stripeCustomerId: String?, stripeSubscriptionId: String?, billingEmail: String?, dateCreated: Date, dateUpdated: Date, userId: String, status: SubscriptionStatus, expiresAtUtc: Int, coupon: String?, promoCode: String?, coupon_utm_campaign: String?, couponDescription: String?, couponDuration: String?, accountId: String?) {
        self.init()
        self.id = id
        self.stripeCustomerId = stripeCustomerId
        self.stripeSubscriptionId = stripeSubscriptionId
        self.billingEmail = billingEmail
        self.dateCreated = dateCreated
        self.dateUpdated = dateUpdated
        self.userId = userId
        self.status = status
        self.expiresAtUtc = expiresAtUtc
        self.coupon = coupon
        self.promoCode = promoCode
        self.coupon_utm_campaign = coupon_utm_campaign
        self.couponDescription = couponDescription
        self.couponDuration = couponDuration
        self.accountId = accountId
    }

    @Persisted var id: String
    @Persisted var stripeCustomerId: String?
    @Persisted var stripeSubscriptionId: String?
    @Persisted var billingEmail: String?
    @Persisted var dateCreated: Date
    @Persisted var dateUpdated: Date
    @Persisted var userId: String
    @Persisted var status: SubscriptionStatus
    @Persisted var expiresAtUtc: Int
    @Persisted var gracePeriodEndsAtUtc: Int?
    @Persisted var coupon: String?
    @Persisted var promoCode: String?
    @Persisted var coupon_utm_campaign: String?
    @Persisted var couponDescription: String?
    @Persisted var couponDuration: String?
    @Persisted var accountId: String?
}

class WellenUserTracking: EmbeddedObject, Codable {
    static let empty = WellenUserTracking(
        utm_source: nil,
        utm_medium: nil,
        utm_campaign: nil,
        utm_term: nil,
        utm_content: nil,
        browser: nil,
        device_type: nil,
        device: nil,
        os: nil,
        rawUserAgent: nil,
        signupIpAddress: nil
    )

    static let sample = WellenUserTracking(
        utm_source: "google",
        utm_medium: "cpc",
        utm_campaign: "spring_sale",
        utm_term: "wellness app",
        utm_content: "banner_ad",
        browser: "Chrome",
        device_type: "Mobile",
        device: "iPhone",
        os: "iOS",
        rawUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 13_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.4 Mobile/15E148 Safari/604.1",
        signupIpAddress: "192.168.1.1"
    )

    convenience init(utm_source: String?, utm_medium: String?, utm_campaign: String?, utm_term: String?, utm_content: String?, browser: String?, device_type: String?, device: String?, os: String?, rawUserAgent: String?, signupIpAddress: String?) {
        self.init()

        self.utm_source = utm_source
        self.utm_medium = utm_medium
        self.utm_campaign = utm_campaign
        self.utm_term = utm_term
        self.utm_content = utm_content
        self.browser = browser
        self.device_type = device_type
        self.device = device
        self.os = os
        self.rawUserAgent = rawUserAgent
        self.signupIpAddress = signupIpAddress
    }

    var utm_source: String?
    @Persisted var utm_medium: String?
    @Persisted var utm_campaign: String?
    @Persisted var utm_term: String?
    @Persisted var utm_content: String?
    @Persisted var browser: String?
    @Persisted var device_type: String?
    @Persisted var device: String?
    @Persisted var os: String?
    @Persisted var rawUserAgent: String?
    @Persisted var signupIpAddress: String?
}

enum SubscriptionStatus: String, Codable, PersistableEnum, Equatable {
    case active
    case canceled
    case incomplete
    case incomplete_expired
    case past_due
    case paused
    case trialing
    case unpaid
    case grace
    case inactive
}

class TargetMacroRange: EmbeddedObject, Codable {
    static let empty = TargetMacroRange(min: 0, max: 0)

    @Persisted var min: Int
    @Persisted var max: Int

    convenience init(min: Int, max: Int) {
        self.init()
        self.min = min
        self.max = max
    }
}

protocol PWellingUserOnboardingState {
    var version: Int { get set }
    var c1MessageGroupsSent: Int { get set }
    var firstReminder: Bool { get set }
    var photoLogging: Bool { get set }
    var loggedFirstFood: Bool? { get set }
    var loggedSecondFood: Bool { get set }
    var loggedFirstActivity: Bool? { get set }
    var loggedSecondActivity: Bool { get set }
}

struct FirebaseWellingUserOnboardingState: PWellingUserOnboardingState {
    var version: Int
    var c1MessageGroupsSent: Int
    var firstReminder: Bool
    var photoLogging: Bool
    var loggedFirstFood: Bool?
    var loggedSecondFood: Bool
    var loggedFirstActivity: Bool?
    var loggedSecondActivity: Bool

    init(from: WellingUserOnboardingState) {
        self.version = from.version
        self.c1MessageGroupsSent = from.c1MessageGroupsSent
        self.firstReminder = from.firstReminder
        self.photoLogging = from.photoLogging
        self.loggedFirstFood = from.loggedFirstFood
        self.loggedSecondFood = from.loggedSecondFood
        self.loggedFirstActivity = from.loggedFirstActivity
        self.loggedSecondActivity = from.loggedSecondActivity
    }
}

class WellingUserOnboardingState: EmbeddedObject, PWellingUserOnboardingState, Codable {
    static let empty: WellingUserOnboardingState = WellingUserOnboardingState()
    static let sample: WellingUserOnboardingState = WellingUserOnboardingState()

    convenience init(from: OnboardingStateUpdate) {
        self.init()
        c1MessageGroupsSent = from.c1MessageGroupsSent
        firstReminder = from.firstReminder
        photoLogging = from.photoLogging
        loggedSecondFood = from.loggedSecondFood
        loggedSecondActivity = from.loggedSecondActivity
    }

    @Persisted var version: Int
    @Persisted var c1MessageGroupsSent: Int
    @Persisted var firstReminder: Bool
    @Persisted var photoLogging: Bool
    @Persisted var loggedFirstFood: Bool?
    @Persisted var loggedSecondFood: Bool
    @Persisted var loggedFirstActivity: Bool?
    @Persisted var loggedSecondActivity: Bool
}


class UserGeo: EmbeddedObject, Codable {
    static let empty = UserGeo(city: "", country: "")

    static let sample = UserGeo(city: "Vancouver", country: "Canada")

    @Persisted var city: String?
    @Persisted var country: String?

    convenience init(city: String?, country: String?) {
        self.init()
        self.city = city
        self.country = country
    }
}

// Other types like WellingChatMessage, WellenUserTracking, UserProfile, UserSubscriptionState are not included here.
// You should convert them to Swift in a similar way.
