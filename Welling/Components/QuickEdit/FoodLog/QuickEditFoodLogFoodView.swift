//
//  QuickEditFoodLogFoodView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-19.
//

import SwiftUI
import Mixpanel

fileprivate enum Field: Hashable, Equatable {
    case servingSizeAmount
    case amount
    case calories
    case protein
    case carbs
    case fat
    case none
}

struct QuickEditFoodLogFoodView: View {
    @StateObject private var viewModel: QuickEditFoodLogFoodViewModel = QuickEditFoodLogFoodViewModel()
    @Binding var isPresented: Bool
    var foodLogFood: FoodLogFood
    var food: Food?
    var onSave: (_ update: FoodLogFoodUpdate) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            HStack {
                IconButtonView("xmark", showBackgroundColor: true, text: "Cancel") {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Cancel", "screen":"QuickEditFoodLogFoodView"])
                    isPresented = false
                }
                Spacer()
            }

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text(viewModel.name)
                            .fontWithLineHeight(Theme.Text.h5)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }

                    Spacer()
                        .frame(height: Theme.Spacing.large)

                    MacroTextFields(viewModel: viewModel)

//                    Spacer()
//                        .frame(height: Theme.Spacing.large)
//
//                    WellingCheckBox(isOn: $viewModel.saveForNextTime, text: "Savea for next time")

                    Spacer()
                        .frame(height: Theme.Spacing.large)

                    WBlobkButton("Save", imageName: "check", imagePosition: .right) {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Save", "screen":"QuickEditFoodLogFoodView"])
                        onSave(viewModel.foodLogFoodUpate)
                    }
                }
                .card()
            }
            .onAppear {
                viewModel.onAppear(foodLogFood: foodLogFood, food: food)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct MacroTextFields: View {
    @ObservedObject var viewModel: QuickEditFoodLogFoodViewModel
    @FocusState private var focused: Field?

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                if viewModel.hasServingSize {
                    NumericTextFieldWithLabel<Field>(label: viewModel.servingSizeName, placeholder: "Reqired", value: $viewModel.servingSizeAmount, focused: $focused, field: .servingSizeAmount)
                }
                NumericTextFieldWithLabel<Field>(label: "Amount (\(viewModel.unit))", placeholder: "Required", value: $viewModel.amount, focused: $focused, field: .amount)
            }

            HStack(spacing: Theme.Spacing.small) {
                NumericTextFieldWithLabel<Field>(label: "Calories", placeholder: "Required", value: $viewModel.calories, focused: $focused, field: .calories)

                NumericTextFieldWithLabel<Field>(label: "Protein (g)", placeholder: "Required", value: $viewModel.protein, focused: $focused, field: .protein)
            }

            HStack(spacing: Theme.Spacing.small) {
                NumericTextFieldWithLabel<Field>(label: "Carbs (g)", placeholder: "Required", value: $viewModel.carbs, focused: $focused, field: .carbs)

                NumericTextFieldWithLabel<Field>(label: "Fat (g)", placeholder: "Required", value: $viewModel.fat, focused: $focused, field: .fat)
            }
        }
        .onChange(of: viewModel.servingSizeAmount) {
            viewModel.onChangeServingSizeAmount(withFocus: focused ?? .none)
        }
        .onChange(of: viewModel.amount) {
            viewModel.onChangeAmount(withFocus: focused ?? .none)
        }
        .onChange(of: viewModel.amount) {
            viewModel.onChangeAmount(withFocus: focused ?? .none)
        }
        .onChange(of: viewModel.calories) {
            viewModel.onChangeCalories(withFocus: focused ?? .none)
        }
        .onChange(of: viewModel.fat) {
            viewModel.onChangeFat(withFocus: focused ?? .none)
        }
        .onChange(of: viewModel.carbs) {
            viewModel.onChangeCarbs(withFocus: focused ?? .none)
        }
        .onChange(of: viewModel.protein) {
            viewModel.onChangeProtein(withFocus: focused ?? .none)
        }
    }
}

#Preview {
    ScrollView {
        VStack {
            QuickEditFoodLogFoodView(isPresented: .constant(false), foodLogFood: .sample1, food: nil) {update in}
            QuickEditFoodLogFoodView(isPresented: .constant(false), foodLogFood: .sample2, food: nil) {update in}
            QuickEditFoodLogFoodView(isPresented: .constant(false), foodLogFood: .sample3, food: nil) {update in}
        }
    }
    .card()
}

class QuickEditFoodLogFoodViewModel: ObservableObject {
    var foodLogFoodUpate: FoodLogFoodUpdate = .empty

    @Published var name: String = ""

    @Published var saveForNextTime: Bool = false

    var initialized: Bool = false
    var servingSizeName: String = ""
    var unit: String = ""
    var hasServingSize: Bool = false
    var macrosChanged: Bool = false
    var food: Food? = nil

    @Published var servingSizeAmount: Double?
    @Published var amount: Double?
    @Published var calories: Double?
    @Published var protein: Double?
    @Published var carbs: Double?
    @Published var fat: Double?

    fileprivate func onAppear(foodLogFood: FoodLogFood, food: Food?) {
        if initialized {
            return
        }

        initialized = true

        self.food = food

        self.foodLogFoodUpate = .init(from: foodLogFood)
        self.name = foodLogFood.getFoodNameDisplayString()

        self.servingSizeName = foodLogFood.portionSizeName ?? ""
        self.servingSizeAmount = foodLogFood.portionSizeAmount
        self.hasServingSize = foodLogFood.portionSizeAmount != nil

        self.unit = foodLogFood.unit
        self.amount = foodLogFood.amount
        self.calories = round(foodLogFood.calories)
        self.protein = round(foodLogFood.protein)
        self.carbs = round(foodLogFood.carbs)
        self.fat = round(foodLogFood.fat)
    }

    fileprivate func onChangeServingSizeAmount(withFocus: Field) {
        if withFocus != .servingSizeAmount {
            return
        }

        guard let servingSizeAmount = servingSizeAmount else {
            return
        }

        foodLogFoodUpate.update(portionSizeAmount: servingSizeAmount, food: food)

        self.amount = foodLogFoodUpate.amount
        self.calories = round(foodLogFoodUpate.calories)
        self.protein = round(foodLogFoodUpate.protein)
        self.carbs = round(foodLogFoodUpate.carbs)
        self.fat = round(foodLogFoodUpate.fat)
    }

    fileprivate func onChangeAmount(withFocus: Field) {
        if withFocus != .amount {
            return
        }

        guard let amount = amount else {
            return
        }

        foodLogFoodUpate.update(amount: amount)
        self.servingSizeAmount = foodLogFoodUpate.portionSizeAmount
        self.calories = round(foodLogFoodUpate.calories)
        self.protein = round(foodLogFoodUpate.protein)
        self.carbs = round(foodLogFoodUpate.carbs)
        self.fat = round(foodLogFoodUpate.fat)
    }

    fileprivate func onChangeCalories(withFocus: Field) {
        if withFocus != .calories {
            return
        }

        guard let calories = calories else {
            return
        }

        foodLogFoodUpate.calories = calories
        macrosChanged = true
    }

    fileprivate func onChangeFat(withFocus: Field) {
        if withFocus != .fat {
            return
        }

        guard let fat = fat else {
            return
        }

        foodLogFoodUpate.fat = fat
        macrosChanged = true
    }

    fileprivate func onChangeCarbs(withFocus: Field) {
        if withFocus != .carbs {
            return
        }

        guard let carbs = carbs else {
            return
        }

        foodLogFoodUpate.carbs = carbs
        macrosChanged = true
    }

    fileprivate func onChangeProtein(withFocus: Field) {
        if withFocus != .protein {
            return
        }

        guard let protein = protein else {
            return
        }

        foodLogFoodUpate.protein = protein
        macrosChanged = true
    }

    static func formatAmount(amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", amount)
        }

        if amount.truncatingRemainder(dividingBy: 0.1) == 0 {
            return String(format: "%.1f", amount)
        }

        return String(format: "%.2f", amount)
    }
}
