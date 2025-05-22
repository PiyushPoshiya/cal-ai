//
//  MealPickerUI.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-10.
//

import SwiftUI

struct MealPickerUI: View {
    @Binding var meal: Meal?
    var onMealChosen: (_ meal: Meal) -> Void
    

    var body: some View {
        HStack {
            Pill("Breakfast", selected: meal == .breakfast) {
                if meal != .breakfast {
                    meal = .breakfast
                    onMealChosen(.breakfast)
                }
            }
            Spacer()
            Pill("Lunch", selected: meal == .lunch) {
                if meal != .lunch {
                    meal = .lunch
                    onMealChosen(.lunch)
                }
            }
            Spacer()
            Pill("Dinner", selected: meal == .dinner) {
                if meal != .dinner {
                    meal = .dinner
                    onMealChosen(.dinner)
                }
            }
            Spacer()
            Pill("Snack", selected: meal == .snack) {
                if meal != .snack {
                    meal = .snack
                    onMealChosen(.snack)
                }
            }
        }
    }
}

struct Pill: View {
    var text: String
    var selected: Bool
    var action: () -> Void

    init(_ text: String, selected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .fontWithLineHeight(Theme.Text.regularMedium)
                .foregroundStyle(selected ? Theme.Colors.TextNeutral9 : Theme.Colors.TextNeutral05)
                .padding(.vertical, Theme.Spacing.xxsmall)
                .padding(.horizontal, Theme.Spacing.small)
                .background(selected ? Theme.Colors.SurfaceSecondary100 : Theme.Colors.SurfaceNeutral05)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
        }
    }
}

#Preview {
    VStack {
        MealPickerUI(meal: .constant(.breakfast)) {meal in}
        Pill("Breakfast", selected: false) {}
        Pill("Breakfast", selected: true) {}
    }
}
