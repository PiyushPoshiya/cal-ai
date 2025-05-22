//
//  NotificationsManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-01.
//

import Foundation
import UserNotifications
import os

class NotificationsSchedular {
    static let loggerCategory = String(describing: NotificationsSchedular.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory)

    static let shared = NotificationsSchedular()
    
    func scheduleNotYetStartedTrialNotification() async throws {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 60 * 60, repeats: false)
        
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        content.title = "Welling"
        content.body = ""
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "com.welling.Welling.FinishSignUpReminder", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleNotYetSignedUpNotification() async throws {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 60 * 60, repeats: false)
        
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        content.title = "Welling"
        content.body = ""
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "com.welling.Welling.GetStartedReminder", content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }
}
