//
//  WellingToggleView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

struct WellingToggleView: View {
    @Binding var isOn: Bool
    var optionOne: String
    var optionTwo: String
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(BlockToggleStyle(optionOne: optionOne, optionTwo: optionTwo))
    }
    
}

struct BlockToggleStyle: ToggleStyle {
    var optionOne: String
    var optionTwo: String
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .center) {
            GeometryReader { geometry in
                HStack {
                    if configuration.isOn {
                        Spacer()
                    }
                    Rectangle()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.full))
                        .foregroundStyle(Theme.Colors.SurfaceSecondary100)
                        .frame(width: geometry.size.width / 2, height: Theme.Spacing.xlarge)
                        .padding(.top, Theme.Spacing.xsmall)
                }
                
                HStack {
                    Text(optionOne)
                        .frame(maxWidth: .infinity)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                    Text(optionTwo)
                        .frame(maxWidth: .infinity)
                        .fontWithLineHeight(Theme.Text.regularMedium)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: Theme.Spacing.xlarge)
                .padding(.top, Theme.Spacing.xsmall)
            }
        }
        .padding(.horizontal, Theme.Spacing.xsmall)
        .frame(height: Theme.Spacing.xxxlarge)
        .background(Theme.Colors.SurfaceNeutral05)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
        .onTapGesture {
            withAnimation( .easeInOut(duration: 0.15), {
                configuration.isOn.toggle()
            })
        }
    }
}

struct SmallToggleStyle: ToggleStyle {
    var optionOne: String
    var optionTwo: String
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: Theme.Radius.full, style: .continuous)
                .foregroundStyle(Theme.Colors.SurfaceNeutral2)
            
            HStack (spacing: 0) {
                if configuration.isOn {
                    Spacer()
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                Rectangle()
                    .frame(height: 32)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
                    .foregroundStyle(Theme.Colors.SurfacePrimary120)
                
                if !configuration.isOn {
                    Spacer()
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Theme.Spacing.xxsmall)
            
            HStack (spacing: 0) {
                Text(optionOne)
                    .fontWithLineHeight(Theme.Text.smallMedium)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 32)
                Text(optionTwo)
                    .fontWithLineHeight(Theme.Text.smallMedium)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 32)
            }
            .padding(.horizontal, Theme.Spacing.xxsmall)
        }
        .background(.clear)
        .frame(width: 96, height: 40)
        .onTapGesture {
            withAnimation( .easeInOut(duration: 0.15), {
                configuration.isOn.toggle()
            })
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var isOn: Bool = false
        
        var body: some View {
            VStack {
                Toggle("", isOn: $isOn)
                HStack {
                    Spacer()
                    Toggle("Text", isOn: $isOn)
                        .toggleStyle(SmallToggleStyle(optionOne: "D", optionTwo: "W"))
                }
                Toggle("Test", isOn: $isOn)
                    .toggleStyle(BlockToggleStyle(optionOne: "D", optionTwo: "W"))
            }
        }
    }
    return PreviewWrapper()
}
