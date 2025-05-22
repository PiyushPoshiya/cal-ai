//
//  NavigationState.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-31.
//

import Foundation
class NavigationState {
    static let shared = NavigationState()
    
    var areConversationMessagesVisible: Bool = false
    var areConversationMessagesScrolledToBottom: Bool = true
}
