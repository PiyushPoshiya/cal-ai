//
//  WeekPickerScrollView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-28.
//

import SwiftUI

struct WeekPickerScrollView: View {
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @Binding var currentWeekOf: Date
    
    @StateObject fileprivate var viewModel: DayPickerScrollViewModel = DayPickerScrollViewModel()
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView (.horizontal, showsIndicators: false) {
                LazyHStack (spacing: Theme.Spacing.xsmall) {
                    ForEach(viewModel.weeks, id: \.weekOf) { day in
                        VStack (spacing: 0) {
                            Text(day.display)
                                .fontWithLineHeight(Theme.Text.regularMedium)
                                .foregroundStyle(day.isThisWeek ? Theme.Colors.SurfaceSecondary100 : Theme.Colors.TextNeutral9)
                        }
                        .padding(Theme.Spacing.small)
                        .background(day.weekOf == currentWeekOf ? Theme.Colors.SurfacePrimary120 : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                currentWeekOf = day.weekOf
                                proxy.scrollTo(currentWeekOf, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(height: 45)
            .onAppear {
                viewModel.onAppear(dm: dm, um: um)
                currentWeekOf = Calendar.current.startOfWeek(for: currentWeekOf)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                    proxy.scrollTo(currentWeekOf, anchor: .center)
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var currentWeekOf: Date = Calendar.current.startOfDay(for: Date.now)
        
        var body: some View {
            WeekPickerScrollView(currentWeekOf: $currentWeekOf)
                .environmentObject(DM())
                .environmentObject(UserManager.sample)
        }
    }
    return PreviewWrapper()
}

@MainActor
fileprivate class DayPickerScrollViewModel: ObservableObject {
    static let formatter: DateFormatter = DateFormatter()
    
    @Published fileprivate var weeks: [WeekPickerWeek] = []
    
    func onAppear(dm: DM, um: UserManager) {
        if weeks.count > 0 {
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date.now)
        
        let first: Date = Calendar.current.date(byAdding: .day, value: -14, to: Calendar.current.startOfWeek(for: um.user.dateCreated))!
        let last: Date = Calendar.current.date(byAdding: .day, value: 14, to: Calendar.current.startOfWeek(for: dm.getLastMessageDate()))!
        
        var currentDay: Date = first
        while currentDay <= last {
            let toDay: Date = Calendar.current.date(byAdding: .day, value: 6, to: currentDay)!
            let toComponents: DateComponents = Calendar.current.dateComponents([.month, .day], from: toDay)
            
            let from: String = Date.dateLoggedFormatter.string(from: currentDay)
            let to: String = toDay.isSameMonth(asDate: currentDay) ? toComponents.day!.description : Date.dateLoggedFormatter.string(from: toDay)
            
            weeks.append(WeekPickerWeek(
                weekOf: currentDay,
                display: "\(from) - \(to)",
                isThisWeek: today >= currentDay && today <= toDay))
            
            currentDay = Calendar.current.date(byAdding: .day, value: 7, to: currentDay)!
        }
    }
}

fileprivate struct WeekPickerWeek {
    let weekOf: Date
    let display: String
    let isThisWeek: Bool
}
