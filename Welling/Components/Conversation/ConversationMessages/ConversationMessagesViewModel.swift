//
//  ConversationMessagesViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import Foundation
import os
import RealmSwift
import SwiftUI

@Observable
class ConversationMessagesViewModel: ObservableObject {
    static let loggerCategory =  String(describing: ConversationMessagesViewModel.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )
    private static let LOAD_MORE_COUNT = 25
    
    var canLoadMore: Bool = true
    var isLoadingMore: Bool = false
    var totalMessagesToLoad: Int = 10
    
    @ObservationIgnored var firstTimestamp: Date?
    @ObservationIgnored var didAlreadyAppear: Bool = false
    
    @MainActor
    func finishedLoadingMoreFromApi(realmDm: DM, result: FetchResult<Int>) {
        if let error: ResultError = result.error {
            let s = "\(error)"
            Self.logger.error("Erorr loading chat history because \(s)")
            return
        }
        
        guard let count = result.value else {
            Self.logger.error("Expected value without error when loading more chat messages")
            return
        }
        WLogger.shared.error(Self.loggerCategory, "Loaded \(count) more messages")
        canLoadMore = count >= ConversationMessagesViewModel.LOAD_MORE_COUNT
    }
}
