//
//  DateUtils.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-19.
//

import Foundation

class DateUtils {
    static var UtcCalendar: Calendar {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        return utcCalendar
    }
    
    static func transform(hour: Int, inTimezone timezone: String, toTimeZone targetTimezone: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        dateFormatter.timeZone = TimeZone(identifier: timezone)
        
        guard let date = dateFormatter.date(from: String(hour)) else {
            return nil
        }
        
        dateFormatter.timeZone = TimeZone(abbreviation: targetTimezone)
        let utcHourString = dateFormatter.string(from: date)
        
        return Int(utcHourString)
    }
    
    static func getDateWith(hour: Int, inTimezone timezone: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Extract the current date components
        var dateComponents = calendar.dateComponents([.year, .month, .day, .minute, .second, .nanosecond], from: now)
        
        dateComponents.hour = hour
        dateComponents.timeZone = TimeZone(identifier: timezone)
        
        // Create the date from the components
        return calendar.date(from: dateComponents)
    }
}
