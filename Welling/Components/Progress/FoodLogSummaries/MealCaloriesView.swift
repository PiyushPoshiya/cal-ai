//
//  MealCaloriesView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-02.
//

import SwiftUI
import os

struct MealCaloriesView: View {
    @Environment(ConversationScreenViewModel.self) var conversationScreenViewModel: ConversationScreenViewModel
    @EnvironmentObject var dm: DM
    
    @Binding var currentDay: Date
    let meal: Meal
    @Binding var calories: Double
    @Binding var summary: String
    @Binding var foodLogEntries: [MobileFoodLogEntry]
    @State private var sheetHeight: CGFloat = .zero
    @State var expanded: Bool = false
    var messages: [String:MobileMessage]
    
    var body: some View {
        VStack (spacing: Theme.Spacing.small) {
            VStack {
                HStack {
                    Text(meal.displayString())
                        .fontWithLineHeight(Theme.Text.h4)
                    
                    Spacer()
                    
                    
                    Text(lround(calories).description)
                        .fontWithLineHeight(Theme.Text.h4)
                    Text("kcal")
                        .fontWithLineHeight(Theme.Text.regularRegular)
                    ColoredIconView(imageName: "nav-arrow-right", foregroundColor: Theme.Colors.TextNeutral2)
                        .rotationEffect(expanded ? .degrees(90) : .degrees(0))
                }
                
                HStack {
                    Text(summary)
                        .fontWithLineHeight(Theme.Text.regularRegular)
                        .foregroundStyle(Theme.Colors.TextNeutral3)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    IconButtonView("plus", showBackgroundColor: true, backgroundColor: Theme.Colors.SurfacePrimary120, text: nil) {
                        conversationScreenViewModel.logFoodOn(day: currentDay, forMeal: meal)
                    }
                }
            }
            .card(small: true)
            .onTapGesture {
                if foodLogEntries.isEmpty {
                    return
                }
                
                var found = false
                for foodLogEntry in foodLogEntries {
                    if foodLogEntry.isDeleted {
                        continue
                    }
                    
                    for food in foodLogEntry.foods {
                        if food.isDeleted {
                            continue
                        }
                        found = true
                        break
                    }
                }
                
                if found {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expanded.toggle()
                    }
                }
            }
            
            if expanded {
                EditFoodLogFoodsView(foodLogEntries: $foodLogEntries, messages: messages)
            }
        }
    }
}
