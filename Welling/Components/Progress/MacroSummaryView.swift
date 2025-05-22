//
//  MacroSummaryView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-29.
//

import SwiftUI

struct MacroSummaryView: View {
    @Binding var stats: LoggingStats
    
    @State var presentInfoSheet: Bool = false
    @State private var sheetHeight: CGFloat = .zero
    
    var average: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xlarge) {
            HStack (spacing: 0) {
                Text("Macros")
                    .fontWithLineHeight(Theme.Text.h4)
                if average {
                    IconButtonView("info-circle", showBackgroundColor: false, foregroundColor: Theme.Colors.TextNeutral3) {
                        presentInfoSheet = true
                    }
                }
                Spacer()
            }
            MacroSummaryStatView(macro: "Protein", target: stats.targetProtein, consumed: stats.proteinConsumed, average: average)
            MacroSummaryStatView(macro: "Carbs", target: stats.targetCarbs, consumed: stats.carbsConsumed, average: average)
            MacroSummaryStatView(macro: "Fat", target: stats.targetFat, consumed: stats.fatConsumed, average: average)
        }
        .sheet(isPresented: $presentInfoSheet) {
            VStack {
                VStack(spacing: 0) {
                    HStack {
                        ColoredIconView(imageName: "info-circle", foregroundColor: Theme.Colors.Neutral7)
                        Spacer()
                        Text("Average Macros")
                            .fontWithLineHeight(Theme.Text.h5)
                        Spacer()
                        IconButtonView("info-circle", foregroundColor: Theme.Colors.Neutral7) {
                        }
                        .hidden()
                    }
                    .sheetNavbar()
                    
                    VStack(spacing: Theme.Spacing.large) {
                        Text("Average macros are calculated by only looking at the days on which you logged food or activity.")
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

struct MacroSummaryStatView: View {
    var macro: String
    var target: Int
    var consumed: Double
    var average: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack {
                Text("\(macro) (\(lround(consumed / Double(target == 0 ? 1 : target) * 100.0))%)")
                    .fontWithLineHeight(Theme.Text.regularRegular)
               Spacer()
                if average {
                    Text("\(lround(consumed))g avg. per day")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                } else {
                    Text("\(lround(consumed))/\(target)g")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                }
            }
            
            WProgressBar(value: (consumed / Double(target == 0 ? 1 : target)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .tint(Theme.Colors.SurfaceSecondary100)
        }
    }
}

#Preview {
    MacroSummaryView(stats: .constant(.sample))
}
