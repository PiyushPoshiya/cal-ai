//
//  CalendarExtensions.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-28.
//

import Foundation

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        return self.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: date).date!
    }
}
