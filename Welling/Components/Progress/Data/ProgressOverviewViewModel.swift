//
//  ProgressViewModel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import Foundation
import RealmSwift
import os

@MainActor
class ProgressOverviewViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ProgressOverviewViewModel.self))
    
    var um: UserManager = .notLoggedIn
    var dm: DM?
    var messagesNotificationToken: NotificationToken?
    var profileNotificationToken: NotificationToken?

    @Published var presentDailyTotalsSheet: Bool = false

    @Published var hasAverageWeeklyDeficit: Bool = false
    @Published var weeklyAverageDeficit: Int = 0

    @Published var last30DaysWeight: [WeightStat] = []
    @Published var yAxisMin: Int = 0
    @Published var yAxisMax: Int = 1

    @Published var today: Date = .distantPast
    
    @Published var dailyStats: LoggingStats = .empty

    @MainActor
    func onAppear(realmDataManager: DM, um: UserManager) {
        self.dm = realmDataManager
        self.um = um
        messagesNotificationToken = realmDataManager
            .realm
            .objects(MobileMessage.self)
            .observe(self.onMessagesChanged)
        profileNotificationToken = realmDataManager
            .realm
            .object(ofType: WellingUser.self, forPrimaryKey: um.user.uid)?
            .observe(self.onUserChanged)
    }
    
    deinit {
        messagesNotificationToken?.invalidate()
        profileNotificationToken?.invalidate()
    }

    @MainActor
    func onMessagesChanged(change: RealmCollectionChange<Results<MobileMessage>>) -> Void {
        reloadStats()
    }

    @MainActor
    func onUserChanged(change: ObjectChange<WellingUser>) -> Void {
        reloadStats()
    }

    private func resetValues() {
        weeklyAverageDeficit = 0
        last30DaysWeight = []
    }
    
    @MainActor
    func reloadStats() {
        guard let dm = dm else {
            return
        }
        
        guard let profile = um.user.profile else {
            return
        }

        resetValues()
        
        // Get messages for week
        // Get weight logs for last 30 days.
        today = Calendar.current.startOfDay(for: Date.now)
        let endOfToday: Date = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date.distantFuture
        
        dailyStats = StatsUtils.getStats(from: today, to: endOfToday, dm: dm, profile: profile)

        let startOfWeek: Date = Calendar.current.startOfWeek(for: today)

        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? Date.distantPast

        // Load messages since the start of the week
        let weightLogsAscendingTimestamp: Results<MobileWeightLog> = dm.listWeightLogs(from: monthAgo, to: endOfToday)

        do {
            let endOfWeek: Date = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek) ?? Date.distantFuture
            let weeklyStats = try StatsUtils.getWeeklyStats(from: startOfWeek, to: endOfWeek, dm: dm, profile: profile)
            weeklyAverageDeficit = weeklyStats.averageDeficitPerDay
        } catch {
            WLogger.shared.record(error)
        }
        reloadWeightLogStats(weightLogsAscendingTimestamp: Array(weightLogsAscendingTimestamp), monthAgo: monthAgo)
    }

    private func reloadWeightLogStats(weightLogsAscendingTimestamp: [MobileWeightLog], monthAgo: Date) {
        let stats = StatsUtils.getWeightStatsPerDayFrom(weightLogsAscendingTimestamp: weightLogsAscendingTimestamp, preferredUnits: um.user.profile?.preferredUnits)

        yAxisMin = Int(stats.minWeight - 10)
        yAxisMax = Int(stats.maxWeight + 10)
        last30DaysWeight = stats.weightStats
    }
}
