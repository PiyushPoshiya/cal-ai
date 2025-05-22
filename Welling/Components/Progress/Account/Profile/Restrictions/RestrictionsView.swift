//
//  RestrictionsView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-09.
//

import SwiftUI

fileprivate enum Field {
    case otherAllergy
    case dietaryRestrictions
    case foodsToAvoid
    case otherConsiderations
}

struct RestrictionsView: View {
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
                
                ///MARK :- WEL-858: Allergies screen name: Diet and Macros
                ///Task :- change name Allergies and Restrictions
                ///Date :- 16 August, 2024
                ///By Piyush Poshiya

                Text("Allergies and Restrictions")
                    .fontWithLineHeight(Theme.Text.h5)
                Spacer()
                
                PrimaryTextButtonView("Save", disabled: !viewModel.updated) {
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
                        Text("Intolerances")
                            .fontWithLineHeight(Theme.Text.h4)
                        
                        Toggle("Lactose Intolerant", isOn: $viewModel.lactoseIntolerant)
                            .fontWithLineHeight(Theme.Text.mediumRegular)
                            .tint(Theme.Colors.SurfaceSecondary100)
                        
                        Toggle("Gluten Intolerant", isOn: $viewModel.glutentIntolerant)
                            .fontWithLineHeight(Theme.Text.mediumRegular)
                            .tint(Theme.Colors.SurfaceSecondary100)
                    }
                    .card()
                    
                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Allergies")
                            .fontWithLineHeight(Theme.Text.h4)
                        
                        SettingsCheckboxView(title: "None", isOn: $viewModel.allergyNone, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Dairy", isOn: $viewModel.allergyDairy, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Eggs", isOn: $viewModel.allergyEggs, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Nuts", isOn: $viewModel.allergyNuts, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Soy", isOn: $viewModel.allergySoy, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Wheat", isOn: $viewModel.allergyWheat, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Shellfish", isOn: $viewModel.allergyShellfish, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Shrimp", isOn: $viewModel.allergyShrimp, onTap: viewModel.allergyChecked)
                        
                        SettingsCheckboxView(title: "Fish", isOn: $viewModel.allergyFish, onTap: viewModel.allergyChecked)
                        
                        Text("Other:")
                            .fontWithLineHeight(Theme.Text.mediumRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral9)
                        
                        TextField("", text: $viewModel.otherAllergy)
                            .focused($focus, equals: .otherAllergy)
                            .textFieldStyle(WellingTextFeldStyle())
                            .autocorrectionDisabled()
                    }
                    .card()
                    
                    VStack (alignment: .leading, spacing: Theme.Spacing.xsmall) {
                        Text("Do you have any dietary restrictions due to specific health concerns or conditions?")
                            .fontWithLineHeight(Theme.Text.h5)
                        Text("Try to describe in detail")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral3)
                            .padding(.vertical, Theme.Spacing.xsmall)
                        
                        TextField("", text: $viewModel.dietaryRestrictions, axis: .vertical)
                        .focused($focus, equals: .dietaryRestrictions)
                        .textFieldStyle(WellingTextFeldStyle())
                        .padding(.vertical, Theme.Spacing.xsmall)
                    }
                    .card()
                    
                    VStack (alignment: .leading, spacing: Theme.Spacing.xsmall) {
                        Text("Any specific foods that you don’t like or can’t eat?")
                            .fontWithLineHeight(Theme.Text.h5)
                        Text("E.g. aubergines, tofu, sugary things, alcohol, etc.")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral3)
                            .padding(.vertical, Theme.Spacing.xsmall)
                        
                        TextField("", text: $viewModel.foodsToAvoid, axis: .vertical)
                        .focused($focus, equals: .foodsToAvoid)
                        .textFieldStyle(WellingTextFeldStyle())
                        .padding(.vertical, Theme.Spacing.xsmall)
                    }
                    .card()
                    
                    VStack (alignment: .leading, spacing: Theme.Spacing.xsmall) {
                        Text("Anything else that Welling should be aware of?")
                            .fontWithLineHeight(Theme.Text.h5)
                        Text("For example: food guidance from previous nutrition consultations.")
                            .fontWithLineHeight(Theme.Text.regularRegular)
                            .foregroundStyle(Theme.Colors.TextNeutral3)
                            .padding(.vertical, Theme.Spacing.xsmall)
                        
                        TextField("", text: $viewModel.otherConsiderations, axis: .vertical)
                        .focused($focus, equals: .otherConsiderations)
                        .textFieldStyle(WellingTextFeldStyle())
                        .padding(.vertical, Theme.Spacing.xsmall)
                    }
                    .card()

                }
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .onAppear {
            viewModel.onAppear(um: um)
        }
        .onChange(of: viewModel.otherAllergy) {
            viewModel.onOtherAllergyUpdated()
        }
        .onChange(of: viewModel.dietaryRestrictions) {
            viewModel.updated = true
        }
        .onChange(of: viewModel.foodsToAvoid) {
            viewModel.updated = true
        }
        .onChange(of: viewModel.otherConsiderations) {
            viewModel.updated = true
        }
    }
}

#Preview {
    RestrictionsView()
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .environmentObject(UserManager.sample)
        .environmentObject(DM())
}

extension RestrictionsView {
    @Observable
    @MainActor
    class ViewModel {
        var lactoseIntolerant: Bool = false
        var glutentIntolerant: Bool = false
        
        var allergyNone: Bool = false
        var allergyDairy: Bool = false
        var allergyEggs: Bool = false
        var allergyNuts: Bool = false
        var allergySoy: Bool = false
        var allergyWheat: Bool = false
        var allergyShellfish: Bool = false
        var allergyShrimp: Bool = false
        var allergyFish: Bool = false
        
        var updated: Bool = false
        var otherAllergy: String = ""
        
        var dietaryRestrictions: String = ""
        var foodsToAvoid: String = ""
        var otherConsiderations: String = ""
        
        @ObservationIgnored var allergies: Set<String> = Set()
        
        func onAppear(um: UserManager) {
            guard let profile = um.user.profile else {
                return
            }
            
            for intolerance in profile.intolerances {
                if intolerance.caseInsensitiveCompare("Lactose intolerant") == .orderedSame {
                    lactoseIntolerant = true
                } else if intolerance.caseInsensitiveCompare("Gluten intolerant") == .orderedSame  {
                    glutentIntolerant = true
                }
            }
            
            allergies = Set(profile.foodAllergies)
            updateAllergyCheckboxes(first: true)
            
            dietaryRestrictions = profile.dietaryRestrictions ?? ""
            foodsToAvoid = profile.foodsToAvoid ?? ""
            otherConsiderations = profile.otherConsiderations ?? ""
        }
        
        func allergyChecked(allergy: String) {
            updated = true
            if allergy == "None" {
                allergies.removeAll(keepingCapacity: true)
            } else {
                allergies.remove("None")
            }
            
            if otherAllergy.count > 0 {
                otherAllergy = ""
                allergies.removeAll(keepingCapacity: true)
            }
            
            if allergies.contains(allergy) {
                allergies.remove(allergy)
            } else {
                allergies.insert(allergy)
            }
            
            updateAllergyCheckboxes()
        }
        
        func onOtherAllergyUpdated() {
            updated = true
            if otherAllergy.isEmpty {
                if allergies.isEmpty {
                    allergyNone = true
                }
            }
            
            updateAllergyCheckboxes()
        }
        
        func updateAllergyCheckboxes(first: Bool = false) {
            allergyNone = allergies.contains("None")
            allergyDairy = allergies.contains("Dairy")
            allergyEggs = allergies.contains("Eggs")
            allergyNuts = allergies.contains("Nuts")
            allergySoy = allergies.contains("Soy")
            allergyWheat = allergies.contains("Wheat")
            allergyShellfish = allergies.contains("Shellfish")
            allergyShrimp = allergies.contains("Shrimp")
            allergyFish = allergies.contains("Fish")

            if !allergyNone && !allergyDairy && !allergyEggs && !allergyNuts && !allergySoy && !allergyWheat && !allergyShellfish && !allergyShrimp && !allergyFish {
                if first && !allergies.isEmpty {
                    otherAllergy = allergies.popFirst()!
                } else if first {
                    allergyNone = true
                }
            }
        }
        
        @MainActor
        func onSave(dm: DM, um: UserManager, presentationMode: Binding<PresentationMode>) async -> Bool {
            guard let profile = um.user.profile else {
                return false
            }
            
            var allergies: [String] = []
            if allergyDairy {
                allergies.append("Dairy")
            }
            if allergyEggs {
                allergies.append("Eggs")
            }
            if allergyNuts {
                allergies.append("Nuts")
            }
            if allergySoy {
                allergies.append("Soy")
            }
            if allergyWheat {
                allergies.append("Wheat")
            }
            if allergyShrimp {
                allergies.append("Shrimp")
            }
            if allergyFish {
                allergies.append("Fish")
            }
            if !otherAllergy.isEmpty {
                allergies.append(otherAllergy)
            }
            
            var intolerances: [String] = []
            if lactoseIntolerant {
                intolerances.append("Lactose intolerant")
            }
            if glutentIntolerant {
                intolerances.append("Gluten intolerant")
            }
            
            let _dietaryRestrictions: String = dietaryRestrictions.trimmingCharacters(in: .whitespacesAndNewlines)
            let _foodsToAvoid: String = foodsToAvoid.trimmingCharacters(in: .whitespacesAndNewlines)
            let _otherConsiderations: String = otherConsiderations.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let update: UserProfileRestrictionsUpdate = UserProfileRestrictionsUpdate(intolerances: intolerances, foodAllergies: allergies, dietaryRestrictions: _dietaryRestrictions.isEmpty ? nil : _dietaryRestrictions, foodsToAvoid: _foodsToAvoid.isEmpty ? nil : _foodsToAvoid, otherConsiderations: _otherConsiderations.isEmpty ? nil : _otherConsiderations)
            
            do {
                try await dm.update(user: um.user, profile: profile, restrictions: update)
            } catch {
                WLogger.shared.record(error)
                return false
            }
            return true
        }
    }
}
