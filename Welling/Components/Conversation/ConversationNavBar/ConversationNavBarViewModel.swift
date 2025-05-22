//
//  ConversationNavBarViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import Foundation
import RealmSwift

class ConversationNavBarViewModel: ObservableObject {
    @Published var caloriesRemaining: String = ""
    
    var um: UserManager = .notLoggedIn
    var dm: DM?
    var messagesNotificationToken: NotificationToken?
    var profileNotificationToken: NotificationToken?
    
    @MainActor
    func onAppear(realmDataManager: DM, um: UserManager) {
        self.um = um
        self.dm = realmDataManager
        refresh()
        messagesNotificationToken = realmDataManager
            .realm
            .objects(MobileMessage.self)
            .observe(self.onMessagesChanged)
        profileNotificationToken = realmDataManager
            .realm
            .object(ofType: WellingUser.self, forPrimaryKey: um.user.uid)?
            .observe(self.onUserChanged)
    }
    
    @MainActor
    func onMessagesChanged(change: RealmCollectionChange<Results<MobileMessage>>) -> Void {
        refresh()
    }
    
    @MainActor
    func onUserChanged(change: ObjectChange<WellingUser>) -> Void {
        refresh()
    }
   
    @MainActor
    func refresh() {
        guard let dm = self.dm else {
            return
        }
        
        let stats: LoggingStats = StatsUtils.getTodaysStats(dm: dm, profile: self.um.user.profile ?? .empty)
        
        caloriesRemaining = stats.caloriesRemaining.formatted()
    }
}
