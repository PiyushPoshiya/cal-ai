//
//  Utils.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-26.
//

import Foundation

class Utils {
    static func valueIfPresent<T>(value: T?, defaultValue: T) -> T {
        guard let value = value else {
            return defaultValue
        }
        
        return value
    }
}
