//
//  FoodLogWeeklySummaryView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-28.
//

import SwiftUI
import Charts
import os

struct FoodLogWeeklySummaryView: View {
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @StateObject var viewModel: FoodLogWeeklySummaryViewModel = FoodLogWeeklySummaryViewModel()
    @Binding var currentWeekOf: Date
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            
            ///MARK :- WEL-879: Move weekly calorie consumed graph (sunday, monday, etc.) to the top
            ///Task :- DeficitPerDayView move on last to top
            ///Date :- 27 August, 2024
            ///By Piyush Poshiya

            DeficitPerDayView(weeklyStats: $viewModel.weeklyStats)
                .padding(.vertical, Theme.Spacing.xlarge)
                .background(Theme.Colors.SurfacePrimary100)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))

            ProgressOverviewCaloriesView(stats: $viewModel.stats, showTodaySubtitle: false, showNavArrow: false)
                .frame(maxWidth: .infinity)
                .card(small: true)
            
            MacroSummaryView(stats: $viewModel.stats, average: true)
                .card(small: true)
            
        }
        .onAppear {
            viewModel.set(currentWeekOf: currentWeekOf, dm: dm, um: um)
        }
        .onChange(of: currentWeekOf) {
            viewModel.set(currentWeekOf: currentWeekOf, dm: dm, um: um)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var currentWeekOf: Date = Calendar.current.startOfDay(for: Date.now)
        
        var body: some View {
            FoodLogWeeklySummaryView(currentWeekOf: $currentWeekOf)
                .environmentObject(DM())
                .environmentObject(UserManager.sample)
        }
    }
    return PreviewWrapper()
}


@MainActor
class FoodLogWeeklySummaryViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FoodLogWeeklySummaryViewModel.self))
    
    @Published var stats: LoggingStats = .empty
    @Published var weeklyStats: WeeklyCaloriesStats = .empty
    
    func set(currentWeekOf: Date, dm: DM, um: UserManager) {
        guard let profile = um.user.profile else {
            return
        }
        
        let startOfDay: Date = Calendar.current.startOfDay(for: currentWeekOf)
        let endOfDay: Date = Calendar.current.date(byAdding: .day, value: 7, to: startOfDay) ?? Date.distantFuture
        do {
            weeklyStats = try StatsUtils.getWeeklyStats(from: startOfDay, to: endOfDay, dm: dm, profile: profile)
            stats = LoggingStats(
                day: startOfDay,
                targetCalories: (weeklyStats.stats[0].targetCalories * 7), //weeklyStats.targetCalories,
                caloriesRemaining: weeklyStats.totalCaloriesRemaining,
                caloriesBurned: weeklyStats.totalCaloriesBurned,
                caloriesConsumed: weeklyStats.totalCaloriesConsumed,
                targetProtein: weeklyStats.targetProtein,
                proteinConsumed: weeklyStats.averageProteinConsumed,
                targetCarbs: weeklyStats.targetCarbs, 
                carbsConsumed: weeklyStats.averageCarbsConsumed,
                targetFat: weeklyStats.targetFat,
                fatConsumed: weeklyStats.averageFatConsumed,
                breakfastCaloriesConsumed: 0,
                lunchCaloriesConsumed: 0,
                dinnerCaloriesConsumed: 0,
                snacksCaloriesConsumed: 0,
                hasData: weeklyStats.hasData)
        } catch {
            WLogger.shared.record(error)
        }
    }
}
