//
//  QuickEditView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-05.
//

import RealmSwift
import SwiftUI
import os
import Mixpanel

struct QuickEditFoodLogSheetView: View {
    @EnvironmentObject var dm: DM
    @ObservedRealmObject var foodLogEntry: MobileFoodLogEntry
    @Binding var isPresented: Bool
    @StateObject var viewModel: QuickEditFoodLogEntryViewModel = QuickEditFoodLogEntryViewModel()
    
    @State private var sheetHeight: CGFloat = .zero
    var showNavBar: Bool = true
    var allowEditMealTime: Bool = true
    var isFavorite: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if showNavBar {
                    HStack {
                        IconButtonView("xmark", showBackgroundColor: true) {
                            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"xmark", "screen":"QuickEditFoodLogSheetView"])
                            isPresented = false
                        }
                        Spacer()
                        Text("\(lround(foodLogEntry.calories)) kcal")
                            .fontWithLineHeight(Theme.Text.h5)
                        Spacer()
                        TextButtonView("Delete") {
                            viewModel.onPresentDeleteFoodLog()
                            Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Delete", "screen":"QuickEditFoodLogSheetView"])
                        }
                    }
                    .sheetNavbar()
                    Spacer()
                        .frame(height: Theme.Spacing.small)
                }
                
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.large) {
                        // Set meal time
                        if allowEditMealTime {
                            VStack {
                                HStack {
                                    Text("Set meal time:")
                                        .foregroundStyle(Theme.Colors.Neutral7)
                                        .fontWithLineHeight(Theme.Text.tinyRegular)
                                    Spacer()
                                }
                                MealPickerUI(meal: $foodLogEntry.meal) { meal in
                                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Meal", "screen":"QuickEditFoodLogSheetView"])
                                    viewModel.onMealPicked(dm: dm, foodLogEntry: foodLogEntry, meal: meal)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.small)
                            .padding(.horizontal, Theme.Spacing.medium)
                            .background(Theme.Colors.SurfacePrimary100)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        }
                        
                        ForEach(foodLogEntry.foods.filter({$0.dateDeleted == nil}), id: \.id) { food in
                            QuickEditFoodView(foodLogFood: food) {
                                viewModel.onPresentDeleteFoodLogFood(foodLogFoodToDelete: food)
                            } onEdit: {
                                viewModel.onPresentEditFoodLogFood(foodLogFoodToEdit: food)
                            } onIncreaseServing: {
                                viewModel.onIncreaseServing(foodLogFood: food)
                            } onDecreaseServing: {
                                viewModel.onDecreaseServing(foodLogFood: food)
                            }
                        }
                        
                        FooDataSourceExplanationView()
                            .padding(.top, Theme.Spacing.medium)
                    }
                }
            }
            
            if viewModel.foodsLoading {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .padding(.horizontal, Theme.Spacing.small * -1)
                LoadingModalView(progressView: true)
            }
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .sheet(isPresented: $viewModel.presentDeleteSheet) {
            ConfirmDeleteSheetView(isPresented: $viewModel.presentDeleteSheet) {
                Task { @MainActor in
                    if await viewModel.handleDeleteConfirmed() {
                        if viewModel.deletingFoodLog {
                            isPresented = false
                        }
                    }
                }
            }
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $viewModel.presentEditFoodLogFood) {
            QuickEditFoodLogFoodView(isPresented: $viewModel.presentEditFoodLogFood,foodLogFood: viewModel.foodLogFoodToEdit, food: viewModel.foodOfFoodLogFoodToEdit) { update in
                if viewModel.update(foodLogFood: viewModel.foodLogFoodToEdit, with: update) {
                    viewModel.onHideEditFoodLogFood()
                }
            }
            .padding(.top, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.small)
            .background(Theme.Colors.SurfaceNeutral05)
        }
        .onAppear {
            Task { @MainActor in
                await viewModel.onAppear(dm: dm, foodLogEntry: foodLogEntry, isFavorite: isFavorite)
            }
        }
    }
}

struct FooDataSourceExplanationView: View {
    var body: some View {
        Text("Serving and nutrition data is based on various sources including [USDA](https://fdc.nal.usda.gov/), [EFSA](https://www.efsa.europa.eu/en), [SG ENCF](https://focos.hpb.gov.sg/eservices/ENCF/), [HK CFS](https://www.cfs.gov.hk/english/index.html), [MenuStat](https://www.menustat.org/), and Welling's proprietary database.")
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.Colors.TextNeutral05)
            .fontWithLineHeight(Theme.Text.regularRegular)
            .padding(.horizontal, Theme.Spacing.large)
    }
}

struct QuickEditFoodView: View {
    @EnvironmentObject var dm: DM
    @ObservedRealmObject var foodLogFood: FoodLogFood
    var portionShortcuts: Bool = true
    var onDelete: () -> Void
    var onEdit: () -> Void
    var onIncreaseServing: () -> Void
    var onDecreaseServing: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            HStack {
                IconButtonView("edit", showBackgroundColor: false, foregroundColor: Theme.Colors.Neutral7) {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"edit", "screen":"QuickEditFoodLogSheetView"])
                    onEdit()
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxxsmall) {
                        Text(foodLogFood.name)
                            .fontWithLineHeight(Theme.Text.mediumMedium)
                            .lineLimit(1)
                        Text("(\(foodLogFood.brand))")
                            .fontWithLineHeight(Theme.Text.mediumMedium)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Text("\(lround(foodLogFood.calories)) kcal, \(foodLogFood.getServingSizeString())")
                        .fontWithLineHeight(Theme.Text.mediumRegular)
                        .foregroundStyle(Theme.Colors.Neutral7)
                }
                .onTapGesture {
                    onEdit()
                }
                Spacer()
                
                IconButtonView("trash", showBackgroundColor: false, foregroundColor: Theme.Colors.Neutral7) {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"trash", "screen":"QuickEditFoodLogSheetView"])
                    onDelete()
                }
            }
            
            if portionShortcuts {
                HStack(spacing: 1) {
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Decrease Serving", "screen":"QuickEditFoodLogSheetView"])
                        onDecreaseServing()
                    } label: {
                        Image(systemName: "minus")
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.xsmall)
                            .background(Theme.Colors.SurfacePrimary100)
                    }
                    Button {
                        Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Increase Serving", "screen":"QuickEditFoodLogSheetView"])
                        onIncreaseServing()
                    } label: {
                        Image(systemName: "plus")
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.xsmall)
                            .background(Theme.Colors.SurfacePrimary100)
                    }
                }
                .padding(.top, 1)
                .background(Theme.Colors.SurfaceNeutral05)
            }
        }
        .padding(.top, Theme.Spacing.medium)
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.bottom, portionShortcuts ? Theme.Spacing.xxxsmall : Theme.Spacing.medium)
        .background(Theme.Colors.SurfacePrimary100)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }
}

#Preview {
    QuickEditFoodLogSheetView(foodLogEntry: MobileFoodLogEntry.sample, isPresented: .constant(true))
        .environmentObject(DM())
}
