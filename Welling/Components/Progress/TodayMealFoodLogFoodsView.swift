//
//  TodayMealFoodLogFoodsView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-04.
//

import SwiftUI
import RealmSwift

struct TodayMealFoodLogFoodsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @State var viewModel: ViewModel = ViewModel()
    
    @Binding var meal: Meal
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: Theme.Spacing.xsmall) {
                IconButtonView("xmark", showBackgroundColor: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Text(meal.displayString())
                    .fontWithLineHeight(Theme.Text.h5)
                    .foregroundStyle(Theme.Colors.TextPrimary100)
                Spacer()
                IconButtonView("xmark", showBackgroundColor: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                .hidden()
            }
            .sheetNavbar()
            
            ScrollView {
                if viewModel.anyFoods {
                    EditFoodLogFoodsView(foodLogEntries: $viewModel.foodLogEntries, messages: viewModel.messages)
                } else {
                    Spacer()
                    
                    Text("No \(meal.rawValue) logged")
                        .fontWithLineHeight(Theme.Text.smallRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral05)
                        .padding(.top, Theme.Spacing.xxlarge)
                }
            }
            Spacer()
        }
        .padding(.top, Theme.Spacing.medium)
        .padding(.horizontal, Theme.Spacing.horizontalPadding)
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            viewModel.onAppear(dm: self.dm, um: self.um, meal: meal)
        }
    }
}

extension TodayMealFoodLogFoodsView {
    @Observable
    @MainActor
    class ViewModel {
        @ObservationIgnored var messagesNotificationToken: NotificationToken?
        @ObservationIgnored var meal: Meal = .snack
        
        var um: UserManager? = nil
        var foodLogEntries: [MobileFoodLogEntry] = []
        var messages: [String:MobileMessage] = [:]
        var anyFoods: Bool = true
        
        func onAppear(dm: DM, um: UserManager, meal: Meal) {
            self.meal = meal
            self.um = um
            
            let startOfDay = Calendar.current.startOfDay(for: .now)
            let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date.distantFuture
            
            messagesNotificationToken?.invalidate()
            messagesNotificationToken = dm
                .realm
                .objects(MobileMessage.self)
                .where {
                    $0.foodLog != nil && $0.foodLog.timestamp.contains(startOfDay ..< endOfToday)
                }
                .observe(self.onMessagesChanged)
        }
        
        @MainActor
        func onMessagesChanged(change: RealmCollectionChange<Results<MobileMessage>>) -> Void {
            reloadStats()
        }
        
        @MainActor
        func reloadStats() {
            guard let um = self.um else {
                return
            }
            
            let stats: LoggingStats = StatsUtils.getTodaysStats(dm: DM.shared, profile: um.user.profile ?? .empty)
            messages = stats.messages
            
            switch meal {
            case .breakfast:
                foodLogEntries = stats.breakfastFoods
            case .lunch:
                foodLogEntries = stats.lunchFoods
            case .dinner:
                foodLogEntries = stats.dinnerFoods
            case .snack:
                foodLogEntries = stats.snackFoods
            }
            
            anyFoods = foodLogEntries.anyFoods()
        }
        
        deinit {
            messagesNotificationToken?.invalidate()
        }
        
    }
}
