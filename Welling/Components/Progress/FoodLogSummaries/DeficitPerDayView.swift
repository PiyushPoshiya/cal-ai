//
//  DeficitPerDayView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-30.
//

import SwiftUI
import Charts

struct DeficitPerDayView: View {
    @Binding var weeklyStats: WeeklyCaloriesStats
    
    @State var presentDeficitPerDayInfo: Bool = false
    @State private var sheetHeight: CGFloat = .zero
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xxlarge) {
            HStack {
                VStack (spacing: 0) {
                    HStack(spacing: 0) {
                        Text("\(weeklyStats.averageDeficitPerDay)")
                            .fontWithLineHeight(Theme.Text.d2)
                        
                        IconButtonView("info-circle", showBackgroundColor: false, foregroundColor: Theme.Colors.TextNeutral3) {
                            presentDeficitPerDayInfo = true
                        }
                        Spacer()
                    }
                    HStack {
                        Text("avg. kcal deficit per day")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                        Spacer()
                    }
                }
            }
            .frame(alignment: .leading)
            .padding(.horizontal, Theme.Spacing.xsmall)
            
            Chart {
                ForEach(weeklyStats.stats, id: \.day) {
                    if $0.caloriesRemaining < 0 {
                        BarMark(
                            x: .value("Day", $0.day, unit: .weekday),
                            y: .value("Consumed", Int($0.caloriesConsumed))
                        )
                        .foregroundStyle(Theme.Colors.SurfaceSecondary100)
                        .cornerRadius(Theme.Spacing.xxxlarge)
                    } else {
                        BarMark(
                            x: .value("Day", $0.day, unit: .weekday),
                            y: .value("Consumed", $0.caloriesConsumed)
                        )
                        .foregroundStyle(Theme.Colors.SurfaceSecondary100)
                        
                        BarMark(
                            x: .value("Day", $0.day, unit: .weekday),
                            y: .value("Remaining", $0.caloriesRemaining)
                        )
                        .foregroundStyle(Theme.Colors.SurfaceNeutral9.opacity(0.06))
                        .cornerRadius(Theme.Spacing.xxxlarge)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) {
                    AxisValueLabel(format: Date.weekday, centered: true)
                        .font(.custom("DMSans-Medium", size: 10))
                        .foregroundStyle(Theme.Colors.TextNeutral8)
                        .offset(CGSize(width: 0, height: 4))
                }
            }
            .chartYScale(domain: [0, weeklyStats.stats.map({max(Int($0.caloriesConsumed), $0.targetCalories)}).max(by: {a, b in a < b})!])
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                        AxisValueLabel()
                            .font(.custom("DMSans-Medium", size: 10))
                            .foregroundStyle(Theme.Colors.TextNeutral8)
                }
            }
            .frame(height: 130)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .sheet(isPresented: $presentDeficitPerDayInfo) {
            VStack {
                VStack(spacing: 0) {
                    HStack {
                        IconButtonView("info-circle", foregroundColor: Theme.Colors.Neutral7) {
                        }
                        Spacer()
                        Text("Average Deficit")
                            .fontWithLineHeight(Theme.Text.h5)
                        Spacer()
                        IconButtonView("info-circle", foregroundColor: Theme.Colors.Neutral7) {
                        }
                        .hidden()
                    }
                    .sheetNavbar()
                    
                    VStack(spacing: Theme.Spacing.large) {
                        Text("Average daily deficit is calculated by only looking at the days on which you logged food or activity.")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.75))
                            .lineLimit(4, reservesSpace: true)
                    }
                    .padding(.horizontal, Theme.Spacing.small + Theme.Spacing.medium)
                    .padding(.top, Theme.Spacing.xxxlarge)
                    .padding(.bottom, Theme.Spacing.xxlarge)
                    .background(Theme.Colors.SurfaceNeutral2)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
                }
                .foregroundStyle(Theme.Colors.TextPrimary100)
                .background(Theme.Colors.SurfaceNeutral05)
            }
            .padding(.top, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.large)
            .padding(.horizontal, Theme.Spacing.small)
            .background(Theme.Colors.SurfaceNeutral05)
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
    }
}

#Preview {
    DeficitPerDayView(weeklyStats: .constant(.sample))
}
