//
//  ConversationMessagesListView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-10.
//

import SwiftUI
import UIKit
import RealmSwift

public extension Notification.Name {
    static let onScrollToBottom = Notification.Name("onScrollToBottom")
    static let fcmToken = Notification.Name("FCMToken")
}

class WellingUITableView: UITableView {
    var messagesChangeNotificationToken: NotificationToken? = nil
    let messages: Results<MobileMessage>
    
    init(messages: Results<MobileMessage>) {
        self.messages = messages
        super.init(frame: .zero, style: .plain)
        self.messagesChangeNotificationToken = messages.observe(self.onMessageChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.messagesChangeNotificationToken?.invalidate()
    }
    
    func onMessageChanged(changes: RealmCollectionChange<Results<MobileMessage>>) {
        DispatchQueue.main.async {
            switch changes {
            case .initial:
//                // Results are now populated and can be accessed without blocking the UI
//                self.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                
                if insertions.count == 0 && modifications.count == 0 && deletions.count == 0 {
                    return
                }
                
                self.beginUpdates()
                if insertions.count > 0 {
                    let fromSystem = insertions.filter {
                        self.messages[$0].fromSystem == true || self.messages[$0].classification != .other
                    }
                    
                    let others = insertions.filter { fromSystem.firstIndex(of: $0) == nil }
                    if fromSystem.count > 0 {
                        self.insertRows(at: fromSystem.map { IndexPath(row: $0, section: 0) }, with: .top)
                    }
                    
                    if others.count > 0 {
                        self.insertRows(at: others.map { IndexPath(row: $0, section: 0) }, with: .top)
                    }
                }

                if deletions.count > 0 {
                    self.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                }

                if modifications.count > 0 {
                    self.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                }
                self.endUpdates()
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
    }
}

struct ConversationMessagesListView: UIViewRepresentable {
    
//    @Binding var isScrolledToBottom: Bool
//    @Binding var shouldScrollToTop: () -> ()
    
    var messages: Results<MobileMessage>
    var lastChange: RealmCollectionChange<Results<MobileMessage>>? = nil
    var messagesChangeNotificationToken: NotificationToken? = nil
    
    @MainActor
    init(dm: DM) {
        messages = dm.realm.objects(MobileMessage.self).sorted(by: \.timestamp, ascending: false)
    }
    
    static func dismantleUIView(_ uiView: UITableView, coordinator: ConversationMessagesListTableViewController) {
    }
    
    func makeUIView(context: Context) -> UITableView {
        let tableView = WellingUITableView(messages: messages)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.sectionHeaderHeight = 0

        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedSectionHeaderHeight = .leastNormalMagnitude
        tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
        tableView.backgroundColor = UIColor(Theme.Colors.SurfaceNeutral05)
        tableView.scrollsToTop = false
        tableView.keyboardDismissMode = .onDrag
        
        NotificationCenter.default.addObserver(forName: .onScrollToBottom, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                if tableView.numberOfRows(inSection: 0) == 0 {
                    return
                }
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }

//        DispatchQueue.main.async {
//            shouldScrollToTop = {
//                tableView.contentOffset = CGPoint(x: 0, y: tableView.contentSize.height - tableView.frame.height)
//            }
//        }

        return tableView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) {
        
    }
    
    func makeCoordinator() -> ConversationMessagesListTableViewController {
        return ConversationMessagesListTableViewController(messages: messages)
    }
}

class ConversationMessagesListTableViewController:  NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var messages: Results<MobileMessage>
    
    init(messages: Results<MobileMessage>) {
        self.messages = messages
        super.init()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return messages.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none

        let message = messages[indexPath.row]
        
        cell.contentConfiguration = UIHostingConfiguration {
            ConversationMessageView(message: message)
                .id(message.timestamp)
                .padding(.top, Theme.Spacing.medium)
                .transition(.scale)
        }
        .minSize(width: 0, height: 0)
        .margins(.all, 0.0)
        cell.backgroundColor = .clear
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        return cell
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        isScrolledToBottom = scrollView.contentOffset.y <= 0
//        isScrolledToTop = scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.height - 1
//    }
}
