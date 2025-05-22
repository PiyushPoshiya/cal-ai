//
//  UserPreferences.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-13.
//

import Foundation

import Foundation

struct UserPreferences: Codable {
    static let empty = UserPreferences(useSystemSettingsForDarkMode: true, darkMode: false)
    
    var useSystemSettingsForDarkMode: Bool
    var darkMode: Bool
    
    init(useSystemSettingsForDarkMode: Bool, darkMode: Bool) {
        self.useSystemSettingsForDarkMode = useSystemSettingsForDarkMode
        self.darkMode = darkMode
    }
}
