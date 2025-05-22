//
//  FoodLogSimmaryView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-28.
//

import SwiftUI


struct FoodLogSummaryView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    private static let topOfSummaryId = "top-view"
    
    @State var currentDay: Date = Calendar.current.startOfDay(for: Date.now)
    @State var weekView: Bool = false
    
    var body: some View {
        VStack(spacing: 0){
            ZStack {
                HStack {
                    IconButtonView("arrow-left-long", showBackgroundColor: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
                
                VStack (spacing: 0) {
                    Text("Calories")
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
                        if weekView {
                            FoodLogWeeklySummaryView(currentWeekOf: $currentDay)
                                .padding(.horizontal, Theme.Spacing.horizontalPadding)
                        } else {
                            FoodLogDailySummaryView(currentDay: $currentDay)
                                .padding(.horizontal, Theme.Spacing.horizontalPadding)
                        }
                        Spacer()
                    }
                    .onChange(of: weekView) {
                        proxy.scrollTo(Self.topOfSummaryId, anchor: .top)
                    }
                }
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var currentDay: Date = Calendar.current.startOfDay(for: Date.now)
        
        var body: some View {
            FoodLogSummaryView()
                .foregroundStyle(Theme.Colors.TextNeutral9)
                .environmentObject(DM())
                .environmentObject(UserManager.sample)
        }
    }
    return PreviewWrapper()
}
