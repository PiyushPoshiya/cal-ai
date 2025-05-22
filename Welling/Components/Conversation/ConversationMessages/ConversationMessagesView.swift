//
//  ConversationMessagesView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-25.
//

import os
import RealmSwift
import SwiftUI

struct ConversationMessagesView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ConversationMessagesView.self)
    )
    
    @EnvironmentObject var dm: DM
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    @StateObject var viewModel: ConversationMessagesViewModel = .init()
    @ObservedResults(
        MobileMessage.self,
        sortDescriptor: SortDescriptor(keyPath: "timestamp", ascending: false)
    ) var messages
    
    @State var didAlreadyAppear = false
    
    private let scrollAreaId = "scrollArea"
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(messages) { message in
                    ConversationMessageView(message: message)
                        .padding(.top, Theme.Spacing.medium)
                        .flippedUpsideDown()
                        .id(message.timestamp.timeIntervalSince1970)
                }
            }
            .animation(.easeInOut, value: messages)
        }
        .flippedUpsideDown()
        .scrollDismissesKeyboard(.interactively)
    }
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    ConversationMessagesView()
        .environmentObject(DM())
        .environment(ConversationScreenViewModel())
}
