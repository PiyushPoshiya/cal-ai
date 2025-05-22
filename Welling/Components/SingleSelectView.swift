//
//  SingleSelectView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-06.
//

import SwiftUI

struct SingleSelectView<T: Identifiable & Equatable, U: View>: View {
    var options: [T]
    @Binding var selected: T
    var optionRenderer: (_ option: T) -> U
    
    var body: some View {
        VStack {
            ForEach(options, id: \.id) { option in
                Button {
                    selected = option
                } label: {
                    HStack {
                        optionRenderer(option)
                        Spacer()
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .overlay(selected == option ? Circle().inset(by: 0.5).fill(Theme.Colors.SurfaceSecondary100) : nil)
                    }
                    .padding(.vertical, Theme.Spacing.xsmall)
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var selectedItem: UserGoal = .loseWeight
        
        var body: some View {
            VStack {
                SingleSelectView(options: [UserGoal.loseWeight, UserGoal.buildMuscle, UserGoal.keepfit], selected: $selectedItem) { option in
                    Text(option.rawValue)
                }
            }
            .card()
        }
    }
    return PreviewWrapper()
}
