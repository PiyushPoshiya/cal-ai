//
//  ProgressOverviewCaloriesView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-02.
//

import SwiftUI

struct ProgressOverviewCaloriesView: View {
    @EnvironmentObject var um: UserManager
    @EnvironmentObject var viewModel: ProgressOverviewViewModel
    
    @Binding var stats: LoggingStats
    
    @State var presentDailyTotalsSheet: Bool = false
    @State private var sheetHeight: CGFloat = .zero

    var showTodaySubtitle: Bool
    var showNavArrow: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Header
            HStack (spacing: 0) {
                // Title
                VStack(alignment: .leading, spacing: 0) {
                    HStack (spacing: 0) {
                        Text("Calories")
                            .fontWithLineHeight(Theme.Text.h5)
                        IconButtonView("info-circle", showBackgroundColor: false, foregroundColor: Theme.Colors.TextNeutral3) {
                            presentDailyTotalsSheet = true
                        }
                        Spacer()
                        if showNavArrow {
                            ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral2)
                        }
                    }
                    if showTodaySubtitle {
                        Text("Today")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                    }
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: 0) {
                    Image("apple")
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.bottom, Theme.Spacing.medium)
                        .padding(.top, Theme.Spacing.medium)
                    Text("+\(lround(stats.caloriesConsumed))")
                        .fontWithLineHeight(Theme.Text.regularSemiBold)
                    Text("eaten")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                }
                
                VStack(alignment: .center, spacing: 0) {
                    Image("fire-flame")
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.bottom, Theme.Spacing.medium)
                    Text("\(abs(stats.caloriesRemaining))")
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                        .fontWithLineHeight(Theme.Text.d1)
                    Text(stats.caloriesRemaining > 0 ? "remaining" : "over")
                        .fontWithLineHeight(Theme.Text.regularSemiBold)
                        .foregroundStyle(stats.caloriesRemaining > 0 ? Theme.Colors.TextNeutral9 : Theme.Colors.TextSecondary100)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .center, spacing: 0) {
                    Image("walking")
                        .padding(.horizontal, Theme.Spacing.medium)
                        .padding(.bottom, Theme.Spacing.medium)
                        .padding(.top, Theme.Spacing.medium)
                    Text("\(lround(stats.caloriesBurned))")
                        .fontWithLineHeight(Theme.Text.regularSemiBold)
                    Text("burned")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                }
            }
            .padding(.top, Theme.Spacing.small)
            
            WProgressBar(value: (stats.caloriesConsumed / Double(stats.targetCalories == 0 ? 1 : stats.targetCalories)))
//            WProgressBar(value: (stats.caloriesConsumed / Double(10500)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .tint(Theme.Colors.SurfaceSecondary100)
        }
        .sheet(isPresented: $presentDailyTotalsSheet) {
            VStack {
                DailyCalorieBudget(profile: self.um.user.profile ?? .sample)
                Spacer()
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
