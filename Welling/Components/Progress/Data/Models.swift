//
//  Models.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import Foundation

class DailyDeficit: Identifiable {
    // 0 - 7, Monday - Sunday
    var day: Int

    // Higher the defecit, the better
    var deficit: Int
    var id: UUID

    init(day: Int, deficit: Int, id: UUID = UUID()) {
        self.day = day
        self.deficit = deficit
        self.id = id
    }
}

class WeightStat: Identifiable {
    var day: Int
    var weight: Double
    var timestamp: Date
    var id: UUID

    init(day: Int, weight: Double, timestamp: Date, id: UUID = UUID()) {
        self.day = day
        self.weight = weight
        self.timestamp = timestamp
        self.id = id
    }
}
