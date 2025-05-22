//
//  HeightPickerView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-26.
//

import SwiftUI

struct HeightPickerView: View {
    @Binding var height: Int?
    var preferredUnits: MeasurementUnit
    @State var heightFeet: Int? = nil
    @State var heightInches: Int? = nil
    @FocusState.Binding var focus: AccountProfilePersonalInfoField?
    
    init(height: Binding<Int?>, preferredUnits: MeasurementUnit, focus: FocusState<AccountProfilePersonalInfoField?>.Binding) {
        self._height = height
        self.preferredUnits = preferredUnits
        self._focus = focus
    }
    
    var body: some View {
        Group {
            if preferredUnits == .imperial {
                HStack (spacing: Theme.Spacing.small) {
                    IntegerTextFieldWithLabel(label: "Height (ft)", placeholder: "Required", value: $heightFeet, focused: $focus, field: AccountProfilePersonalInfoField.heightFeet)
                    
                    IntegerTextFieldWithLabel(label: "Height (in)", placeholder: "Required", value: $heightInches, focused: $focus, field: AccountProfilePersonalInfoField.heightInches)
                }
            } else {
                IntegerTextFieldWithLabel(label: "Height (cm)", placeholder: "Required", value: $height, focused: $focus, field: AccountProfilePersonalInfoField.height)
            }
        }
        .onAppear {
            updateImperialHeight()
        }
        .onChange(of: height) {
            updateImperialHeight()
        }
        .onChange(of: heightFeet) {
            updateMetricHeight()
        }
        .onChange(of: heightInches) {
            updateMetricHeight()
        }
    }
    
    func updateImperialHeight() {
        if preferredUnits == .imperial {
            return
        }
        
        guard let height = height else {
            return
        }
        
        let imperialHeight = UnitUtils.cmToImperial(height)
        heightFeet = imperialHeight.feet
        heightInches = imperialHeight.inches
    }
    
    func updateMetricHeight() {
        if preferredUnits == .metric {
            return
        }
        
        guard let heightFeet = heightFeet else {
            return
        }
        guard let heightInches = heightInches else {
            return
        }
        
        height = UnitUtils.imperialToCm(heightFeet, heightInches)
    }
}

#Preview {
    HeightPickerView(height: .constant(173), preferredUnits: .imperial, focus: FocusState<AccountProfilePersonalInfoField?>().projectedValue)
}
