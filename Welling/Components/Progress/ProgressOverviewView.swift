//
//  ProgressOverviewView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-11.
//

import SwiftUI
import Charts
import Mixpanel

/**
 Calories Sumamry
 - Calories daily summary
 - List of meals, and how many calories of consumed
 - Chart of calories eaten in the day, broken down by macros
 - Show calories eaten in breakfast, lunch, dinner, snacks in a card
 - Tap to open daily summary
 - Calories weekly summary
 
 Daily summary view - show all foods/actity logged
 */

struct ProgressOverviewView: View {
    @EnvironmentObject var realmDataManager: DM
    @EnvironmentObject var um: UserManager
    @StateObject var viewModel: ProgressOverviewViewModel = .init()
    @State var dailyFoodLogSummaryViewPresented: Bool = false
    @State var dailyFoodLogSummaryWekViewPresented: Bool = false
    @State var mealFoodsSheetPresented: Bool = false
    @State var mealFoodsToPresent: Meal = .breakfast

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.cardSpacing) {
                Button {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Progress Overview Calories", "screen":"ProgressOverviewView"])
                    dailyFoodLogSummaryViewPresented = true
                } label: {
                    ProgressOverviewCaloriesView(stats: $viewModel.dailyStats, showTodaySubtitle: true, showNavArrow: true)
                        .frame(maxWidth: .infinity)
                        .card(small: true)
                }
                
                HStack (spacing: Theme.Spacing.cardSpacing) {
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Breakfast", "screen":"ProgressOverviewView"])
                        mealFoodsToPresent = .breakfast
                        mealFoodsSheetPresented = true
                    } label: {
                        ProgressOverviewDoubleStatsCardView(
                            title: "Breakfast",
                            subtitle: "Today",
                            stat: $viewModel.dailyStats.breakfastCaloriesConsumed,
                            statUnit: "kcal")
                        .frame(maxWidth: .infinity)
                    }
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Lunch", "screen":"ProgressOverviewView"])
                        mealFoodsToPresent = .lunch
                        mealFoodsSheetPresented = true
                    } label: {
                        ProgressOverviewDoubleStatsCardView(
                            title: "Lunch",
                            subtitle: "Today",
                            stat: $viewModel.dailyStats.lunchCaloriesConsumed,
                            statUnit: "kcal")
                        .frame(maxWidth: .infinity)
                    }
                }
                
                HStack (spacing: Theme.Spacing.cardSpacing) {
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Dinner", "screen":"ProgressOverviewView"])
                        mealFoodsToPresent = .dinner
                        mealFoodsSheetPresented = true
                    } label: {
                        ProgressOverviewDoubleStatsCardView(
                            title: "Dinner",
                            subtitle: "Today",
                            stat: $viewModel.dailyStats.dinnerCaloriesConsumed,
                            statUnit: "kcal")
                        .frame(maxWidth: .infinity)
                    }
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Snacks", "screen":"ProgressOverviewView"])
                        mealFoodsToPresent = .snack
                        mealFoodsSheetPresented = true
                    } label: {
                        ProgressOverviewDoubleStatsCardView(
                            title: "Snacks",
                            subtitle: "Today",
                            stat: $viewModel.dailyStats.snacksCaloriesConsumed,
                            statUnit: "kcal")
                        .frame(maxWidth: .infinity)
                    }
                }
                
                HStack(spacing: Theme.Spacing.cardSpacing) {
                    VStack(spacing: Theme.Spacing.cardSpacing) {
                        Button {
                            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Weekly Deficit", "screen":"ProgressOverviewView"])
                            dailyFoodLogSummaryWekViewPresented = true
                            dailyFoodLogSummaryViewPresented = true
                        } label: {
                            WeeklyAverageDeficit(
                                averageDeficit: $viewModel.weeklyAverageDeficit)
                            .frame(maxWidth: .infinity)
                        }
                        NavigationLink {
                            ActivityLogSummaryView()
                                .withoutDefaultNavBar()
                        } label: {
                            ProgressOverviewActivityCardView(
                                stat: $viewModel.dailyStats.caloriesBurned)
                            .frame(maxWidth: .infinity)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Activity", "screen":"ProgressOverviewView"])
                        })
                        
                    }
                    
                    NavigationLink {
                        WeightProgressView()
                            .withoutDefaultNavBar()
                    } label: {
                        WeightProgressCardView(last30DaysWeight: $viewModel.last30DaysWeight, yAxisMin: $viewModel.yAxisMin, yAxisMax: $viewModel.yAxisMax)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Weight", "screen":"ProgressOverviewView"])
                    })
                }
            }
            .navigationDestination(isPresented: $dailyFoodLogSummaryViewPresented) {
                FoodLogSummaryView(weekView: dailyFoodLogSummaryWekViewPresented)
                    .withoutDefaultNavBar()
            }
            .padding(.horizontal, Theme.Spacing.cardSpacing)
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .environmentObject(viewModel)
        .foregroundStyle(Theme.Colors.TextPrimary100)
        .sheet(isPresented: $mealFoodsSheetPresented) {
            TodayMealFoodLogFoodsView(meal: $mealFoodsToPresent)
                .presentationDetents([.large])
        }
        .onAppear {
            viewModel.onAppear(realmDataManager: realmDataManager, um: um)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSCalendarDayChanged).receive(on: DispatchQueue.main)) { _ in
            viewModel.reloadStats()
       }
    }
}

struct ProgressOverviewDoubleStatsCardView: View {
    var title: String
    var subtitle: String
    
    @Binding var stat: Double
    var statUnit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment:  .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .fontWithLineHeight(Theme.Text.h5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral2)
                }
                Text(subtitle)
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            Text(String(lround(stat)))
                .fontWithLineHeight(Theme.Text.h3)
                .padding(.top, Theme.Spacing.medium)
            Text(statUnit)
                .fontWithLineHeight(Theme.Text.regularRegular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(small: true)
    }
}

struct ProgressOverviewActivityCardView: View {
    @Binding var stat: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Activity")
                        .fontWithLineHeight(Theme.Text.h5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral2)
                }
                Text("Today")
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            
            Text(String(lround(stat)))
                .fontWithLineHeight(Theme.Text.h3)
                .padding(.top, Theme.Spacing.medium)
            Text("kcal burned")
                .fontWithLineHeight(Theme.Text.regularRegular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(small: true)
    }
}

struct WeeklyAverageDeficit: View {
    @Binding var averageDeficit: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text("Average Deficit")
                        .fontWithLineHeight(Theme.Text.h5)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral2)
                }
                Text("This week")
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            
            Text(averageDeficit.formatted())
                .fontWithLineHeight(Theme.Text.h3)
                .padding(.top, Theme.Spacing.medium)
            Text("kcal")
                .fontWithLineHeight(Theme.Text.regularRegular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(small: true)
    }
}

struct WeightProgressCardView: View {
    @EnvironmentObject var um: UserManager
    let weightRange: [Int] = (0...30).filter{$0.isMultiple(of: 3) }
    @Binding var last30DaysWeight: [WeightStat]
    @Binding var yAxisMin: Int
    @Binding var yAxisMax: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Weight")
                        .fontWithLineHeight(Theme.Text.h5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral2)
                }
                Text("30 days")
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            
            if last30DaysWeight.isEmpty {
                Spacer()
                Text("Tell Welling your weight to log it")
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral2)
                    .frame(alignment: .center)
                    .multilineTextAlignment(.center)
                Spacer()
            } else if last30DaysWeight.count == 1 {
                Chart(last30DaysWeight) {
                    PointMark(
                        x: .value("Day", $0.day),
                        y: .value("Weight", $0.weight))
                }
                .chartXAxis {
                    AxisMarks(preset: .automatic, values: .init(weightRange)) {
                        AxisGridLine(stroke: .init(lineWidth: 4, lineCap: .round))
                            .foregroundStyle(.white)
                    }
                }.chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 0))
                }
                .chartYScale(domain: yAxisMin...yAxisMax)
                .foregroundStyle(Theme.Colors.TextSecondary100)
                .padding(.vertical, Theme.Spacing.large)
            } else {
                Chart(last30DaysWeight) {
                    LineMark(
                        x: .value("Day", $0.day),
                        y: .value("Weight", $0.weight))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(preset: .automatic, values: .init(weightRange)) {
                        AxisGridLine(stroke: .init(lineWidth: 4, lineCap: .round))
                            .foregroundStyle(.white)
                    }
                }.chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 0))
                }
                .chartYScale(domain: yAxisMin...yAxisMax)
                .foregroundStyle(Theme.Colors.TextSecondary100)
                .padding(.vertical, Theme.Spacing.large)
            }
            
            Text(UnitUtils.getWeightString(
                um.user.profile?.currentWeight ?? 0,
                um.user.profile?.preferredUnits))
            .fontWithLineHeight(Theme.Text.h3)
            
            Text((um.user.profile?.preferredUnits ?? MeasurementUnit.metric) == .imperial ? "lb" : "kg")
                .fontWithLineHeight(Theme.Text.regularRegular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity)
        .card(small: true)
    }
}

#Preview {
    ProgressOverviewView().environmentObject(DM()).environmentObject(UserManager.sample)
}


