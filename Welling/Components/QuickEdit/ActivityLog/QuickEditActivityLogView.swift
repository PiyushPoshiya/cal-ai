//
//  QuickEditActivityLogView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-21.
//

import SwiftUI
import RealmSwift
import os
import Mixpanel

fileprivate enum Field: Hashable, Equatable {
    case burnedCalories
}

struct QuickEditActivityLogView: View {
    @EnvironmentObject var dm: DM
    @State private var sheetHeight: CGFloat = .zero
    @StateObject var viewModel: QuickEditActivityViewModel = QuickEditActivityViewModel()
    
    @Binding var activityLog: MobilePhysicalActivityLog
    @Binding var isPresented: Bool
    @FocusState private var focused: Field?
    var onUpdated: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            HStack {
                IconButtonView("xmark", showBackgroundColor: true) {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"xmark", "screen":"QuickEditActivityLogView"])
                    isPresented = false
                }
                Spacer()
                TextButtonView("Delete") {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Delete", "screen":"QuickEditActivityLogView"])
                    viewModel.onPresentConfirmDeleteActivityLog()
                }
            }
            .sheetNavbar()
            
            VStack(spacing: Theme.Spacing.large) {
                HStack {
                    Text("\(activityLog.name), \(activityLog.amount)")
                        .fontWithLineHeight(Theme.Text.h5)
                        .padding(.bottom, Theme.Spacing.small)
                    
                    Spacer()
                }
                
                NumericTextFieldWithLabel<Field>(label: "Burned Calories", placeholder: "Required", value: $viewModel.caloriesExpended, focused: $focused, field: .burnedCalories)
                
                WBlobkButton("Save", imageName: "check", imagePosition: .right) {
                    Mixpanel.mainInstance().track(event: "User Tapped Button", properties: ["button":"Save", "screen":"QuickEditActivityLogView"])
                    Task { @MainActor in
                        if await viewModel.onSave(dm: dm) {
                            if let onUpdated = onUpdated {
                                onUpdated()
                            }
                            isPresented = false
                        }
                    }
                }
            }
            .card()
        }
        .sheet(isPresented: $viewModel.presentConfirmDeleteActivityLog) {
            ConfirmDeleteSheetView(isPresented: $viewModel.presentConfirmDeleteActivityLog) {
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
            viewModel.onAppear(activityLog: activityLog)
        }
    }
}

#Preview {
    QuickEditActivityLogView(activityLog: .constant(.sample), isPresented: .constant(true))
        .environmentObject(DM.init())
}

@MainActor
class QuickEditActivityViewModel: ObservableObject {
    static let loggerCategory =  String(describing: QuickEditActivityViewModel.self)
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )
    
    var activityLog: MobilePhysicalActivityLog = .redacted
    
    @Published var presentConfirmDeleteActivityLog: Bool = false
    @Published var caloriesExpended: Double? = nil
    
    func onAppear(activityLog: MobilePhysicalActivityLog) {
        self.activityLog = activityLog
        caloriesExpended = activityLog.caloriesExpended
    }
    
    func onPresentConfirmDeleteActivityLog() {
        presentConfirmDeleteActivityLog = true
    }
    
    func handleDeleteConfirmed(dm: DM) async -> Bool {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        do {
            try await dm.delete(activityLog: activityLog)
            return true
        } catch {
            WLogger.shared.record(error)
        }
        
        return false
    }
    
    func onSave(dm: DM) async -> Bool {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        
        guard let caloriesExpended = caloriesExpended else {
            return false
        }
        
        do {
            try await dm.update(activityLog: activityLog, caloriesExpended: caloriesExpended)
            return true
        } catch {
            WLogger.shared.record(error)
        }
        
        return false
    }
}
