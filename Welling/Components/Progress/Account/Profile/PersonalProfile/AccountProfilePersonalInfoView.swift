//
//  AccountProfilePersonalInfoView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI
import os

enum AccountProfilePersonalInfoField {
    case name
    case email
    case age
    case height
    case heightFeet
    case heightInches
    case country
    case city
}

struct AccountProfilePersonalInfoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var dm: DM
    @StateObject var viewModel: AccountProfilePersonalInfoViewModel = AccountProfilePersonalInfoViewModel()
    @FocusState fileprivate var focus: AccountProfilePersonalInfoField?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Profile")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                HStack {
                    IconButtonView("arrow-left-long", showBackgroundColor: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Spacer()
                    
                    PrimaryTextButtonView("Save") {
                        Task { @MainActor in
                            try await viewModel.onSave(dm: dm, um: userManager, presentationMode: presentationMode)
                        }
                    }
                }
            }
            .navbar()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.small) {
                    VStack(spacing: Theme.Spacing.large) {
                        TextFieldWithLabel(label: "Name", placeholder: "", value: $viewModel.name, focused: $focus, field: AccountProfilePersonalInfoField.name, keyboardType: .default)
                        
                        DisabledTextFieldWithLabel(label: "Email", value: viewModel.email)
                        
                        WellingToggleView(isOn: $viewModel.gender, optionOne: "Male", optionTwo: "Female")
                        
                        IntegerTextFieldWithLabel(label: "Age", placeholder: "", value: $viewModel.age, focused: $focus, field: AccountProfilePersonalInfoField.age)
                        
                        WellingToggleView(isOn: $viewModel.preferredUnits, optionOne: "Metric", optionTwo: "Imperial")
                        
                        HeightPickerView(height: $viewModel.height, preferredUnits: viewModel.preferredUnits ? .imperial : .metric, focus: $focus)
                        
                        CountryPickerView(selectedCountry: $viewModel.country)
                        
                        TextFieldWithLabel(label: "City", placeholder: "", value: $viewModel.city, focused: $focus, field: AccountProfilePersonalInfoField.city, keyboardType: .default)
                    }
                    .accountListSection()
                }
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .onAppear {
            viewModel.onAppear(um: userManager)
        }
        .onChange(of: viewModel.gender) { gender in
            viewModel.onGenderChanged()
        }
        .onChange(of: viewModel.age) { age in
            viewModel.onAgeChanged()
        }
        .onChange(of: viewModel.height) { height in
            viewModel.onHeightChanged()
        }
    }
}

#Preview {
    AccountProfilePersonalInfoView()
        .environmentObject(UserManager.sample)
        .environmentObject(DM())
}

class AccountProfilePersonalInfoViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AccountProfilePersonalInfoViewModel.self))
    
    @Published var name: String = ""
    var email: String = ""
    @Published var gender: Bool = false
    @Published var preferredUnits: Bool = false
    @Published var age: Int? = nil
    @Published var height: Int? =  nil
    @Published var country: String = ""
    @Published var city: String = ""
    
    var updatedMacroProfile: MacroProfile = .sample
    var computedMacroProfile: ComputedMacroProfile = .empty
    
    func onAppear(um: UserManager) {
        guard let profile = um.user.profile else {
            return
        }
        
        name = profile.name ?? ""
        email = profile.email ?? "-"
        if email.count == 0 {
            email = "-"
        }
        gender = profile.gender == .female ? true : false
        preferredUnits = profile.preferredUnits == .imperial ? true : false
        age = profile.age
        height = profile.height
        country = um.user.geo?.country ?? ""
        city = um.user.geo?.city ?? ""
        
        guard let height = height, let age = age else {
            return
        }
        
        updatedMacroProfile = MacroProfile(targetProteinPercentOverride: profile.targetProteinPercentOverride, targetFatPercentOverride: profile.targetFatPercentOverride, targetCarbsPercentOverride: profile.targetCarbsPercentOverride, currentWeight: profile.currentWeight, height: height, goal: profile.goal, age: age, gender: profile.gender, dietaryPreference: profile.dietaryPreference, calorieOverride: profile.calorieOverride, targetCalories: profile.targetCalories)
    }
    
    func onGenderChanged() {
        let chosenGender: Gender = gender ? .female : .male
        
        updatedMacroProfile.gender = chosenGender
        computedMacroProfile = ProfileUtils.getMacroProfile(macroProfile: updatedMacroProfile)
    }
    
    func onAgeChanged() {
        guard let age = age else {
            return
        }
        
        updatedMacroProfile.age = age
        computedMacroProfile = ProfileUtils.getMacroProfile(macroProfile: updatedMacroProfile)
    }
    
    func onHeightChanged() {
        guard let height = height else {
            return
        }
        
        updatedMacroProfile.height = height
        computedMacroProfile = ProfileUtils.getMacroProfile(macroProfile: updatedMacroProfile)
    }
    
    @MainActor
    func onSave(dm: DM, um: UserManager, presentationMode: Binding<PresentationMode>) async throws {
        guard let profile = um.user.profile else {
            return
        }
        
        guard let height = height, let age = age else {
            return
        }
        
        let chosenGender: Gender = gender ? .female : .male
        let chosenPreferredUnits: MeasurementUnit = preferredUnits ? .imperial : .metric
        
        let userProfileUpdate: UserProfilePersonalInfoUpdate = UserProfilePersonalInfoUpdate(name: name, gender: updatedMacroProfile.gender, preferredUnits: chosenPreferredUnits, age: updatedMacroProfile.age, height: updatedMacroProfile.height, country: country, city: city)
        
        do {
            try await dm.update(user: um.user, profile: profile, update: userProfileUpdate, macroProfile: computedMacroProfile)
            presentationMode.wrappedValue.dismiss()
        } catch {
            WLogger.shared.record(error)
        }
    }
}
