//
//  QuickEditWeightLogView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-24.
//

import SwiftUI
import RealmSwift
import os

fileprivate enum Field: Hashable, Equatable {
    case weight
}

struct QuickEditWeightLogView: View {
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um : UserManager
    @State private var sheetHeight: CGFloat = .zero
    @StateObject fileprivate var viewModel: QuickEditViewModel = QuickEditViewModel()
    
    @ObservedRealmObject var weightLog: MobileWeightLog
    @Binding var isPresented: Bool
    @FocusState private var focused: Field?
    
    var body: some View {
        VStack {
            HStack {
                IconButtonView("xmark", showBackgroundColor: true) {
                    isPresented = false
                }
                Spacer()
                TextButtonView("Delete") {
                    viewModel.onPresentConfirmDeleteWeightLog()
                }
            }
            .sheetNavbar()
            
            VStack(spacing: Theme.Spacing.large) {
                HStack {
                    Text("Weight on \(Date.dateLoggedWithYearFormatter.string(from: weightLog.timestamp))")
                        .fontWithLineHeight(Theme.Text.h5)
                        .padding(.bottom, Theme.Spacing.small)
                    
                    Spacer()
                }
                
                NumericTextFieldWithLabel<Field>(label: "Weight \(UnitUtils.weightUnitString(um.user.profile?.preferredUnits))", placeholder: "Required", value: $viewModel.weight, focused: $focused, field: .weight)
                
                WBlobkButton("Save", imageName: "check", imagePosition: .right) {
                    Task { @MainActor in
                        if await viewModel.onSave(dm: dm) {
                            isPresented = false
                        }
                    }
                }
            }
            .card()
        }
        .sheet(isPresented: $viewModel.presentConfirmDeleteWeightLog) {
            ConfirmDeleteSheetView(isPresented: $viewModel.presentConfirmDeleteWeightLog) {
                Task { @MainActor in
                    if await viewModel.handleDeleteConfirmed(dm: dm) {
                        isPresented = false
                    }
                }
            }
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
        .onAppear {
            viewModel.onAppear(weightLog: weightLog, preferredUnits: um.user.profile?.preferredUnits)
        }
    }
}

#Preview {
    QuickEditWeightLogView(weightLog: .redacted, isPresented: .constant(true))
}

@MainActor
fileprivate class QuickEditViewModel: ObservableObject {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: QuickEditViewModel.self)
    )
    
    var weightLog: MobileWeightLog = .redacted
    var preferredUnits: MeasurementUnit? = nil
    
    @Published var presentConfirmDeleteWeightLog: Bool = false
    @Published var weight: Double? = nil
    
    func onAppear(weightLog: MobileWeightLog, preferredUnits: MeasurementUnit?) {
        self.weightLog = weightLog
        weight = UnitUtils.weightValue(weightLog.weightInKg, preferredUnits)
        self.preferredUnits = preferredUnits
    }
    
    func onPresentConfirmDeleteWeightLog() {
        presentConfirmDeleteWeightLog = true
    }
    
    func handleDeleteConfirmed(dm: DM) async -> Bool {
        do {
            try await dm.delete(weightLog: weightLog)
            return true
        } catch {
            WLogger.shared.record(error)
        }
        
        return false
    }
    
    func onSave(dm: DM) async -> Bool {
        guard let weight = weight else {
            return false
        }
        
        let newWeight: Double = preferredUnits == .metric ? weight : UnitUtils.lbToKg(weight)
        
        do {
            try await dm.update(weightLog: weightLog, weightInKg: newWeight)
            return true
        } catch {
            WLogger.shared.record(error)
        }
        
        return false
    }
}
