//
//  EditFoodLogFoodsView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-04.
//

import SwiftUI
import os

struct EditFoodLogFoodsView: View {
    @EnvironmentObject var dm: DM
    
    @Binding var foodLogEntries: [MobileFoodLogEntry]
    var messages: [String:MobileMessage]
    
    @State private var viewModel: ViewModel = ViewModel()
    @State private var sheetHeight: CGFloat = .zero
    
    var body: some View {
        ZStack {
            LazyVStack {
                ForEach ($foodLogEntries, id: \.id) { $foodLogEntry in
                    if let image = messages[foodLogEntry.messageId]?.image {
                        MobileMessageImageView(image: .constant(image))
                            .frame(width: UIScreen.main.bounds.width - 24, height: 430)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
                    }
                    
                    ForEach($foodLogEntry.foods, id: \.id) { $food in
                        if food.isDeleted {
                            EmptyView()
                        } else {
                            QuickEditFoodView(foodLogFood: food, portionShortcuts: false) {
                                viewModel.onPresentDeleteFoodLogFood(foodLogFoodToDelete: food, inFoodLogEntry: foodLogEntry)
                            } onEdit: {
                                viewModel.onPresentEditFoodLogFood(foodLogFoodToEdit: food, inFoodLogEntry: foodLogEntry)
                            } onIncreaseServing: {
                            } onDecreaseServing: {
                            }
                        }
                    }
                }
            }
            
            if viewModel.foodsLoading {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                LoadingModalView(progressView: true)
            }
        }
        .sheet(isPresented: $viewModel.presentDeleteSheet) {
            ConfirmDeleteSheetView(isPresented: $viewModel.presentDeleteSheet) {
                
                ///MARK :- WEL-864: Deleting items on some screens does not update the screen
                ///Task :- set async time
                ///Date :- 21 August, 2024
                ///By Piyush Poshiya

                Task { @MainActor in
                    await viewModel.handleDeleteConfirmed()
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
                await viewModel.onAppear(dm: dm, foodLogEntries: foodLogEntries)
            }
        }
    }
}

extension EditFoodLogFoodsView {
    
    @Observable
    @MainActor
    class ViewModel {
        static let loggerCategory =  String(describing: ViewModel.self)
        static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: loggerCategory
        )
        
        var foodsLoading: Bool = true
        var foods: [String:Food] = [:]
        var presentDeleteSheet: Bool = false
        var presentEditFoodLogFood: Bool = false
        
        var dm: DM?
        
        var foodLogFoodToEdit: FoodLogFood = .empty
        var foodLogFoodToDelete: FoodLogFood?
        var inFoodLogEntry: MobileFoodLogEntry?
        var foodOfFoodLogFoodToEdit: Food?
        var deletingFoodLogFood: Bool = false
        
        @MainActor
        func onAppear(dm: DM, foodLogEntries: [MobileFoodLogEntry]) async {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
            
            do {
                for foodLogEntry in foodLogEntries {
                    let results = try await dm.getFoodsFor(foodLogEntry: foodLogEntry)
                    if let _foods = results.value {
                        self.foods.merge(_foods) { (current, _) in current }
                    }
                }
                
                self.foodsLoading = false
                
                self.dm = dm
            } catch {
                WLogger.shared.record(error)
            }
        }
        
        func onPresentDeleteFoodLogFood(foodLogFoodToDelete: FoodLogFood, inFoodLogEntry: MobileFoodLogEntry) {
            self.foodLogFoodToDelete = foodLogFoodToDelete
            self.inFoodLogEntry = inFoodLogEntry
            self.deletingFoodLogFood = true
            self.presentDeleteSheet = true
            self.presentEditFoodLogFood = false
        }
        
        func onPresentEditFoodLogFood(foodLogFoodToEdit: FoodLogFood, inFoodLogEntry: MobileFoodLogEntry) {
            self.deletingFoodLogFood = false
            self.presentDeleteSheet = false
            
            self.presentEditFoodLogFood = true
            self.foodLogFoodToEdit = foodLogFoodToEdit
            self.inFoodLogEntry = inFoodLogEntry
            self.foodOfFoodLogFoodToEdit = foodLogFoodToEdit.foodId != nil ? foods[foodLogFoodToEdit.foodId!] : nil
        }
        
        func onHideEditFoodLogFood() {
            self.presentEditFoodLogFood = false
            self.foodLogFoodToEdit = .empty
            self.foodOfFoodLogFoodToEdit = nil
        }
        
        func handleDeleteConfirmed() async -> Bool {
            guard let inFoodLogEntry = inFoodLogEntry else {
                return false
            }
            
            if deletingFoodLogFood {
                return await deleteFoodLogFood(inFoodLogEntry: inFoodLogEntry)
            }
            
            return false
        }
        
        @MainActor
        private func deleteFoodLogFood(inFoodLogEntry foodLogEntry: MobileFoodLogEntry) async -> Bool {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
            
            var count = 0
            for food in foodLogEntry.foods {
                if food.dateDeleted != nil {
                    continue
                }
                count += 1
            }
            
            guard let dm = dm, let foodLogFoodToDelete = foodLogFoodToDelete else {
                return false
            }
            
            do {
                // If only 1 food log food left, delete entire food
                if count == 1 {
                    try await dm.delete(foodLogEntry: foodLogEntry)
                } else {
                    try await dm.delete(foodLogFood: foodLogFoodToDelete, inFoodLogEntry: foodLogEntry, isFavorite: false)
                }
            } catch {
                WLogger.shared.record(error)
                return false
            }
            
            presentDeleteSheet = false
            
            return true
        }
        
        func update(foodLogFood: FoodLogFood?, with: FoodLogFoodUpdate) -> Bool {
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
            
            guard let dm = dm, let foodLogEntry = inFoodLogEntry, let foodLogFood = foodLogFood else {
                return false
            }
            
            if foodLogFood == .empty {
                return false
            }
            
            Task { @MainActor in
                do {
                    try await dm.update(foodLogFood: foodLogFood, inFoodLogEntry: foodLogEntry, with: with, isFavorite: false)
                } catch {
                    WLogger.shared.record(error)
                }
            }
            
            return true
        }
    }
}
