//
//  Chat.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-18.
//

import Foundation
import RealmSwift

class MobilePhysicalActivityLog: Object, ObjectKeyIdentifiable, Codable {
    static let sample: MobilePhysicalActivityLog = .init(
        id: "1",
        name: "5 mile run",
        amount: "5 miles",
        mets: 12,
        userDescription: "I ran 5 miles",
        caloriesExpended: 600,
        evaluation: "Great work!",
        timestamp: Date.distantFuture,
        dateUpdated: Date.distantFuture
        
    )
    
    static let redacted: MobilePhysicalActivityLog = .init(
        id: "1",
        name: "Redacted workout",
        amount: "5 miles",
        mets: 12,
        userDescription: "Redacted workout description",
        caloriesExpended: 600,
        evaluation: "Redacted evaluation.",
        timestamp: Date.redacted,
        dateUpdated: Date.redacted
    )
    
    @Persisted(primaryKey: true) var id: String
    
    @Persisted var name: String
    @Persisted var amount: String
    @Persisted var mets: Double
    @Persisted var userDescription: String
    @Persisted var caloriesExpended: Double
    
    @Persisted var evaluation: String?
    
    @Persisted var timestamp: Date
    @Persisted var dateUpdated: Date
    @Persisted var dateDeleted: Date?
    
    var isDeleted: Bool {
        get {
            return dateDeleted != nil
        }
    }
    
    convenience init(id: String, name: String, amount: String, mets: Double, userDescription: String, caloriesExpended: Double, evaluation: String? = nil, timestamp: Date, dateUpdated: Date, dateDeleted: Date? = nil) {
        self.init()
        self.name = name
        self.amount = amount
        self.mets = mets
        self.userDescription = userDescription
        self.caloriesExpended = caloriesExpended
        self.evaluation = evaluation
        self.timestamp = timestamp
        self.dateUpdated = dateUpdated
        self.dateDeleted = dateDeleted
    }
}

protocol PFirebaseMobileFoodLogEntry {
    var _version: Int {get set}
    
    var id: String {get set}
    var messageId: String {get set}
    
    var userDescription: String {get set}
    var meal: Meal? {get set}
    var evaluation: String? {get set}
    
    var calories: Double {get set}
    var fat: Double {get set}
    var carbs: Double {get set}
    var protein: Double {get set}
    
    var timestamp: Date {get set}
    var dateUpdated: Date? {get set}
    var dateDeleted: Date? {get set}
}

struct FirebaseMobileFoodLogEntry: PFirebaseMobileFoodLogEntry, Codable {
    var _version: Int
    var id: String
    var messageId: String
    var userDescription: String
    var meal: Meal?
    var evaluation: String?
    var calories: Double
    var fat: Double
    var carbs: Double
    var protein: Double
    var timestamp: Date
    var dateUpdated: Date?
    var dateDeleted: Date?
    
    init(from: MobileFoodLogEntry) {
        self._version = from._version
        self.id = from.id
        self.messageId = from.messageId
        self.userDescription = from.userDescription
        self.meal = from.meal
        self.evaluation = from.evaluation
        self.calories = from.calories
        self.fat = from.fat
        self.carbs = from.carbs
        self.protein = from.protein
        self.timestamp = from.timestamp
        self.dateUpdated = from.dateUpdated
        self.dateDeleted = from.dateDeleted
    }
}

class MobileFoodLogEntry: Object, ObjectKeyIdentifiable, PFirebaseMobileFoodLogEntry, Codable {
    static let redacted: MobileFoodLogEntry = {
        let foods: List<FoodLogFood> = List()
        foods.append(objectsIn: [FoodLogFood.sample1, FoodLogFood.sample2, FoodLogFood.sample3])
        return MobileFoodLogEntry(
            _version: 1,
            id: "id",
            messageId: "messageId",
            userDescription: "This will be redacted",
            meal: Meal.breakfast,
            calories: 100,
            fat: 99,
            carbs: 99,
            protein: 99,
            foods: foods,
            timestamp: Date.redacted,
            evaluation: "Good to eat more"
        )
    }()
    
    static let sample: MobileFoodLogEntry = {
        let foods: List<FoodLogFood> = List()
        foods.append(objectsIn: [FoodLogFood.sample1, FoodLogFood.sample2, FoodLogFood.sample3])
        return MobileFoodLogEntry(
            _version: 1,
            id: "id",
            messageId: "messageId",
            userDescription: "This is a sample food log",
            meal: Meal.breakfast,
            calories: 100,
            fat: 99,
            carbs: 99,
            protein: 99,
            foods: foods,
            timestamp: Date(),
            dateDeleted: Date()
        )
    }()
    
    @Persisted var _version: Int
    
    @Persisted(primaryKey: true) var id: String
    @Persisted var messageId: String
    
    @Persisted var userDescription: String
    @Persisted var meal: Meal?
    @Persisted var evaluation: String?
    
    @Persisted var calories: Double
    @Persisted var fat: Double
    @Persisted var carbs: Double
    @Persisted var protein: Double
    
    @Persisted var foods: List<FoodLogFood>
    
    @Persisted var timestamp: Date
    @Persisted var dateUpdated: Date?
    @Persisted var dateDeleted: Date?
    
    var isDeleted: Bool {
        get {
            return dateDeleted != nil
        }
    }
    
    convenience init(_version: Int, id: String, messageId: String, userDescription: String, meal: Meal?, calories: Double, fat: Double, carbs: Double, protein: Double, foods: List<FoodLogFood>, timestamp: Date, dateUpdated: Date? = nil, dateDeleted: Date? = nil, evaluation: String? = nil) {
        self.init()
        self._version = _version
        self.id = id
        self.messageId = messageId
        self.meal = meal
        self.userDescription = userDescription
        self.calories = calories
        self.fat = fat
        self.carbs = carbs
        self.protein = protein
        self.foods = foods
        self.timestamp = timestamp
        self.dateUpdated = dateUpdated
        self.dateDeleted = dateDeleted
        self.evaluation = evaluation
    }
    
    convenience init(firebase: FirebaseMobileFoodLogEntry, foods: [FoodLogFood]) {
        self.init()
        self._version = firebase._version
        self.id = firebase.id
        self.messageId = firebase.messageId
        self.meal = firebase.meal
        self.userDescription = firebase.userDescription
        self.calories = firebase.calories
        self.evaluation = firebase.evaluation
        self.fat = firebase.fat
        self.carbs = firebase.carbs
        self.protein = firebase.protein
        self.foods = List()
        for food in foods {
            self.foods.append(food)
        }
        self.timestamp = firebase.timestamp
        self.dateUpdated = firebase.dateUpdated
        self.dateDeleted = firebase.dateDeleted
    }
    
    func anyFoods() -> Bool {
        for food in foods {
            if !food.isDeleted {
                return true
            }
        }
        
        return false
    }
}

extension [MobileFoodLogEntry] {
    func anyFoods() -> Bool {
        for entry in self {
            if entry.anyFoods() {
                return true
            }
        }
        
        return false
    }
}

class MobileWeightLog: Object, ObjectKeyIdentifiable, Codable {
    static let redacted: MobileWeightLog = .init(
        id: "",
        weightInKg: 123,
        evaluation: "Good job for logging, keep it up.",
        timestamp: Date.redacted
    )
    
    static let sample: MobileWeightLog = .init(
        id: "1",
        weightInKg: 67.6,
        evaluation: "Good job for logging, keep it up.",
        timestamp: Date.distantFuture)
    
    @Persisted(primaryKey: true) var id: String
    
    @Persisted var weightInKg: Double
    
    @Persisted var evaluation: String?
    
    @Persisted var timestamp: Date
    @Persisted var dateUpdated: Date?
    @Persisted var dateDeleted: Date?
    
    var isDeleted: Bool {
        get {
            return dateDeleted != nil
        }
    }
    
    convenience init(id: String, weightInKg: Double, evaluation: String? = nil, timestamp: Date, dateUpdated: Date? = nil, dateDeleted: Date? = nil) {
        self.init()
        self.id = id
        self.weightInKg = weightInKg
        self.evaluation = evaluation
        self.timestamp = timestamp
        self.dateUpdated = dateUpdated
        self.dateDeleted = dateDeleted
    }
}

enum MessageProcessingState: String, PersistableEnum, CaseIterable, Codable, Equatable {
    case saved
    case sendingFailed
    case queued
    case processing
    case completed
    // A special state for reply messages inside a user's message
    case reply
    case error
    case dailyOnTrialImageRateLimitExceeded
    case dailyOnTrialMessageRateLimitExceeded
    case dailySubscribedMessageRateLimitExceeded
    case subscriptionExpired
}

enum ImageProcessingState: String, PersistableEnum, CaseIterable, Codable, Equatable {
    case saved
    case uploading
    case uploaded
    case uploadFailed
}

enum Meal: String, PersistableEnum, CaseIterable, Codable, Equatable {
    case breakfast
    case lunch
    case dinner
    case snack
}

extension Meal {
    func displayString() -> String {
        switch self {
        case .breakfast:
            "Breakfast"
        case .lunch:
            "Lunch"
        case .dinner:
            "Dinner"
        case .snack:
            "Snack"
        }
    }
}

class MobileMessageImageClassification: EmbeddedObject, Codable {
    @Persisted var hasFood: Bool
    @Persisted var hasPackagedFood: Bool
    @Persisted var hasNutritionLabel: Bool
    @Persisted var hasFoodMenu: Bool
}

class MobileMessageImage: EmbeddedObject, Codable {
    @Persisted var localPath: String
    @Persisted var fbFullPath: String
    @Persisted var downloadURL: String?
    @Persisted var state: ImageProcessingState
    @Persisted var classification: MobileMessageImageClassification?
    
    convenience init(localPath: String, fbFullPath: String, downloadURL: String?, state: ImageProcessingState, classification: MobileMessageImageClassification? = nil) {
        self.init()
        self.localPath = localPath
        self.fbFullPath = fbFullPath
        self.downloadURL = downloadURL
        self.state = state
        self.classification = classification
    }
}

enum MobileMessageClassification: String, PersistableEnum, CaseIterable, Codable, Equatable {
    case foodEaten = "food_eaten"
    case foodLogEdit = "food_log_edit"
    case activity
    case weightLog = "weight_log"
    case dailyTotal = "daily_total"
    case editAccount = "edit_account"
    case logFavoriteFood = "log_favorite_food"
    case logFrequentFood = "log_frequent_food"
    case command
    case other
    case error
    case none
}

enum MobileMessageType: String, PersistableEnum, CaseIterable, Codable, Equatable {
    case welcome
    case other
    case foodLogPreview
    case foodLogged
    case activityLogged
    case weightLogged
    case foodLogEdited
    case foodFavorited
    case foodLogUndone
    case foodLogEvaluation
    case activityLogUndone
    case weightLogUndone
    case foodUnfavorited
    case reminder
    
    case lunchFoodLogReminder
    case endOfDayCheckInReminder
    case weightLogReminder
    
    case onboarding
    case dailyTotal
    case loginOtp
    case dashboard
    case contactTeamReply
    case favourites
    case frequentFoodsList
    case error
}

protocol PFirebaseMobileMessage {
    var _version: Int { get set }
    
    var id: String { get set }
    
    // The processing state of the message
    var state: MessageProcessingState { get set }
    
    // The classification of the user's message
    var classification: MobileMessageClassification? { get set }
    
    // The type of the message's reply
    var messageType: MobileMessageType { get set }
    
    var fromSystem: Bool { get set }
    var text: String? { get set }
    var image: MobileMessageImage? { get set }
    var mealHint: Meal? { get set }
    
    var replyingToMessageId: String? { get set }
    
    var activityLog: MobilePhysicalActivityLog? { get set }
    var weightLog: MobileWeightLog? { get set }
    var logTimestamp: Date? { get set }
    
    var replies: List<MobileMessage> { get set }
    
    var ignoreForPrompt: Bool? { get set }
    
    var timestamp: Date { get set }
    var dateUpdated: Date? { get set }
}

struct FirebaseMobileMessage: PFirebaseMobileMessage, Codable {
    var _version: Int
    
    var id: String
    
    var state: MessageProcessingState
    var classification: MobileMessageClassification?
    var messageType: MobileMessageType
    
    var fromSystem: Bool
    var text: String?
    var image: MobileMessageImage?
    var mealHint: Meal?
    var replyingToMessageId: String?
    
    var activityLog: MobilePhysicalActivityLog?
    var weightLog: MobileWeightLog?
    var logTimestamp: Date?
    
    var replies: List<MobileMessage>
    
    var ignoreForPrompt: Bool?
    
    var timestamp: Date
    var dateUpdated: Date?
    
    var foodLog: FirebaseMobileFoodLogEntry?
    var favoriteFood: FirebaseMobileFoodLogEntry?
    
    init(from: MobileMessage) {
        self._version = from._version
        self.id = from.id
        self.state = from.state
        self.classification = from.classification
        self.messageType = from.messageType
        self.fromSystem = from.fromSystem
        self.text = from.text
        self.image = from.image
        self.mealHint = from.mealHint
        self.replyingToMessageId = from.replyingToMessageId
        self.activityLog = from.activityLog
        self.weightLog = from.weightLog
        self.logTimestamp = from.logTimestamp
        self.timestamp = from.timestamp
        self.dateUpdated = from.dateUpdated
        self.replies = List()
        for reply in from.replies {
            self.replies.append(reply)
        }
        
        self.ignoreForPrompt = from.ignoreForPrompt
        
        if let fromFoodLog = from.foodLog {
            self.foodLog = FirebaseMobileFoodLogEntry(from: fromFoodLog)
        }
        
        if let fromFavoriteFood = from.favoriteFood {
            self.favoriteFood = FirebaseMobileFoodLogEntry(from: fromFavoriteFood)
        }
    }
}

class MobileMessage: Object, Identifiable, PFirebaseMobileMessage, Codable {
    static let sample: MobileMessage = {
        let replies: List<MobileMessage> = List()
        return MobileMessage(
            _version: 1,
            id: "id",
            state: MessageProcessingState.completed,
            classification: MobileMessageClassification.other,
            messageType: MobileMessageType.other,
            fromSystem: false,
            text: "This is a sample message",
            image: nil as MobileMessageImage?,
            replyingToMessageId: nil as String?,
            foodLog: nil as MobileFoodLogEntry?,
            activityLog: nil as MobilePhysicalActivityLog?,
            weightLog: nil as MobileWeightLog?,
            favoriteFood: nil as MobileFoodLogEntry?,
            logTimestamp: nil,
            replies: replies,
            ignoreForPrompt: nil,
            timestamp: Date(),
            dateUpdated: Date()
        )
    }()
    
    static let saved: MobileMessage = {
        let replies: List<MobileMessage> = List()
        return MobileMessage(
            _version: 1,
            id: "id",
            state: MessageProcessingState.saved,
            classification: MobileMessageClassification.other,
            messageType: MobileMessageType.other,
            fromSystem: false,
            text: "This is a sample message",
            image: nil as MobileMessageImage?,
            replyingToMessageId: nil as String?,
            foodLog: nil as MobileFoodLogEntry?,
            activityLog: nil as MobilePhysicalActivityLog?,
            weightLog: nil as MobileWeightLog?,
            favoriteFood: nil as MobileFoodLogEntry?,
            logTimestamp: nil,
            replies: replies,
            ignoreForPrompt: nil,
            timestamp: Date(),
            dateUpdated: Date()
        )
    }()
    
    static let withFoodLogRedacted: MobileMessage = {
        let replies: List<MobileMessage> = List()
        return MobileMessage(
            _version: 1,
            id: "id",
            state: MessageProcessingState.saved,
            classification: MobileMessageClassification.foodEaten,
            messageType: MobileMessageType.other,
            fromSystem: false,
            text: "This is a sample message",
            image: nil as MobileMessageImage?,
            replyingToMessageId: nil as String?,
            foodLog: nil as MobileFoodLogEntry?,
            activityLog: nil as MobilePhysicalActivityLog?,
            weightLog: nil as MobileWeightLog?,
            favoriteFood: nil as MobileFoodLogEntry?,
            logTimestamp: nil,
            replies: replies,
            ignoreForPrompt: nil,
            timestamp: Date(),
            dateUpdated: Date()
        )
    }()
    
    static let withFoodLog: MobileMessage = {
        let replies: List<MobileMessage> = List()
        return MobileMessage(
            _version: 1,
            id: "id",
            state: MessageProcessingState.saved,
            classification: MobileMessageClassification.foodEaten,
            messageType: MobileMessageType.other,
            fromSystem: false,
            text: "This is a sample message",
            image: nil as MobileMessageImage?,
            replyingToMessageId: nil as String?,
            foodLog: .sample,
            activityLog: nil as MobilePhysicalActivityLog?,
            weightLog: nil as MobileWeightLog?,
            favoriteFood: nil as MobileFoodLogEntry?,
            logTimestamp: nil,
            replies: replies,
            ignoreForPrompt: nil,
            timestamp: Date(),
            dateUpdated: Date()
        )
    }()
    
    @Persisted var _version: Int
    @Persisted(primaryKey: true) var id: String
    
    @Persisted var uid: String?
    
    @Persisted var state: MessageProcessingState
    @Persisted var classification: MobileMessageClassification?
    @Persisted var messageType: MobileMessageType
    
    @Persisted var fromSystem: Bool
    @Persisted var text: String?
    @Persisted var image: MobileMessageImage?
    @Persisted var mealHint: Meal?
    
    @Persisted var replyingToMessageId: String?
    
    @Persisted var foodLog: MobileFoodLogEntry?
    @Persisted var activityLog: MobilePhysicalActivityLog?
    @Persisted var weightLog: MobileWeightLog?
    @Persisted var favoriteFood: MobileFoodLogEntry?
    @Persisted var logTimestamp: Date?
    
    @Persisted var replies: List<MobileMessage>
    
    @Persisted var ignoreForPrompt: Bool?
    
    @Persisted(indexed: true) var timestamp: Date
    @Persisted var dateUpdated: Date?
    
    convenience init(_version: Int, id: String, state: MessageProcessingState, classification: MobileMessageClassification?, messageType: MobileMessageType, fromSystem: Bool, text: String?, image: MobileMessageImage?, replyingToMessageId: String?, foodLog: MobileFoodLogEntry?, activityLog: MobilePhysicalActivityLog?, weightLog: MobileWeightLog?, favoriteFood: MobileFoodLogEntry?, logTimestamp: Date?, replies: List<MobileMessage>, ignoreForPrompt: Bool?, timestamp: Date, dateUpdated: Date? = nil) {
        self.init()
        self._version = _version
        self.id = id
        self.state = state
        self.classification = classification
        self.messageType = messageType
        self.fromSystem = fromSystem
        self.text = text
        self.image = image
        self.replyingToMessageId = replyingToMessageId
        self.foodLog = foodLog
        self.activityLog = activityLog
        self.weightLog = weightLog
        self.favoriteFood = favoriteFood
        self.logTimestamp = logTimestamp
        self.replies = replies
        self.ignoreForPrompt = ignoreForPrompt
        self.timestamp = timestamp
        self.dateUpdated = dateUpdated
    }
    
    convenience init(firebase: FirebaseMobileMessage, foodLog: MobileFoodLogEntry?, favoriteFood: MobileFoodLogEntry?) {
        self.init()
        self._version = firebase._version
        self.id = firebase.id
        self.state = firebase.state
        self.classification = firebase.classification
        self.messageType = firebase.messageType
        self.fromSystem = firebase.fromSystem
        self.text = firebase.text
        self.image = firebase.image
        self.replyingToMessageId = firebase.replyingToMessageId
        self.foodLog = foodLog
        self.activityLog = firebase.activityLog
        self.weightLog = firebase.weightLog
        self.favoriteFood = favoriteFood
        self.ignoreForPrompt = firebase.ignoreForPrompt
        self.logTimestamp = firebase.logTimestamp
        self.replies = firebase.replies
        self.timestamp = firebase.timestamp
        self.dateUpdated = firebase.dateUpdated
    }
}

enum ChatMessageChannel: String, PersistableEnum, CaseIterable, Equatable {
    case whatsapp
    case twilio
    case mobileApp = "mobile-app"
}
