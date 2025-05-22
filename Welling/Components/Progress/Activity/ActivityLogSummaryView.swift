//
//  ActivityLogSummaryView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-04.
//

import SwiftUI
import os

@MainActor
struct ActivityLogSummaryView: View {
    @EnvironmentObject var dm: DM
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    private static let topOfSummaryId = "top-view"
    
    @State var currentDay: Date = Calendar.current.startOfDay(for: Date.now)
    @State var weekView: Bool = false
    @State var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        VStack (spacing: 0) {
            ZStack {
                HStack {
                    IconButtonView("arrow-left-long", showBackgroundColor: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
                
                VStack (spacing: 0) {
                    Text("Activity")
                        .fontWithLineHeight(Theme.Text.h5)
                    Text(Date.monthYearFormatter.string(from: currentDay))
                        .fontWithLineHeight(Theme.Text.regularRegular)
                }
                
                HStack {
                    Spacer()
                    Toggle("", isOn: $weekView)
                        .toggleStyle(SmallToggleStyle(optionOne: "D", optionTwo: "W"))
                }
            }
            .navbar()
            
            VStack (spacing: Theme.Spacing.small) {
                if weekView {
                    WeekPickerScrollView(currentWeekOf: $currentDay)
                } else {
                    DayPickerScrollView(currentDay: $currentDay)
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        EmptyView()
                            .id(Self.topOfSummaryId)
                        VStack (spacing: Theme.Spacing.small) {
                            if weekView {
                                ActivityLogCaloriesBurnedChartView(weeklyStats: $viewModel.weeklyStats)
                                    .padding(.vertical, Theme.Spacing.xlarge)
                                    .background(Theme.Colors.SurfacePrimary100)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
                            }
                            
                            ActivityLogActivitiesView(activityLogs: $viewModel.activityLogs) {
                                viewModel.reloadStats(dm: dm, currentDay: currentDay, isWeek: weekView)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.horizontalPadding)
                        Spacer()
                    }
                    .onChange(of: weekView) {
                        proxy.scrollTo(Self.topOfSummaryId, anchor: .top)
                    }
                }
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            viewModel.reloadStats(dm: dm, currentDay: currentDay, isWeek: weekView)
        }
        .onChange(of: weekView) {
            viewModel.reloadStats(dm: dm, currentDay: currentDay, isWeek: weekView)
        }
        .onChange(of: currentDay) {
            viewModel.reloadStats(dm: dm, currentDay: currentDay, isWeek: weekView)
        }
    }
}

extension ActivityLogSummaryView {
    
    @Observable
    @MainActor
    class ViewModel {
        static let loggerCategory =  String(describing: ViewModel.self)
        private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: loggerCategory)
        
        var weeklyStats: ActivityLogStats = .empty
        var activityLogs: [MobilePhysicalActivityLog] = []
        
        func reloadStats(dm: DM, currentDay: Date, isWeek: Bool) {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
            
            let startOfDay: Date = Calendar.current.startOfDay(for: currentDay)
            let end: Date = (isWeek ? Calendar.current.date(byAdding: .day, value: 7, to: startOfDay) : Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date.distantFuture) ?? Date.distantFuture
            
            do {
                self.weeklyStats = try StatsUtils.getActivityLogStatsPerDay(dm: dm, from: startOfDay, to: end)
                activityLogs = []
                for stat in weeklyStats.activityStats {
                    for message in stat.activities {
                        if let activity = message.activityLog {
                            activityLogs.append(activity)
                        }
                    }
                }
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
}


fileprivate struct ActivityLogActivitiesView: View {
    @Binding var activityLogs: [MobilePhysicalActivityLog]
    @State var presentEditActivityLogSheet: Bool = false
    @State var activityLogToEdit: MobilePhysicalActivityLog = .redacted
    @State private var sheetHeight: CGFloat = .zero
    var onUpdated: () -> Void
    
    var body: some View {
        LazyVStack {
            if activityLogs.isEmpty {
                Text("No activity logged")
                    .fontWithLineHeight(Theme.Text.smallRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral05)
                    .padding(.top, Theme.Spacing.xxlarge)
            } else {
                ForEach(activityLogs, id: \.id) { activityLog in
                    Button {
                        self.presentEditActivityLogSheet = true
                        self.activityLogToEdit = activityLog
                    } label: {
                        VStack (spacing: 0) {
                            HStack (spacing: 0) {
                                Text("\(activityLog.name), \(activityLog.amount)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fontWithLineHeight(Theme.Text.largeRegular)
                                Spacer()
                                ColoredIconView(imageName: "nav-arrow-right")
                            }
                            
                            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxsmall) {
                                Text("\(lround(activityLog.caloriesExpended))")
                                    .fontWithLineHeight(Theme.Text.h1)
                                    .frame(alignment: .bottom)
                                    .frame(height: 67)
                                Text("kcal")
                                    .fontWithLineHeight(Theme.Text.regularSemiBold)
                                Spacer()
                                Text(Date.dateLoggedWithYearFormatter.string(from: activityLog.timestamp))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.xlarge)
                        .padding(.vertical, Theme.Spacing.large)
                        .background(Theme.Colors.SurfacePrimary100)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
                    }
                }
            }
        }
        .sheet(isPresented: $presentEditActivityLogSheet) {
            QuickEditActivityLogView(activityLog: $activityLogToEdit, isPresented: $presentEditActivityLogSheet, onUpdated: onUpdated)
                .sheet()
                .modifier(GetHeightModifier(height: $sheetHeight))
                .presentationDetents([.height(sheetHeight)])
        }
    }
    
}

#Preview {
    struct PreviewWrapper: View {
        @State var currentDay: Date = Calendar.current.startOfDay(for: Date.now)
        
        var body: some View {
            ActivityLogSummaryView()
                .environmentObject(DM())
                .environmentObject(UserManager.sample)
        }
    }
    return PreviewWrapper()
}
