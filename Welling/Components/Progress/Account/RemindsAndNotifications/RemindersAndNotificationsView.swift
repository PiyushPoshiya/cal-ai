//
//  RemindersAndNotificationsView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-09.
//

import SwiftUI
import os

@MainActor
struct RemindersAndNotificationsView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var dm: DM
    
    @State fileprivate var viewModel: ViewModel
    
    init(um: UserManager) {
        viewModel = ViewModel(um: um)
    }
    
    var body: some View {
        VStack (spacing: 0) {
            HStack (spacing: Theme.Spacing.medium) {
                IconButtonView("arrow-left-long", showBackgroundColor: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Text("Notifications")
                    .fontWithLineHeight(Theme.Text.h5)
                    .minimumScaleFactor(0.3)
                Spacer()
                IconButtonView("arrow-left-long", showBackgroundColor: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                .hidden()
            }
            .navbar()
            
            ScrollView {
                
                VStack (spacing: Theme.Spacing.small) {
                    VStack (spacing: Theme.Spacing.medium) {
                        NotificationToggleView(title: "All Notifications", description: "Controls coaching messages where Welling reaches out to you proactively. This includes reminders, and check-ins.", isOn: $viewModel.allNotifications)
                        
                        NotificationToggleView(title: "Educational Content", description: "During the first week, Welling will send explanations and tips once a day.", isOn: $viewModel.educationalContent)
                    }
                    .card()
                    
                    ReminderNotificationSettingView(title: "Afternoon Reminder", description: "If you have not logged any food for the day by \(Date.twelveHourFormatter.string(from: viewModel.lunchReminderTime)), Welling will reach out to remind you.", timeLabel: "Time", viewModel: $viewModel, enabled: $viewModel.lunchReminder, time: $viewModel.lunchReminderTime, daysOfWeek: .constant([]), selectDaysOfWeek: false)
                    
                    ReminderNotificationSettingView(title: "Dinner Reminder", description: "If you have not logged your dinner by \(Date.twelveHourFormatter.string(from: viewModel.endOfDayReminderTime)), Welling will reach out to remind you.", timeLabel: "Time", viewModel: $viewModel, enabled: $viewModel.endOfDayReminder, time: $viewModel.endOfDayReminderTime, daysOfWeek: .constant([]), selectDaysOfWeek: false)
                    
                    ReminderNotificationSettingView(title: "Weigh-In Reminder", description: "Welling will remind you to weigh yourself at \(Date.twelveHourFormatter.string(from: viewModel.weightLogReminderTime)).", timeLabel: "Time",viewModel: $viewModel,  enabled: $viewModel.weightLogReminder, time: $viewModel.weightLogReminderTime, daysOfWeek: $viewModel.weightLogReminderDaysOfWeek, selectDaysOfWeek: true)
                }
                .foregroundStyle(Theme.Colors.TextNeutral05)
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .onChange(of: viewModel.educationalContent) {
            viewModel.onNonAllNotificationToggled(dm: dm)
        }
        .onChange(of: viewModel.allNotifications) {
            viewModel.onAllNotificationToggled(dm: dm)
        }
    }
}

fileprivate struct ReminderNotificationSettingView: View {
    @EnvironmentObject var dm: DM
    
    let title: String
    let description: String
    let timeLabel: String
    
    @Binding var viewModel: RemindersAndNotificationsView.ViewModel
    @Binding var enabled: Bool
    @Binding var time: Date
    @Binding var daysOfWeek: [Bool]
    
    var selectDaysOfWeek: Bool = false
    
    var body: some View {
        VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .fontWithLineHeight(Theme.Text.h4)
                    .minimumScaleFactor(0.3)
                Text(description)
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            
            Toggle(isOn: $enabled) {
                VStack (alignment: .leading, spacing: 0) {
                    Text("Enabled")
                        .fontWithLineHeight(Theme.Text.mediumMedium)
                }
            }
            .tint(Theme.Colors.SurfaceSecondary100)
            
            DatePicker(selection: $time, displayedComponents: [.hourAndMinute]) {
                Text(timeLabel)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
            }
            .disabled(!enabled)
            .opacity(enabled ? 1.0 : 0.3)
            
            if selectDaysOfWeek {
                DayOfWeekPickerView(daysOfWeek: $daysOfWeek)
                    .disabled(!enabled)
                    .opacity(enabled ? 1.0 : 0.3)
            }
        }
        .onChange(of: enabled) {
            viewModel.onNonAllNotificationToggled(dm: dm)
        }
        .onChange(of: time) {
            viewModel.onNonAllNotificationToggled(dm: dm)
        }
        .onChange(of: daysOfWeek) {
            viewModel.onNonAllNotificationToggled(dm: dm)
        }
        .card()
    }
}

fileprivate struct NotificationToggleView: View {
    var title: String
    var description: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack (alignment: .leading, spacing: 0) {
                Text(title)
                    .fontWithLineHeight(Theme.Text.h4)
                    .minimumScaleFactor(0.3)
                Text(description)
                    .fontWithLineHeight(Theme.Text.regularRegular)
            }
            .foregroundStyle(Theme.Colors.TextNeutral05)
        }
        .tint(Theme.Colors.SurfaceSecondary100)
    }
}

#Preview {
    RemindersAndNotificationsView(um: UserManager.sample)
        .environmentObject(DM())
}


extension RemindersAndNotificationsView {
    @Observable
    @MainActor
    class ViewModel {
        private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: ViewModel.self))
        
        var educationalContent: Bool = false
        var allNotifications: Bool = false
        
        var lunchReminder: Bool = false
        var lunchReminderTime: Date = .distantPast
        @ObservationIgnored var lunchDaysOfWeek: [Bool] = [true, true, true, true, true, true, true]
        
        var endOfDayReminder: Bool = false
        var endOfDayReminderTime: Date = .distantPast
        @ObservationIgnored var endOfDayDaysOfWeek: [Bool] = [true, true, true, true, true, true, true]
        
        var weightLogReminder: Bool = false
        var weightLogReminderTime: Date = .distantPast
        var weightLogReminderDaysOfWeek: [Bool] = [false, false, false, false, false, true, false]
        
        @ObservationIgnored var isSaving: Bool = false
        
        @ObservationIgnored var um: UserManager
        
        init(um: UserManager) {
            self.um = um
            guard let notificationSettings = um.user.notificationSettings else{
                return
            }
            
            educationalContent = notificationSettings.educationalContent
            allNotifications = notificationSettings.allNotifications
            
            if let lunch = notificationSettings.lunch {
                lunchReminder = lunch.enabled
                lunchReminderTime = DateUtils.UtcCalendar.date(bySettingHour: lunch.hour, minute: lunch.minute, second: 0, of: .now)!
            } else {
                lunchReminder = notificationSettings.lunchFoodLogReminder
                lunchReminderTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: .now)!
            }
            
            if let endOfDay = notificationSettings.endOfDay {
                endOfDayReminder = endOfDay.enabled
                endOfDayReminderTime = DateUtils.UtcCalendar.date(bySettingHour: endOfDay.hour, minute: endOfDay.minute, second: 0, of: .now)!
            } else {
                endOfDayReminder = notificationSettings.endOfDayCheckIn
                endOfDayReminderTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now)!
            }
            
            if let weight = notificationSettings.weight {
                weightLogReminder = weight.enabled
                weightLogReminderTime = DateUtils.UtcCalendar.date(bySettingHour: weight.hour, minute: weight.minute, second: 0, of: .now)!
                weightLogReminderDaysOfWeek = Array(weight.daysOfWeek)
            } else {
                weightLogReminder = notificationSettings.logWeightReminder
                weightLogReminderTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now)!
            }
        }
        
        func onAppear(um: UserManager) {
        }
        
        func onNonAllNotificationToggled(dm: DM) {
            if isSaving {
                return
            }
            
            allNotifications = (educationalContent || lunchReminder || endOfDayReminder || weightLogReminder)
            isSaving = true
            save(dm: dm)
        }
        
        func onAllNotificationToggled(dm: DM) {
            if isSaving {
                return
            }
            
            if !allNotifications {
                educationalContent = false
                lunchReminder = false
                endOfDayReminder = false
                weightLogReminder = false
            }
            
            isSaving = true
            save(dm: dm)
        }
        
        func save(dm: DM) {
            guard let existingSettings = self.um.user.notificationSettings else {
                return
            }
            
            Task { @MainActor in
                do {
                    let update: UserNotificationsUpdate = UserNotificationsUpdate(
                        allNotifications: allNotifications,
                        lunchFoodLogReminder: lunchReminder,
                        endOfDayCheckIn: endOfDayReminder,
                        consistentLoggingReward: existingSettings.consistentLoggingReward,
                        educationalContent: educationalContent,
                        logWeightReminder: weightLogReminder,
                        dailyMorningCheckIn: existingSettings.dailyMorningCheckIn,
                        whatsAppMarketing: existingSettings.whatsAppMarketing,
                        lunch: getNotificationUpdate(enabled: lunchReminder, date: lunchReminderTime, daysOfWeek: lunchDaysOfWeek),
                        endOfDay: getNotificationUpdate(enabled: endOfDayReminder, date: endOfDayReminderTime, daysOfWeek: endOfDayDaysOfWeek),
                        weight: getNotificationUpdate(enabled: weightLogReminder, date: weightLogReminderTime, daysOfWeek: weightLogReminderDaysOfWeek))
                    try await dm.update(user: self.um.user, notificationSettings: update)
                } catch {
                    WLogger.shared.record(error)
                }
                isSaving = false
            }
        }
        
        func getNotificationUpdate(enabled: Bool, date: Date, daysOfWeek: [Bool]) -> NotificationUpdate {
            let components: DateComponents = DateUtils.UtcCalendar.dateComponents([.hour, .minute], from: date)
            return NotificationUpdate(enabled: enabled, hour: components.hour!, minute: components.minute!, daysOfWeek: daysOfWeek)
        }
    }
}
