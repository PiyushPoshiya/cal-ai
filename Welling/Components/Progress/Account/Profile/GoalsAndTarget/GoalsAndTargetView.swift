//
//  GoalsAndTargetView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-06.
//

import SwiftUI
import RealmSwift

fileprivate enum GoalsAndTargetField {
    case currentWeight
    case targetWeight
    case targetCalories
}

struct GoalsAndTargetView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var um: UserManager
    @EnvironmentObject var dm: DM
    @FocusState fileprivate var focus: GoalsAndTargetField?
    @State var viewModel: ViewModel = ViewModel()

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
                            if await viewModel.onSave(dm: dm, um: um, presentationMode: presentationMode) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
            .navbar()

            ScrollView {
                VStack (spacing: Theme.Spacing.medium) {
                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Main Goal")
                            .fontWithLineHeight(Theme.Text.h4)

                        SingleSelectView(options: [UserGoal.loseWeight, UserGoal.buildMuscle, UserGoal.keepfit], selected: $viewModel.userGoal) { option in
                            Text(option.description)
                                .fontWithLineHeight(Theme.Text.mediumRegular)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .card()

                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Weight")
                            .fontWithLineHeight(Theme.Text.h4)

                        HStack (spacing: Theme.Spacing.small) {
                            NumericTextFieldWithLabel(label: "Current weight (\(UnitUtils.weightUnitString(viewModel.preferredUnits)))", placeholder: "", value: $viewModel.currentWeight, focused: $focus, field: .currentWeight)

                            if viewModel.userGoal == .loseWeight {
                                NumericTextFieldWithLabel(label: "Target weight (\(UnitUtils.weightUnitString(viewModel.preferredUnits)))", placeholder: "", value: $viewModel.targetWeight, focused: $focus, field: .targetWeight)
                            }
                        }
                    }
                    .card()

                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Daily Activity Level")
                                .fontWithLineHeight(Theme.Text.h4)
                            Text("Excluding exercise")
                                .fontWithLineHeight(Theme.Text.regularRegular)
                        }

                        SingleSelectView(options: [ActivityLevel.SittingMostOfTheTime, ActivityLevel.OnMyFeetAllDay, ActivityLevel.HardPhysicalJob], selected: $viewModel.activityLevel) { option in
                            VStack (alignment: .leading, spacing: 0) {
                                Text(option.description)
                                    .fontWithLineHeight(Theme.Text.mediumSemiBold)
                                    .multilineTextAlignment(.leading)

                                Text(option.subDescription)
                                    .fontWithLineHeight(Theme.Text.regularRegular)
                            }
                        }
                    }
                    .card()

                    if viewModel.userGoal == .buildMuscle {
                        VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                            Text("Exercise Level")
                                .fontWithLineHeight(Theme.Text.h4)

                            SingleSelectView(options: [ExerciseLevel.LittleToNoExercise, ExerciseLevel.LightExerciseOrSports1To3DaysPerWeek, ExerciseLevel.ModerateExerciseOrSports3To5DaysPerWeek, ExerciseLevel.HardExerciseOrSports6To7DaysPerWeek, ExerciseLevel.VeryHardExerciseOrTrainingTwicePerDay], selected: $viewModel.exerciseLevel) { option in
                                VStack (alignment: .leading, spacing: 0) {
                                    Text(option.description)
                                        .fontWithLineHeight(Theme.Text.mediumSemiBold)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                        .card()
                    }

                    VStack (spacing: 0) {
                        HStack {
                            Text("Daily Calorie Budget")
                                .fontWithLineHeight(Theme.Text.h4)
                                .minimumScaleFactor(0.7)
                            Spacer()
                            IconButtonView("info-circle", showBackgroundColor: false, foregroundColor: Theme.Colors.TextNeutral3) {
                                viewModel.presentDailyTotalsSheet = true
                            }
                        }
                        Spacer()
                            .frame(height: Theme.Spacing.xlarge)
                        NumberFieldWithTrailingLabel(label: $viewModel.calorieDeficitLabel, placeholder: "", value: $viewModel.dailyCalorieTargetInput, format: .number, focused: $focus, field: .targetCalories, keyboardType: .numberPad)
                        if viewModel.isCalorieOverridden {
                            Text("Recommended daily caloric intake of \(viewModel.defaultDailyCalorieTarget) is overwritten. [Tap to reset](reset).")
                                .environment(\.openURL, OpenURLAction { url in
                                    viewModel.onResetCustomCalorieTarget()
                                    return .handled
                                })
                                .fontWithLineHeight(Theme.Text.regularMedium)
                                .foregroundStyle(Theme.Colors.TextNeutral2)
                                .tint(Theme.Colors.SurfaceSecondary100)
                                .padding(.top, Theme.Spacing.medium)
                                .padding(.horizontal, Theme.Spacing.medium)

                            Text(viewModel.dailyCalorieTargetWarning)
                                .fontWithLineHeight(Theme.Text.regularMedium)
                                .foregroundStyle(Theme.Colors.TextNeutral2)
                                .tint(Theme.Colors.SurfaceSecondary100)
                                .padding(.top, Theme.Spacing.medium)
                                .padding(.horizontal, Theme.Spacing.medium)
                        }
                    }
                    .card()

                    VStack (alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Add Burned Calories")
                            .fontWithLineHeight(Theme.Text.h4)

                        WellingToggleView(isOn: $viewModel.addBurnedCalories, optionOne: "Add", optionTwo: "Don't Add")

                        Text("""
You can choose to add your burned calories from activity logging onto your daily targets.

Be mindful that calorie burn estimates from activities tend to be overestimated.

If you did an average and moderate intensity workout and want to lose weight, it’s recommended to not eat back the calories you burn.
""")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                    }
                    .card()
                }
                .padding(.horizontal, Theme.Spacing.horizontalPadding)
            }
        }
        .onAppear {
            viewModel.onAppear(um: um)
        }
        .onChange(of: viewModel.userGoal) {
            viewModel.onGoalUpdated()
        }
        .onChange(of: viewModel.activityLevel) {
            viewModel.onActivityLevelUpdated()
        }
        .onChange(of: viewModel.exerciseLevel) {
            viewModel.onExerciseLevelUpdated()
        }
        .onChange(of: viewModel.dailyCalorieTargetInput) {
            viewModel.onDailyCalorieBudgetEdited()
        }
        .onChange(of: viewModel.targetWeight) {
            viewModel.onTargetWeightUpdated()
        }
        .onChange(of: viewModel.currentWeight) {
            viewModel.onCurrentWeightUpdated()
        }
        .sheet(isPresented: $viewModel.presentDailyTotalsSheet) {
            DailyCalorieBudget(profile: viewModel.macroProfile)
                .padding(.top, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.large)
                .padding(.horizontal, Theme.Spacing.small)
                .background(Theme.Colors.SurfaceNeutral05)
                .modifier(GetHeightModifier(height: $viewModel.sheetHeight))
                .presentationDetents([.height(viewModel.sheetHeight)])
        }
    }
}

#Preview {
    GoalsAndTargetView()
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .environmentObject(UserManager.sample)
}

extension GoalsAndTargetView {
    @Observable
    @MainActor
    class ViewModel {
        var macroProfile: MacroProfile = .empty
        var userGoal: UserGoal = .buildMuscle
        var activityLevel: ActivityLevel = .SittingMostOfTheTime
        var exerciseLevel: ExerciseLevel = .LittleToNoExercise

        var preferredUnits: MeasurementUnit = .metric
        var currentWeight: Double?
        var targetWeight: Double?

        var defaultDailyCalorieTarget: Int = 1500
        var dailyCalorieTargetInput: Int? = 1501
        var calorieDeficitLabel: String =  ""
        var dailyCalorieTargetWarning: String = ""
        var isCalorieOverridden: Bool = false

        var addBurnedCalories: Bool = false

        var presentDailyTotalsSheet: Bool = false
        var sheetHeight: CGFloat = .zero

        func onAppear(um: UserManager) {
            let profile = um.user.profile ?? .empty
            self.macroProfile = MacroProfile(from: profile)
            self.userGoal = profile.goal
            self.activityLevel = profile.activityLevel ?? .SittingMostOfTheTime
            self.exerciseLevel = profile.exerciseLevel ?? .LittleToNoExercise

            self.preferredUnits = profile.preferredUnits
            self.currentWeight = UnitUtils.weightValue(profile.currentWeight, profile.preferredUnits)

            if let targetWeight = profile.targetWeight {
                self.targetWeight = UnitUtils.weightValue(targetWeight, profile.preferredUnits)
            }

            self.addBurnedCalories = !profile.addBurnedCaloriesToDailyTotal
            self.dailyCalorieTargetInput = profile.calorieOverride ?? profile.targetCalories
            self.isCalorieOverridden = profile.calorieOverride != nil
        }

        func recomputeValues() {
            self.defaultDailyCalorieTarget = ProfileUtils.getTDEE(profile: macroProfile) + ProfileUtils.getCaloriesDelta(profile: macroProfile)

            switch macroProfile.gender {
            case .male:
                self.defaultDailyCalorieTarget = max(1500, self.defaultDailyCalorieTarget)
            case .female:
                self.defaultDailyCalorieTarget = max(1200, self.defaultDailyCalorieTarget)
            }

            if !isCalorieOverridden {
                self.dailyCalorieTargetInput = defaultDailyCalorieTarget
            }

            onDailyCalorieBudgetEdited()
        }

        @MainActor
        func onSave(dm: DM, um: UserManager, presentationMode: Binding<PresentationMode>) async -> Bool {
            guard var currentWeightToSave = self.currentWeight else {
                return false
            }

            guard self.dailyCalorieTargetInput != nil else {
                return false
            }

            guard let profile = um.user.profile else {
                return false
            }

            var targetWeightToSave: Double? = self.targetWeight
            if let _targetWeightToSave = targetWeightToSave {
                if _targetWeightToSave > currentWeightToSave {
                    return false
                }

                if preferredUnits == .imperial {
                    targetWeightToSave = UnitUtils.lbToKg(_targetWeightToSave)
                }
            } else {
                if userGoal == .loseWeight {
                    return false
                }
            }

            if preferredUnits == .imperial {
                currentWeightToSave = UnitUtils.lbToKg(currentWeightToSave)
            }

           setWarnings(um: um)

            let update: UserProfileGoalsAndTargetUpdate = UserProfileGoalsAndTargetUpdate(goal: userGoal, currentWeight: currentWeightToSave, targetWeight: targetWeightToSave, activityLevel: activityLevel, exerciseLevel: userGoal == .buildMuscle ? exerciseLevel : nil, addBurnedCaloriesToDailyTotal: !addBurnedCalories)
            let computedMacroProfile: ComputedMacroProfile = ProfileUtils.getMacroProfile(macroProfile: macroProfile)

            do {
                try await dm.update(user: um.user, profile: profile, update: update, macroProfile: computedMacroProfile)

                return true
            } catch {
                    WLogger.shared.record(error)
            }

            return false
        }

        func setWarnings(um: UserManager) {
            guard let profile = um.user.profile else {
                return
            }

            guard let dailyCalorieTarget = self.dailyCalorieTargetInput else {
                return
            }

            switch profile.gender {
            case .male:
                if dailyCalorieTarget < 1500 {
                    dailyCalorieTargetWarning = "A daily caloric intake below 1500 is not recommended for men."
                    return
                }
            case .female:
                if dailyCalorieTarget < 1200 {
                    dailyCalorieTargetWarning = "A daily caloric intake below 1200 is not recommended for women."
                    return
                }
            }


        }

        func onGoalUpdated() {
            macroProfile.goal = userGoal
            recomputeValues()
        }

        func onActivityLevelUpdated() {
            macroProfile.activityLevel = activityLevel
            recomputeValues()
        }

        func onExerciseLevelUpdated() {
            macroProfile.exerciseLevel = exerciseLevel
            recomputeValues()
        }

        func onDailyCalorieBudgetEdited() {
            isCalorieOverridden = dailyCalorieTargetInput == nil || defaultDailyCalorieTarget != dailyCalorieTargetInput

            macroProfile.targetCalories = self.defaultDailyCalorieTarget
            if isCalorieOverridden {
                if let dailyCalorieTargetInput = dailyCalorieTargetInput {
                    macroProfile.calorieOverride = dailyCalorieTargetInput
                }
            }

            updateCalorieDeficitLabel()
        }

        func onResetCustomCalorieTarget() {
            macroProfile.calorieOverride = nil
            dailyCalorieTargetInput = defaultDailyCalorieTarget
            isCalorieOverridden = false
        }

        func onCurrentWeightUpdated() {
            if let currentWeight = self.currentWeight {
                macroProfile.currentWeight = currentWeight
            }
        }

        func onTargetWeightUpdated() {
        }

        func updateCalorieDeficitLabel() {
            guard let dailyTargetInput = dailyCalorieTargetInput else {
                calorieDeficitLabel = ""
                return
            }

            // delta is tdee - target?
            let delta = dailyTargetInput - ProfileUtils.getTDEE(profile: macroProfile)
            if delta == 0 {
                calorieDeficitLabel = "0 calorie \(userGoal == .buildMuscle ? "surplus" : "deficit")"
            } else {
                calorieDeficitLabel = "\(abs(delta)) calorie \(delta > 0 ? "surplus" : "deficit")"
            }
        }
    }
}
