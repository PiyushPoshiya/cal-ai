//
//  DietAndMacrosView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-08.
//

import SwiftUI

fileprivate enum Field {
    case protein
    case proteinMin
    case proteinMax
    case carbs
    case fat
}

struct DietAndMacrosView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var um: UserManager
    @EnvironmentObject var dm: DM
    @FocusState fileprivate var focus: Field?
    @State var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconButtonView("arrow-left-long", showBackgroundColor: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                Text("Diet and Macros")
                    .fontWithLineHeight(Theme.Text.h5)
                Spacer()
                
                PrimaryTextButtonView("Save", disabled: !viewModel.updated || (viewModel.updated && viewModel.hasError)) {
                    Task { @MainActor in
                        if await viewModel.onSave(dm: dm, um: um, presentationMode: presentationMode) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navbar()
            
            ScrollView {
                VStack (spacing: Theme.Spacing.medium) {
                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        VStack (alignment: .leading, spacing: 0) {
                            Text("Diet Preference")
                                .fontWithLineHeight(Theme.Text.h4)
                            Text("Pick Balanced Diet if you have no preference")
                                .fontWithLineHeight(Theme.Text.regularRegular)
                        }
                        
                        Menu {
                            Picker(selection: $viewModel.dietaryPreference, label: EmptyView(), content: {
                                ForEach(ViewModel.dietaryPreferences, id: \.self) { pref in
                                    Text(pref).tag(pref)
                                    
                                }
                            }).pickerStyle(.automatic)
                        } label: {
                            Button {
                                
                            } label: {
                                HStack {
                                    Text(viewModel.dietaryPreference)
                                        .fontWithLineHeight(Theme.Text.mediumMedium)
                                    Spacer()
                                    ColoredIconView(imageName: "nav-arrow-down")
                                }
                                .padding(.vertical, Theme.Spacing.medium)
                                .padding(.horizontal, Theme.Spacing.medium)
                                .background(Theme.Colors.SurfaceNeutral05)
                                .foregroundStyle(Theme.Colors.TextPrimary100)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .inset(by: 1)
                                    .stroke(Theme.Colors.BorderNeutral2, lineWidth: 2))
                            }
                        }
                    }
                    .card()
                    
                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        HStack {
                            Text("Macro Ratio")
                                .fontWithLineHeight(Theme.Text.h4)
                            
                            Spacer()
                            
                            if viewModel.customMacros {
                                TextButtonView("Reset") {
                                    viewModel.onResetMacros()
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 0)
                        
                        MacroTextFieldWithLabel(title: "Protein (%)", label: $viewModel.proteinLabel, placeholder: "", value: $viewModel.proteinPercent, error: $viewModel.proteinError, focused: $focus, field: .protein)
                        
                        MacroTextFieldWithLabel(title: "Carbs (%)", label: $viewModel.carbsLabel, placeholder: "", value: $viewModel.carbsPercent, error: $viewModel.carbsError, focused: $focus, field: .carbs)
                        
                        MacroTextFieldWithLabel(title: "Fat (%)", label: $viewModel.fatLabel, placeholder: "", value: $viewModel.fatPercent, error: $viewModel.fatError, focused: $focus, field: .fat)
                        
                        if let macroError = viewModel.macroError {
                            HStack {
                                Spacer()
                                Text(macroError)
                                    .fontWithLineHeight(Theme.Text.regularMedium)
                                    .foregroundStyle(Theme.Colors.SemanticError)
                                    .padding(.top, Theme.Spacing.medium)
                                    .padding(.horizontal, Theme.Spacing.medium)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                        }
                        
                    }.card()
                }
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .onAppear {
            viewModel.onAppear(um: um)
        }
        .onChange(of: viewModel.dietaryPreference) {
            viewModel.onDietPreferenceChange()
        }
        .onChange(of: viewModel.proteinPercent) {
            viewModel.onProteinPercentChange()
        }
        .onChange(of: viewModel.carbsPercent) {
            viewModel.onCarbsPercentChange()
        }
        .onChange(of: viewModel.fatPercent) {
            viewModel.onFatPercentChange()
        }
    }
}

#Preview {
    DietAndMacrosView()
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .environmentObject(UserManager.sample)
        .environmentObject(DM())
}

extension DietAndMacrosView {
    @Observable
    @MainActor
    class ViewModel {
        static let dietaryPreferences: [String] = [
            "Balanced diet",
            "Low carb diet",
            "High protein diet",
            "Vegetarian diet",
            "Vegan diet",
            "Paleo diet",
            "Keto diet",
            "Mediterranean diet",
            "Pescatarian diet"
        ]
        
        var macroProfile: MacroProfile = .sample
        var computedMacros: ComputedMacroProfile = .empty
        
        var dietaryPreference: String = ViewModel.dietaryPreferences[0]
        
        var targetCalories: Int = 0
        
        var protein: Int = 0
        var proteinLabel: String = "0g"
        var proteinPercent: Int? = 0
        var proteinError: String? = ""
        
        var carbs: Int = 0
        var carbsLabel: String = "0g"
        var carbsPercent: Int? = 0
        var carbsError: String? = ""
        
        var fat: Int = 0
        var fatLabel: String = "0g"
        var fatPercent: Int? = 0
        var fatError: String? = ""
        
        var customMacros: Bool = false
        
        var hasError: Bool = true
        var updated: Bool = true
        var macroError: String? = nil
        
        func onAppear(um: UserManager) {
            let profile = um.user.profile ?? .empty
            
            dietaryPreference = profile.dietaryPreference
            self.macroProfile = MacroProfile(from: profile)
            
            updateMacroFields()
        }
        
        @MainActor
        func onSave(dm: DM, um: UserManager, presentationMode: Binding<PresentationMode>) async -> Bool {
            let dietAndMacrosUpdate: UserDietAndMacrosUpdate = UserDietAndMacrosUpdate(dietaryPreference: dietaryPreference)
            
            guard let profile = um.user.profile else {
                return false
            }
            
            do {
                try await dm.update(user: um.user, profile: profile, update: dietAndMacrosUpdate, macroProfile: computedMacros)
            } catch {
                WLogger.shared.record(error)
                return false
            }
            return true
        }
        
        func onDietPreferenceChange() {
            macroProfile.dietaryPreference = dietaryPreference
            updateMacroFields()
        }
        
        func onProteinPercentChange() {
            if proteinPercent == computedMacros.proteinPercent {
                macroProfile.targetProteinPercentOverride = nil
                customMacros = false
            } else {
                customMacros = true
                macroProfile.targetProteinPercentOverride = proteinPercent
            }
            
            updateMacroFields()
        }
        
        func onCarbsPercentChange() {
            if carbsPercent == computedMacros.carbsPercent {
                macroProfile.targetCarbsPercentOverride = nil
                customMacros = false
            } else {
                
                customMacros = true
                macroProfile.targetCarbsPercentOverride = carbsPercent
            }
            
            updateMacroFields()
        }
        
        func onFatPercentChange() {
            if fatPercent == computedMacros.fatPercent {
                customMacros = false
                macroProfile.targetFatPercentOverride = nil
                return
            } else {
                customMacros = true
                macroProfile.targetFatPercentOverride = fatPercent
            }
            
            updateMacroFields()
        }
        
        func updateMacroFields() {
            computedMacros = ProfileUtils.getMacroProfile(macroProfile: macroProfile)
            
            protein = computedMacros.targetProtein
            if proteinPercent != nil {
                proteinPercent = computedMacros.targetProteinPercentOverride ?? computedMacros.proteinPercent
                proteinLabel = "\(protein)g"
            } else {
                proteinLabel = ""
            }
            
            carbs = computedMacros.targetCarbs
            if carbsPercent != nil {
                carbsPercent = computedMacros.targetCarbsPercentOverride ?? computedMacros.carbsPercent
                carbsLabel = "\(carbs)g"
            } else {
                carbsLabel = ""
            }
            
            fat = computedMacros.targetFat
            if fatPercent != nil {
                fatPercent = computedMacros.targetFatPercentOverride ?? computedMacros.fatPercent
                fatLabel = "\(fat)g"
            } else {
                fatLabel = ""
            }
            
            targetCalories = computedMacros.calorieOverride ?? computedMacros.targetCalories
            
            customMacros = macroProfile.targetFatPercentOverride != nil || macroProfile.targetCarbsPercentOverride != nil || macroProfile.targetProteinPercentOverride != nil
            
            validateFields()
        }
        
        func validateFields() {
            guard let proteinPercent = proteinPercent else {
                hasError = true
                proteinError = "Protein is required"
                return
            }
            proteinError = nil
            
            guard let fatPercent = fatPercent else {
                hasError = true
                fatError = "Fat is required"
                return
            }
            fatError = nil
            
            guard let carbsPercent = carbsPercent else {
                hasError = true
                carbsError = "Carbs is required"
                return
            }
            carbsError = nil
            
            if (proteinPercent + carbsPercent + fatPercent) != 100 {
                hasError = true
                macroError = "Macro ratios must add up to 100%."
                return
            }
            macroError = nil
            
            hasError = false
        }
        
        func onResetMacros() {
            customMacros = false
            
            proteinPercent = computedMacros.proteinPercent
            macroProfile.targetProteinPercentOverride = nil
            
            carbsPercent = computedMacros.carbsPercent
            macroProfile.targetCarbsPercentOverride = nil
            
            fatPercent = computedMacros.fatPercent
            macroProfile.targetFatPercentOverride = nil
        }
    }
}


struct MacroTextFieldWithLabel<F: Hashable>: View  {
    var title: String
    @Binding var label: String
    var placeholder: String
    @Binding var value: Int?
    @Binding var error: String?
    var focused: FocusState<F?>.Binding
    var field: F
    
    var body: some View {
        VStack (alignment: .leading, spacing: Theme.Spacing.xxsmall) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxsmall * -1) {
                    Text(title)
                        .fontWithLineHeight(Theme.Text.smallMedium)
                        .foregroundStyle(Theme.Colors.TextNeutral9)
                        .opacity(0.75)
                        .frame(alignment: .leading)
                    
                    TextField(placeholder, value: $value, format: .number)
                        .fontWithLineHeight(Theme.Text.mediumMedium)
                        .focused(focused, equals: field)
                        .keyboardType(.numberPad)
                }
                Spacer()
                Text(label)
                    .fontWithLineHeight(Theme.Text.regularSemiBold)
                    .foregroundStyle(Theme.Colors.TextNeutral3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .wellingTextFieldStyleWithTitle(focused: focused.wrappedValue == field, error: error != nil)
            
            if let error = error {
                Text(error)
                    .fontWithLineHeight(Theme.Text.regularMedium)
                    .foregroundStyle(Theme.Colors.SemanticError)
            }
        }
    }
}
