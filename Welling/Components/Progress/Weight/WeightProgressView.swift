//
//  WeightProgressView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI
import RealmSwift
import Charts

fileprivate enum WeightProgressTab {
    case sevenDays
    case thirtyDays
    case ninetyDays
    case all
}

struct WeightProgressView: View {
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    
    @State fileprivate var viewModel: ViewModel = ViewModel()
    @State fileprivate var currentTab: WeightProgressTab = .thirtyDays
    
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
                    Text("Weight")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                
                HStack {
                    Spacer()
                    IconButtonView("plus", showBackgroundColor: true) {
                        conversationScreenViewModel.logWeight()
                    }
                }
            }
            .navbar()
            
            WeightProgressTabView(currentTab: $currentTab)
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            
            Spacer()
                .frame(height: Theme.Spacing.small)
            
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.small) {
                    HStack(spacing: Theme.Spacing.small) {
                        VStack (spacing: Theme.Spacing.xlarge) {
                            HStack {
                              Text("Change")
                                    .fontWithLineHeight(Theme.Text.largeRegular)
                                Spacer()
                                ColoredIconView(imageName: "percentage", foregroundColor: Theme.Colors.TextNeutral9)
                            }
                            HStack {
                                Spacer()
                                Text("\(viewModel.changePercent >= 0 ? "+" : "")\(viewModel.changePercent)%")
                                    .fontWithLineHeight(Theme.Text.h1)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        .card(small: true)
                        
                        VStack (spacing: Theme.Spacing.xlarge) {
                            HStack {
                              Text("Total")
                                    .fontWithLineHeight(Theme.Text.largeRegular)
                                Spacer()
                                ColoredIconView(imageName: "stat-down", foregroundColor: Theme.Colors.TextNeutral9)
                            }
                            HStack {
                                Spacer()
                                Text("\(viewModel.changeTotal >= 0 ? "+" : "")" + UnitUtils.getWeightString(viewModel.changeTotal, um.user.profile?.preferredUnits) + UnitUtils.weightUnitString(um.user.profile?.preferredUnits))
                                    .fontWithLineHeight(Theme.Text.h1)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        .card(small: true)
                    }
                    
                    WeightProgressWeightChartView(weightStats: $viewModel.weightStats, currentWeight: $viewModel.currentWeight, yAxisMin: $viewModel.yAxisMin, yAxisMax: $viewModel.yAxisMax, preferredUnit: um.user.profile?.preferredUnits ?? .metric)
                        .card(small: true)
                    
                    WeightProgressWeightLogsView(weightLogs: $viewModel.weightLogs) {
                        viewModel.reloadStats(dm: dm, um: um, tab: currentTab)
                    }
                }
                .padding(.horizontal, Theme.Spacing.small)
            }
        }
        .onAppear {
            viewModel.reloadStats(dm: dm, um: um, tab: currentTab)
        }
        .onChange(of: currentTab) {
            viewModel.reloadStats(dm: dm, um: um, tab: currentTab)
        }
    }
}

struct WeightProgressWeightLogsView: View {
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @Binding var weightLogs: [MobileWeightLog]
    @State var isDeleting: Bool = false
    @State var presentConfirmDeleteSheet: Bool = false
    @State private var sheetHeight: CGFloat = .zero
    @State var weightLogToDelete: MobileWeightLog? = nil
    var onWeightLogDeleted: () -> Void
    
    var body: some View {
        LazyVStack (spacing: 0) {
            HStack {
                Spacer()
                if isDeleting {
                    TextButtonView("Cancel") {
                        withAnimation {
                            isDeleting = false
                        }
                    }
                    .frame(height: 40)
                } else {
                    IconButtonView("edit", showBackgroundColor: false, foregroundColor: Theme.Colors.Neutral7) {
                        withAnimation {
                            isDeleting = true
                        }
                    }
                    .frame(height: 40)
                }
            }

            ForEach($weightLogs, id: \.self) { $weightLog in
                VStack (spacing: 0) {
                    HStack(alignment: .center) {
                        Text(UnitUtils.getWeightStringWithUnit(weightLog.weightInKg, um.user.profile?.preferredUnits))
                            .fontWithLineHeight(Theme.Text.mediumSemiBold)
                            .frame(height: 40)
                        Spacer()
                        Text(Date.dateLoggedWithYearFormatter.string(from: weightLog.timestamp))
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral8.opacity(0.75))
                            .frame(height: 40)
                        if isDeleting {
                            IconButtonView("trash", showBackgroundColor: false, foregroundColor: Theme.Colors.Neutral7) {
                                delete(weightLog: weightLog)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.medium)

                    if weightLog != weightLogs.last {
                        Divider()
                            .frame(height: 1)
                            .overlay(Theme.Colors.BorderNeutral05)
                    }
                }
                .padding(.horizontal, Theme.Spacing.medium)
            }
        }
        .padding(.horizontal, Theme.Spacing.small)
        .padding(.vertical, Theme.Spacing.large)
        .background(Theme.Colors.SurfacePrimary100)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        .sheet(isPresented: $presentConfirmDeleteSheet) {
            ConfirmDeleteSheetView(isPresented: $presentConfirmDeleteSheet) {
                handleDeleteConfiremed()
            }
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
    }
    
    @MainActor
    func delete(weightLog: MobileWeightLog) {
        weightLogToDelete = weightLog
        presentConfirmDeleteSheet = true
    }
    
    func handleDeleteConfiremed() {
        Task { @MainActor in
            guard let weightLogToDelete = weightLogToDelete else {
               return
            }
           
            do {
                try await dm.delete(weightLog: weightLogToDelete)
                presentConfirmDeleteSheet = false
                self.weightLogToDelete = nil
                onWeightLogDeleted()
            } catch {
                WLogger.shared.record(error)
            }
        }
    }
}

struct WeightProgressWeightChartView: View {
    @EnvironmentObject var um: UserManager
    
    @Binding var weightStats: [WeightStat]
    @Binding var currentWeight: Double
    @Binding var yAxisMin: Int
    @Binding var yAxisMax: Int
    var preferredUnit: MeasurementUnit
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(UnitUtils.getWeightString(currentWeight, preferredUnit) + UnitUtils.weightUnitString(preferredUnit))
                        .fontWithLineHeight(Theme.Text.h1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.5)
                    Text("Current")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                }
                Spacer()
                
                ColoredIconView(imageName: "graph-down", foregroundColor: Theme.Colors.TextNeutral9)
            }
            
            if weightStats.isEmpty {
                Spacer()
                Text("Tell Welling your weight to log it")
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral2)
                    .frame(alignment: .center)
                    .multilineTextAlignment(.center)
                Spacer()
            } else if weightStats.count == 1 {
                Chart(weightStats) {
                    PointMark(
                        x: .value("Day", $0.timestamp),
                        y: .value("Weight", $0.weight))
                }
                .chartXAxis {
                    AxisMarks (preset: .aligned) {
                        AxisValueLabel()
                            .font(.custom("DMSans-Medium", size: 10))
                            .foregroundStyle(Theme.Colors.TextNeutral8)
                        
                        AxisGridLine(stroke: .init(lineWidth: 2.0))
                            .foregroundStyle(Theme.Colors.BorderNeutral95.opacity(0.2))
                    }
                }.chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) {
                        AxisValueLabel()
                            .font(.custom("DMSans-Medium", size: 10))
                            .foregroundStyle(Theme.Colors.TextNeutral8)
                        
                        AxisGridLine(stroke: .init(lineWidth: 2.0))
                            .foregroundStyle(Theme.Colors.BorderNeutral95.opacity(0.2))
                    }
                }
                .chartYScale(domain: yAxisMin...yAxisMax)
                .foregroundStyle(Theme.Colors.TextSecondary100)
                .padding(.vertical, Theme.Spacing.large)
            } else {
                Chart(weightStats) {
                    LineMark(
                        x: .value("Day", $0.timestamp),
                        y: .value("Weight", $0.weight))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks (preset: .aligned) {
                        AxisValueLabel()
                            .font(.custom("DMSans-Medium", size: 10))
                            .foregroundStyle(Theme.Colors.TextNeutral8)
                        
                        AxisGridLine(stroke: .init(lineWidth: 2.0))
                            .foregroundStyle(Theme.Colors.BorderNeutral95.opacity(0.1))
                    }
                }.chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) {
                        AxisValueLabel()
                            .font(.custom("DMSans-Medium", size: 10))
                            .foregroundStyle(Theme.Colors.TextNeutral8)
                        
                        AxisGridLine(stroke: .init(lineWidth: 2.0))
                            .foregroundStyle(Theme.Colors.BorderNeutral95.opacity(0.1))
                    }
                }
                .chartYScale(domain: yAxisMin...yAxisMax)
                .foregroundStyle(Theme.Colors.TextSecondary100)
                .padding(.vertical, Theme.Spacing.large)
            }
        }
    }
}


@Observable
@MainActor
fileprivate class ViewModel: ObservableObject {
    fileprivate var changePercent: Int = 0
    fileprivate var changeTotal: Double = 0.0
    
    fileprivate var weightLogs: [MobileWeightLog] = []
    fileprivate var weightStats: [WeightStat] = []
    fileprivate var yAxisMin: Int = 0
    fileprivate var yAxisMax: Int = 0
    fileprivate var currentWeight: Double = 0.0
    
    fileprivate func reloadStats(dm: DM, um: UserManager, tab: WeightProgressTab) {
        let messagesResult: Results<MobileWeightLog>
        
        let to: Date = Date.now
        let startOfTo: Date = Calendar.current.startOfDay(for: to)
        
        switch tab {
        case .sevenDays:
            messagesResult = dm.listWeightLogs(from: Calendar.current.date(byAdding: .day, value: -7, to: startOfTo) ?? Date.distantPast, to: to)
        case .thirtyDays:
            messagesResult = dm.listWeightLogs(from: Calendar.current.date(byAdding: .day, value: -30, to: startOfTo) ?? Date.distantPast, to: to)
        case .ninetyDays:
            messagesResult = dm.listWeightLogs(from: Calendar.current.date(byAdding: .day, value: -90, to: startOfTo) ?? Date.distantPast, to: to)
        case .all:
            messagesResult = dm.listWeightLogs(from: Date.distantPast, to: to)
        }
        
        self.weightLogs = Array(messagesResult)
        
        let stats = StatsUtils.getWeightStatsPerDayFrom(weightLogsAscendingTimestamp: weightLogs, preferredUnits: um.user.profile?.preferredUnits)
        self.weightStats = stats.weightStats
        
        yAxisMin = Int(stats.minWeight - 5)
        yAxisMax = Int(stats.maxWeight + 5)
        currentWeight = um.user.profile?.currentWeight ?? 0.0
        
        if let firstWeight = stats.weightStats.first {
            changeTotal = UnitUtils.weightValue(um.user.profile?.currentWeight ?? 0.0, um.user.profile?.preferredUnits) - firstWeight.weight
            changePercent = lround(changeTotal / firstWeight.weight * 100)
        }
        
        self.weightLogs.sort {
            $1.timestamp < $0.timestamp
        }
    }
}
struct WeightProgressTabView: View {
    @Binding fileprivate var currentTab: WeightProgressTab
    
    var body: some View {
        ZStack(alignment: .center) {
            GeometryReader { geometry in
                HStack {
                    Text("7 Days")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxsmall)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                        .background(currentTab == .sevenDays ? RoundedRectangle(cornerRadius: Theme.Radius.full).foregroundStyle(Theme.Colors.SurfacePrimary120) : nil)
                        .onTapGesture {
                            withAnimation( .easeInOut(duration: 0.15), {
                                currentTab = .sevenDays
                            })
                        }
                    Text("30 Days")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxsmall)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                        .background(currentTab == .thirtyDays ? RoundedRectangle(cornerRadius: Theme.Radius.full).foregroundStyle(Theme.Colors.SurfacePrimary120) : nil)
                        .onTapGesture {
                            withAnimation( .easeInOut(duration: 0.15), {
                                currentTab = .thirtyDays
                            })
                        }
                    Text("90 Days")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxsmall)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                        .background(currentTab == .ninetyDays ? RoundedRectangle(cornerRadius: Theme.Radius.full).foregroundStyle(Theme.Colors.SurfacePrimary120) : nil)
                        .onTapGesture {
                            withAnimation( .easeInOut(duration: 0.15), {
                                currentTab = .ninetyDays
                            })
                        }
                    Text("All")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxsmall)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                        .background(currentTab == .all ? RoundedRectangle(cornerRadius: Theme.Radius.full).foregroundStyle(Theme.Colors.SurfacePrimary120) : nil)
                        .onTapGesture {
                            withAnimation( .easeInOut(duration: 0.15), {
                                currentTab = .all
                            })
                        }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: Theme.Spacing.xlarge)
                .padding(.vertical, Theme.Spacing.xsmall)
            }
        }
        .padding(.horizontal, Theme.Spacing.xsmall)
        .frame(height: Theme.Spacing.xxxlarge)
        .background(Theme.Colors.SurfaceNeutral2)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
    }
}

#Preview {
    WeightProgressView()
}
