//
//  DailyCalorieBudget.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-12.
//

import SwiftUI

struct DailyCalorieBudget: View {
    var profile: PMacroProfile
    let bmr: Int
    let tdee: Int
    let caloriesFromExercise: Int
    let caloriesDelta: Int
    let activityMultiplier: Double
    let activityLevelDisplay: String
    let targetCalories: Int
    
    init(profile: PMacroProfile) {
        self.profile = profile
        
        bmr = ProfileUtils.getBMR(profile: profile)
        tdee = ProfileUtils.getTDEE(profile: profile)
        activityMultiplier = ProfileUtils.getBMRMultiplier(activityLevel: profile.activityLevel)
        caloriesFromExercise = lround(activityMultiplier * Double(bmr))
        activityLevelDisplay = ProfileUtils.getDisplayFor(activityLevel: profile.activityLevel)
        targetCalories = ProfileUtils.getTargetCalories(profile: profile)
        caloriesDelta = targetCalories - tdee
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                        ColoredIconView(imageName: "info-circle", foregroundColor: Theme.Colors.Neutral7)
                        Spacer()
                }
                HStack {
                    Spacer()
                        Text("Daily Calorie Budget")
                            .fontWithLineHeight(Theme.Text.h5)
                    Spacer()
                }
            }
            .sheetNavbar()
//            HStack {
//                IconButtonView("edit", showBackgroundColor: true) {
//                    
//                }
//            }
            
            VStack(spacing: Theme.Spacing.large) {
                HStack {
                    Text("BMR")
                        .fontWithLineHeight(Theme.Text.mediumMedium)
                    Spacer()
                    Text("\((bmr).formatted()) kcal")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.75))
                }
                
                HStack {
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Baseline Activity")
                            .fontWithLineHeight(Theme.Text.mediumMedium)
                        Text("\(activityLevelDisplay) (x\((activityMultiplier).formatted()))")
                            .fontWithLineHeight(Theme.Text.smallRegular)
                    }
                    Spacer()
                    Text("+\(tdee - bmr) kcal")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.75))
                }
                .padding(.top, Theme.Spacing.small)
                
                HStack {
                    Text(caloriesDelta < 0 ? "Deficit" : "Surplus")
                        .fontWithLineHeight(Theme.Text.mediumMedium)
                    Spacer()
                    Text("\(caloriesDelta < 0 ? "-" : "+")\(abs(caloriesDelta).formatted()) kcal")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.75))
                }
                .padding(.top, Theme.Spacing.small)
                
//                if profile.goal == .buildMuscle {
//                    HStack {
//                        Text("Exercise Level")
//                            .fontWithLineHeight(Theme.Text.mediumMedium)
//                        Spacer()
//                        Text("+\((caloriesFromExercise).formatted()) kcal")
//                            .fontWithLineHeight(Theme.Text.regularRegular)
//                            .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.75))
//                    }
//                    .padding(.top, Theme.Spacing.small)
//                }
                
                Divider()
                    .frame(height: 1)
                    .overlay(Theme.Colors.TextPrimary100)
                
                HStack {
                    Text("Daily Calorie Budget")
                        .fontWithLineHeight(Theme.Text.mediumMedium)
                    Spacer()
                    Text("\((targetCalories).formatted()) kcal")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral9.opacity(0.75))
                }
            }
            .padding(.horizontal, Theme.Spacing.small + Theme.Spacing.medium)
            .padding(.top, Theme.Spacing.xxxlarge)
            .padding(.bottom, Theme.Spacing.xxlarge)
            .background(Theme.Colors.SurfaceNeutral2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        }
        .foregroundStyle(Theme.Colors.TextPrimary100)
        .background(Theme.Colors.SurfaceNeutral05)
    }
}

#Preview {
    DailyCalorieBudget(profile: WellingUser.sample.profile!)
}
