//
//  File.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-03.
//

import Foundation
import SwiftUI

public extension EnvironmentValues {
    var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}

public extension Date {
    static let redacted: Date = .init(timeIntervalSince1970: 0)
    
    func isSameMonth(asDate: Date) -> Bool {
        let thisComponents: DateComponents = Calendar.current.dateComponents([.year, .month], from: self)
        let otherComponents: DateComponents = Calendar.current.dateComponents([.year, .month], from: asDate)
        
        return thisComponents.year == otherComponents.year && thisComponents.month == otherComponents.month
    }
    
    func isSameDay(asDate: Date) -> Bool {
        let thisComponents: DateComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let otherComponents: DateComponents = Calendar.current.dateComponents([.year, .month, .day], from: asDate)
        
        return thisComponents.year == otherComponents.year && thisComponents.month == otherComponents.month && thisComponents.day == otherComponents.day
    }
    
    static var defaultFormatter: DateFormatter {
        let formatter = DateFormatter()
        return formatter
    }
    
    static var dateLoggedFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    static var dateLoggedWithYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    static var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM, yyyy"
        return formatter
    }
    
    static var logFoodForMealFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }
    
    static var subscriptionRenewaFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }
    
    static var notificationDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MMM-dd"
        return formatter
    }
    
    static var twelveHourFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    static var weekday: Date.FormatStyle {
        return Date.FormatStyle().weekday(.abbreviated)
    }
}
