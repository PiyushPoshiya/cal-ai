//
//  Date.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-18.
//

import Foundation


class DateUtils {
    /**
     Given an hour and specic timezone, get what the same hour be in UTC at that same moment.
     */
    static func getUtc(hour: Int, inTimezone timezone: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH"
        dateFormatter.timeZone = TimeZone(identifier: timezone)

        guard let date = dateFormatter.date(from: String(hour)) else {
            return nil
        }

        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let utcHourString = dateFormatter.string(from: date)
        
        return Int(utcHourString)
    }
}
