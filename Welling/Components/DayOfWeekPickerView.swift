//
//  DayOfWeekPickerView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-08-20.
//

import SwiftUI

struct DayOfWeekPickerView: View {
    @Binding var daysOfWeek: [Bool]
    
    @State var monday: Bool
    @State var tuesday: Bool
    @State var wednesday: Bool
    @State var thursday: Bool
    @State var friday: Bool
    @State var saturday: Bool
    @State var sunday: Bool
    
    init(daysOfWeek: Binding<[Bool]>) {
        _daysOfWeek = daysOfWeek
        _sunday = State(initialValue: daysOfWeek.wrappedValue[0])
        _monday = State(initialValue: daysOfWeek.wrappedValue[1])
        _tuesday = State(initialValue: daysOfWeek.wrappedValue[2])
        _wednesday = State(initialValue: daysOfWeek.wrappedValue[3])
        _thursday = State(initialValue: daysOfWeek.wrappedValue[4])
        _friday = State(initialValue: daysOfWeek.wrappedValue[5])
        _saturday = State(initialValue: daysOfWeek.wrappedValue[6])
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
            SettingsCheckboxView(title: "Monday", isOn: $monday, font: Theme.Text.mediumMedium, onTap: {checked in
                monday = !monday
                daysOfWeek[1] = monday
            })
            SettingsCheckboxView(title: "Tuesday", isOn: $tuesday, font: Theme.Text.mediumMedium, onTap: {checked in
                tuesday = !tuesday
                daysOfWeek[2] = tuesday
            })
            SettingsCheckboxView(title: "Wednesday", isOn: $wednesday, font: Theme.Text.mediumMedium, onTap: {checked in
                wednesday = !wednesday
                daysOfWeek[3] = wednesday
            })
            SettingsCheckboxView(title: "Thursday", isOn: $thursday, font: Theme.Text.mediumMedium, onTap: {checked in
                thursday = !thursday
                daysOfWeek[4] = thursday
            })
            SettingsCheckboxView(title: "Friday", isOn: $friday, font: Theme.Text.mediumMedium, onTap: {checked in
                friday = !friday
                daysOfWeek[5] = friday
            })
            SettingsCheckboxView(title: "Saturday", isOn: $saturday, font: Theme.Text.mediumMedium, onTap: {checked in
                saturday = !saturday
                daysOfWeek[6] = saturday
            })
            SettingsCheckboxView(title: "Sunday", isOn: $sunday, font: Theme.Text.mediumMedium, onTap: {checked in
                sunday = !sunday
                daysOfWeek[0] = sunday
            })
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var daysOfWeek: [Bool] = [true, true, true, true, true, true, true]
        
        var body: some View {
            DayOfWeekPickerView(daysOfWeek: $daysOfWeek)
        }
    }
    return PreviewWrapper()
}
