//
//  DayPickerScrollView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-28.
//

import SwiftUI
import Foundation

struct DayPickerScrollView: View {
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @Binding var currentDay: Date
    
    @StateObject fileprivate var viewModel: DayPickerScrollViewModel = DayPickerScrollViewModel()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView (.horizontal, showsIndicators: false) {
                LazyHStack (spacing: Theme.Spacing.xsmall) {
                    ForEach(viewModel.days, id: \.day) { day in
                        VStack (spacing: 0) {
                            Text(day.weekday)
                                .fontWithLineHeight(Theme.Text.tinyMedium)
                            Text(day.dayOfMonth)
                                .fontWithLineHeight(Theme.Text.h5)
                                .frame(width: 32)
                        }
                        .padding(.horizontal, Theme.Spacing.xsmall)
                        .padding(.vertical, Theme.Spacing.small)
                        .background(day.day == currentDay ? Theme.Colors.SurfacePrimary120 : .clear)
                        .foregroundStyle(Calendar.current.isDateInToday(day.day) ? Theme.Colors.SurfaceSecondary100 : Theme.Colors.TextNeutral9)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                currentDay = day.day
                                proxy.scrollTo(currentDay, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(height: 68)
            .onAppear {
                viewModel.onAppear(dm: dm, um: um)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                    proxy.scrollTo(currentDay, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var currentDay: Date = Calendar.current.startOfDay(for: Date.now)
        
        var body: some View {
            DayPickerScrollView(currentDay: $currentDay)
                .environmentObject(DM())
                .environmentObject(UserManager.sample)
        }
    }
    return PreviewWrapper()
}

@MainActor
fileprivate class DayPickerScrollViewModel: ObservableObject {
    static let formatter: DateFormatter = DateFormatter()
    
    @Published fileprivate var days: [DayPickerDay] = []
    
    func onAppear(dm: DM, um: UserManager) {
        
        if days.count > 0 {
            return
        }
        
        let first: Date = Calendar.current.date(byAdding: .day, value: -5, to: Calendar.current.startOfDay(for: um.user.dateCreated))!
        let last: Date = Calendar.current.date(byAdding: .day, value: 5, to: Calendar.current.startOfDay(for: dm.getLastMessageDate()))!
        
        var currentDay: Date = first
        while currentDay <= last {
            let components = Calendar.current.dateComponents([.weekday, .day], from: currentDay)
            
            days.append(DayPickerDay(
                day: currentDay,
                weekday: Self.formatter.weekdaySymbols[components.weekday! - 1].description.first?.description ?? "?",
                dayOfMonth: components.day!.description))
            
            currentDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDay)!
        }
    }
}

fileprivate struct DayPickerDay {
    let day: Date
    let weekday: String
    let dayOfMonth: String
}
