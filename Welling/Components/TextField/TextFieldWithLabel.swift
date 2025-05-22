//
//  TextFieldWithLabel.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-24.
//

import SwiftUI

struct NumericTextFieldWithLabel<F: Hashable>: View  {
    var label: String
    var placeholder: String
    @Binding var value: Double?
    var focused: FocusState<F?>.Binding
    var field: F
    
    var body: some View {
        VStack {
            VStack(spacing: Theme.Spacing.xxsmall * -1) {
                HStack {
                    Text(label)
                        .fontWithLineHeight(Theme.Text.smallMedium)
                        .foregroundStyle(Theme.Colors.TextNeutral9)
                        .opacity(0.75)
                        .minimumScaleFactor(0.3)
                        .frame(alignment: .leading)
                    Spacer()
                }
                TextField(placeholder, value: $value, format: .number)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
                    .focused(focused, equals: field)
                    .keyboardType(.decimalPad)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .wellingTextFieldStyleWithTitle(focused: focused.wrappedValue == field)
        }
    }
}

struct IntegerTextFieldWithLabel<F: Hashable>: View  {
    var label: String
    var placeholder: String
    @Binding var value: Int?
    var focused: FocusState<F?>.Binding
    var field: F
    
    var body: some View {
        VStack {
            VStack(spacing: Theme.Spacing.xxsmall * -1) {
                HStack {
                    Text(label)
                        .fontWithLineHeight(Theme.Text.smallMedium)
                        .foregroundStyle(Theme.Colors.TextNeutral9)
                        .opacity(0.75)
                        .frame(alignment: .leading)
                    Spacer()
                }
                TextField(placeholder, value: $value, format: .number)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
                    .focused(focused, equals: field)
                    .keyboardType(.numberPad)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .wellingTextFieldStyleWithTitle(focused: focused.wrappedValue == field)
        }
    }
}

struct TextFieldWithLabel<F: Hashable>: View {
    var label: String
    var placeholder: String
    @Binding var value: String
    var focused: FocusState<F?>.Binding
    var field: F
    var keyboardType: UIKeyboardType
    
    var body: some View {
        VStack {
            VStack(spacing: Theme.Spacing.xxsmall * -1) {
                HStack {
                    Text(label)
                        .fontWithLineHeight(Theme.Text.smallMedium)
                        .foregroundStyle(Theme.Colors.TextNeutral9)
                        .opacity(0.75)
                        .frame(alignment: .leading)
                    Spacer()
                }
                TextField(placeholder, text: $value)
                    .fontWithLineHeight(Theme.Text.mediumMedium)
                    .focused(focused, equals: field)
                    .keyboardType(keyboardType)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .wellingTextFieldStyleWithTitle(focused: focused.wrappedValue == field)
        }
    }
}

struct NumberFieldWithTrailingLabel<F: Hashable, V>: View where V : ParseableFormatStyle, V.FormatOutput == String {
    @Binding var label: String
    var placeholder: String
    @Binding var value: V.FormatInput?
    var format: V
    var focused: FocusState<F?>.Binding
    var field: F
    var keyboardType: UIKeyboardType
    
    var body: some View {
        VStack {
            HStack(spacing: Theme.Spacing.xxsmall * -1) {
                TextField(placeholder, value: $value, format: format)
                    .fontWithLineHeight(Theme.Text.largeRegular)
                    .focused(focused, equals: field)
                    .keyboardType(.numberPad)
                Spacer()
                Text(label)
                    .fontWithLineHeight(Theme.Text.smallSemiBold)
                    .opacity(0.75)
                    .frame(alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .wellingTextFieldStyle(focused: focused.wrappedValue == field)
        }
    }
}

fileprivate enum Field: Hashable {
    case A
}

#Preview {
    TextFieldWithLabel<Field>(label: "385 calorie deficit", placeholder: "Name", value: .constant("Irwin"), focused: FocusState<Field?>().projectedValue, field: .A, keyboardType: .numberPad)
}
