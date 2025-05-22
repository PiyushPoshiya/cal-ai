//
//  FoodLogDailySummaryView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-28.
//

import SwiftUI
import RealmSwift

struct FoodLogDailySummaryView: View {
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @StateObject var viewModel: FoodLogDailySummaryViewModel = FoodLogDailySummaryViewModel()
    @Binding var currentDay: Date
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            ProgressOverviewCaloriesView(stats: $viewModel.stats, showTodaySubtitle: false, showNavArrow: false)
                .frame(maxWidth: .infinity)
                .card(small: true)
            
            MacroSummaryView(stats: $viewModel.stats)
                .card(small: true)
            
            MealCaloriesView(currentDay: $currentDay, meal: .breakfast, calories: $viewModel.stats.breakfastCaloriesConsumed, summary: $viewModel.breakfastSummary, foodLogEntries: $viewModel.breakfastFoodLogs, messages: viewModel.stats.messages)
            
            MealCaloriesView(currentDay: $currentDay, meal: .lunch, calories: $viewModel.stats.lunchCaloriesConsumed, summary: $viewModel.lunchSummary, foodLogEntries: $viewModel.lunchFoodLogs, messages: viewModel.stats.messages)
            
            MealCaloriesView(currentDay: $currentDay, meal: .dinner, calories: $viewModel.stats.dinnerCaloriesConsumed, summary: $viewModel.dinnerSummary, foodLogEntries: $viewModel.dinnerFoodLogs, messages: viewModel.stats.messages)
            
            MealCaloriesView(currentDay: $currentDay, meal: .snack, calories: $viewModel.stats.snacksCaloriesConsumed, summary: $viewModel.snacksSummry, foodLogEntries: $viewModel.snackFoodLogs, messages: viewModel.stats.messages)
        }
        .onAppear {
            viewModel.onAppear(dm: dm, um: um)
            viewModel.set(day: currentDay)
        }
        .onChange(of: currentDay) {
            viewModel.set(day: currentDay)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var currentDay: Date = Calendar.current.startOfDay(for: Date.now)
        
        var body: some View {
            FoodLogDailySummaryView(currentDay: $currentDay)
                .environmentObject(DM())
                .environmentObject(UserManager.sample)
        }
    }
    return PreviewWrapper()
}

@MainActor
class FoodLogDailySummaryViewModel: ObservableObject {
    var um: UserManager?
    var dm: DM?
    @Published var stats: LoggingStats = .empty
    
    @Published var breakfastSummary: String = ""
    @Published var lunchSummary: String = ""
    @Published var dinnerSummary: String = ""
    @Published var snacksSummry: String = ""
    
    @Published var breakfastFoodLogs: [MobileFoodLogEntry] = []
    @Published var lunchFoodLogs: [MobileFoodLogEntry] = []
    @Published var dinnerFoodLogs: [MobileFoodLogEntry] = []
    @Published var snackFoodLogs: [MobileFoodLogEntry] = []
    
    var startOfDay: Date = .distantPast
    var endOfToday: Date = .distantPast

    var messagesNotificationToken: NotificationToken?
    
    func onAppear(dm: DM, um: UserManager) {
        self.dm = dm
        self.um = um
    }
    
    func set(day: Date) {
        guard let dm = dm else {
            return
        }
        
        startOfDay = Calendar.current.startOfDay(for: day)
        endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date.distantFuture
        
        messagesNotificationToken?.invalidate()
        messagesNotificationToken = dm
            .realm
            .objects(MobileMessage.self)
            .where {
                $0.foodLog != nil && $0.foodLog.timestamp.contains(startOfDay ..< endOfToday)
            }
            .observe(self.onMessagesChanged)
        
//        reloadStats()
    }
    
    deinit {
        messagesNotificationToken?.invalidate()
    }
    
    @MainActor
    func onMessagesChanged(change: RealmCollectionChange<Results<MobileMessage>>) -> Void {
        reloadStats()
    }
    
    @MainActor
    func reloadStats() {
        guard let dm = dm, let um = um, let profile = um.user.profile else {
            return
        }
        
        stats = StatsUtils.getStats(from: startOfDay, to: endOfToday, dm: dm, profile: profile)
        
        updateMealSummaries(stats: stats)
    }
    
    func updateMealSummaries(stats: LoggingStats) {
        var breakfastFoods: [FoodLogFood] = []
        var lunchFoods: [FoodLogFood] = []
        var dinnerFoods: [FoodLogFood] = []
        var snackFoods: [FoodLogFood] = []

        breakfastFoodLogs = stats.breakfastFoods
        for foodLogEntry in stats.breakfastFoods {
            breakfastFoods.append(contentsOf: foodLogEntry.foods)
        }
        
        lunchFoodLogs = stats.lunchFoods
        for foodLogEntry in stats.lunchFoods {
            lunchFoods.append(contentsOf: foodLogEntry.foods)
        }
        
        dinnerFoodLogs = stats.dinnerFoods
        for foodLogEntry in stats.dinnerFoods {
            dinnerFoods.append(contentsOf: foodLogEntry.foods)
        }
        
        snackFoodLogs = stats.snackFoods
        for foodLogEntry in stats.snackFoods {
            snackFoods.append(contentsOf: foodLogEntry.foods)
        }
        
        if breakfastFoods.isEmpty {
            breakfastSummary = "You did not log breakfast."
        } else {
            breakfastSummary = breakfastFoods.shortSummaryDisplayString()
        }
        
        if lunchFoods.isEmpty {
            lunchSummary = "You did not log lunch."
        } else {
            lunchSummary = lunchFoods.shortSummaryDisplayString()
        }
        
        if dinnerFoods.isEmpty {
            dinnerSummary = "You did not log dinner."
        } else {
            dinnerSummary = dinnerFoods.shortSummaryDisplayString()
        }
        
        if snackFoods.isEmpty {
            snacksSummry = "You did not log any snacks."
        } else {
            snacksSummry = snackFoods.shortSummaryDisplayString()
        }
    }
}
