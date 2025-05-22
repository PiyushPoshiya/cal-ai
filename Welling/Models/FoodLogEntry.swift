//
//  FoodLogEntry.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import Foundation
import RealmSwift

protocol PFirebaseFoodLogFood {
    var name: String {get set}
    var brand: String {get set}
    var id: String {get set}
    var messageId: String {get set}
    var foodLogId: String {get set}
    var index: Int {get set}
    var calories: Double {get set}
    var fat: Double {get set}
    var carbs: Double {get set}
    var protein: Double {get set}
    var guardrailTriggered: Bool {get set}
    var foodId: String? {get set}
    
    var amount: Double {get set}
    var unit: String {get set}
    var portionSizeName: String? {get set}
    var portionSizeAmount: Double? {get set}
    var dateDeleted: Date? {get set}
}

struct FirebaseFoodLogFood: PFirebaseFoodLogFood, Codable {
    var name: String
    var brand: String
    var id: String
    var messageId: String
    var foodLogId: String
    var index: Int
    var calories: Double
    var fat: Double
    var carbs: Double
    var protein: Double
    var guardrailTriggered: Bool
    var foodId: String?
    var amount: Double
    var unit: String
    var portionSizeName: String?
    var portionSizeAmount: Double?
    var dateDeleted: Date?
    
    init(from: FoodLogFood) {
        self.name = from.name
        self.brand = from.brand
        self.id = from.id
        self.messageId = from.messageId
        self.foodLogId = from.foodLogId
        self.index = from.index
        self.calories = from.calories
        self.fat = from.fat
        self.carbs = from.carbs
        self.protein = from.protein
        self.guardrailTriggered = from.guardrailTriggered
        self.foodId = from.foodId
        self.amount = from.amount
        self.unit = from.unit
        self.portionSizeName = from.portionSizeName
        self.portionSizeAmount = from.portionSizeAmount
        self.dateDeleted = from.dateDeleted
    }
}

class FoodLogFood: Object, PFirebaseFoodLogFood, ObjectKeyIdentifiable, Codable {
    static let empty: FoodLogFood = .init(
        name: "",
        brand: "",
        id: "",
        messageId: "",
        foodLogId: "",
        index: 0,
        calories: 0,
        fat: 0,
        carbs: 0,
        protein: 0,
        guardrailTriggered: false,
        amount: 0,
        unit: "g",
        portionSizeName: "",
        portionSizeAmount: 0.0
    )
    static let sample1: FoodLogFood = .init(
        name: "Egg",
        brand: "Generic",
        id: "sample-food",
        messageId: "id",
        foodLogId: "",
        index: 0,
        calories: 100,
        fat: 10,
        carbs: 20,
        protein: 30,
        guardrailTriggered: false,
        amount: 100,
        unit: "g",
        portionSizeName: "Eggs",
        portionSizeAmount: 2.0
    )
    
    static let sample2: FoodLogFood = .init(
        name: "Sourdough Bread",
        brand: "Generic",
        id: "sample-food-2",
        messageId: "id",
        foodLogId: "",
        index: 1,
        calories: 200,
        fat: 20,
        carbs: 40,
        protein: 60,
        guardrailTriggered: false,
        amount: 118,
        unit: "g",
        portionSizeName: "Slice",
        portionSizeAmount: 1.5
    )
    
    static let sample3: FoodLogFood = .init(
        name: "Grilled Salmon Steak",
        brand: "Subway Sandwhich",
        id: "sample-food-3",
        messageId: "id",
        foodLogId: "",
        index: 2,
        calories: 300,
        fat: 30,
        carbs: 60,
        protein: 90,
        guardrailTriggered: false,
        amount: 154,
        unit: "g",
        portionSizeName: "Fillet",
        portionSizeAmount: 0.75
    )
    
    @Persisted var name: String
    @Persisted var brand: String
    @Persisted(primaryKey: true) var id: String
    @Persisted var messageId: String
    @Persisted var foodLogId: String
    @Persisted var index: Int
    @Persisted var calories: Double
    @Persisted var fat: Double
    @Persisted var carbs: Double
    @Persisted var protein: Double
    @Persisted var guardrailTriggered: Bool
    @Persisted var foodId: String?
    
    @Persisted var amount: Double
    @Persisted var unit: String
    @Persisted var portionSizeName: String?
    @Persisted var portionSizeAmount: Double?
    @Persisted var dateDeleted: Date?
    
    var isDeleted: Bool {
        get {
            return dateDeleted != nil
        }
    }
    
    convenience init(name: String, brand: String, id: String, messageId: String, foodLogId: String, index: Int, calories: Double, fat: Double, carbs: Double, protein: Double, guardrailTriggered: Bool, amount: Double, unit: String, portionSizeName: String?, portionSizeAmount: Double?, foodId: String? = nil, dateDeleted: Date? = nil) {
        self.init()
        self.name = name
        self.brand = brand
        self.id = id
        self.messageId = messageId
        self.foodLogId = foodLogId
        self.index = index
        self.calories = calories
        self.fat = fat
        self.carbs = carbs
        self.protein = protein
        self.amount = amount
        self.portionSizeName = portionSizeName
        self.portionSizeAmount = portionSizeAmount
        self.unit = unit
        self.guardrailTriggered = guardrailTriggered
        self.foodId = foodId
    }
    
    convenience init(from: FoodLogFood, messageId: String, foodLogId: String, withId: String) {
        self.init()
        self.name = from.name
        self.brand = from.brand
        self.id = withId
        self.messageId = messageId
        self.foodLogId = foodLogId
        self.index = from.index
        self.calories = from.calories
        self.fat = from.fat
        self.carbs = from.carbs
        self.protein = from.protein
        self.guardrailTriggered = from.guardrailTriggered
        self.foodId = from.foodId
        self.amount = from.amount
        self.unit = from.unit
        self.portionSizeName = from.portionSizeName
        self.portionSizeAmount = from.portionSizeAmount
        self.dateDeleted = from.dateDeleted
    }
}

class Food: Object, ObjectKeyIdentifiable, Codable  {
    @Persisted var id: String
    @Persisted var dateCreated: Date
    @Persisted var version: Int
    @Persisted var name: String
    @Persisted var brand: String?
    @Persisted var nutrimentSizeUnit: String
    @Persisted var nutrimentSize: Double
    @Persisted var servingSizes: List<ServingSize>
    @Persisted var calories: Double
    @Persisted var fat: Double
    @Persisted var carbs: Double
    @Persisted var protein: Double
    @Persisted var hiddenFromSearch: Bool
    @Persisted var servingSize: Double?
    @Persisted var servingSizeUnit: String?
    @Persisted var servingSizeName: String?
    @Persisted var servingSizeAmount: Double?
    @Persisted var source: String
    @Persisted var verified: Bool
    @Persisted var explicitMacros: Bool
    @Persisted var generatedByUserId: String?
    @Persisted var isCustom: Bool
    @Persisted var officialFoodId: Int?
    
    convenience init(id: String, dateCreated: Date, version: Int, name: String, brand: String? = nil, nutrimentSizeUnit: String, nutrimentSize: Double, servingSizes: List<ServingSize>, calories: Double, fat: Double, carbs: Double, protein: Double, hiddenFromSearch: Bool, servingSize: Double? = nil, servingSizeUnit: String? = nil, servingSizeName: String? = nil, servingSizeAmount: Double? = nil, source: String, verified: Bool, explicitMacros: Bool, generatedByUserId: String? = nil, isCustom: Bool, officialFoodId: Int? = nil) {
        self.init()
        self.id = id
        self.dateCreated = dateCreated
        self.version = version
        self.name = name
        self.brand = brand
        self.nutrimentSizeUnit = nutrimentSizeUnit
        self.nutrimentSize = nutrimentSize
        self.servingSizes = servingSizes
        self.calories = calories
        self.fat = fat
        self.carbs = carbs
        self.protein = protein
        self.hiddenFromSearch = hiddenFromSearch
        self.servingSize = servingSize
        self.servingSizeUnit = servingSizeUnit
        self.servingSizeName = servingSizeName
        self.servingSizeAmount = servingSizeAmount
        self.source = source
        self.verified = verified
        self.explicitMacros = explicitMacros
        self.generatedByUserId = generatedByUserId
        self.isCustom = isCustom
        self.officialFoodId = officialFoodId
    }
}

class ServingSize: Object, Codable {
    @Persisted var unit: String
    @Persisted var size: Double
    @Persisted var name: String
    @Persisted var amount: Double
    @Persisted var generated: Bool?
    convenience init(unit: String, size: Double, name: String, amount: Double, generated: Bool? = nil) {
        self.init()
        self.unit = unit
        self.size = size
        self.name = name
        self.amount = amount
        self.generated = generated
    }
}

class OfficialFood: Codable {
    var id: Int
    var dateCreated: Date
    var dateUpdated: Date
    var name: String
    var brand: String?
    var servingSize: Double?
    var servingSizeUnit: String?
    var servingSizes: [ServingSize]
    var nutrimentSize: Double
    var nutrimentSizeUnit: String
    var servingSizeName: String?
    var servingSizeAmount: Double?
    var calories: Double
    var carbs: Double
    var sugar: Double
    var dietaryFiber: Double
    var fat: Double
    var saturatedFat: Double
    var transFat: Double
    var protein: Double
    var source: String
    var sourceId: String
}
