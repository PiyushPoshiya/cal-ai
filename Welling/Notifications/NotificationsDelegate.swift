//
//  NotificationsDelegate.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-12.
//

import UserNotifications

class NotificationsDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared: NotificationsDelegate = NotificationsDelegate()
    
    // MARK: Notification receieved handlers
    
    /// Handle notifications while app is in background.
    /// This will only be triggered by actions taken by the the user.
    /// - Dismissed
    /// - Opened
    ///
    /// When this happens, we need to insert the content into the user's chat history.
    /// We can either queue it up
    ///
    /// How do we know if the user should have gotten a notification?
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler:
                                @escaping () -> Void) {
        print("NOTIFICATION RECEIVED: \(response.notification.request.content.body): \(response.actionIdentifier)")
    }
    
    /// Handle notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        print("NOTIFICATION RECEIVED: willPresent")
        let userInfo = notification.request.content.userInfo

        
        // Check if conversation screen is visible or not scrolled to bottom, then show alert.
        // Otherwise, ignore.
        
        if !NavigationState.shared.areConversationMessagesVisible || !NavigationState.shared.areConversationMessagesScrolledToBottom {
            return [[.list, .banner, .sound]]
        }
        
        return []
    }
    
    
    /// Handle delivered notifications that are still present in notification center.
    func handleDeliveredNotifications() {
        
    }
}
