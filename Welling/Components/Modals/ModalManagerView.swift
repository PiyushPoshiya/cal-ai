//
//  ModalManagerView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-14.
//

import PopupView
import SwiftUI

struct ModalManagerView: View {
    @EnvironmentObject var modalManager: ModalManager

    var body: some View {
        ZStack {
            if modalManager.presentLoadingModal {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
            }
        }
        .popup(
            isPresented: $modalManager.presentErrorToast
        ) {
            ErrorToastView(title: $modalManager.errorToastTitle, message: $modalManager.errorToastMessage)
        } customize: {
            $0.type(.floater())
                .position(.top)
                .animation(.default)
                .closeOnTapOutside(true)
        }
        .alert(modalManager.alertModalTitle, isPresented: $modalManager.presentAlertModal) {
            Button("OK", role: .cancel) {
                modalManager.hideAlertModal()
            }
        }
        .alert(modalManager.errorModalTitle, isPresented: $modalManager.presentErrorModal) {
            Button(role: .none) {
                modalManager.hideErrorModal()
            } label: {
                Text("Ok")
            }
        } message: {
            Text(modalManager.errorModalMessage)
        }
        .alert(modalManager.confirmModalTitle, isPresented: $modalManager.presentConfirmModal) {
            Button(modalManager.confirmModalCancelButtonText) {
                modalManager.hideConfirmModal(confirm: false)
            }
            Button(role: modalManager.confirmModalConfirmButtonRole) {
                modalManager.hideConfirmModal(confirm: true)
            } label: {
                Text(modalManager.confirmModalConfirmButtonText)
            }
        } message: {
            Text(modalManager.confirmModalMessage)
        }
    }
}

struct ModalManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            VStack {
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .background(.white)

            ModalManagerView()
                .environmentObject(ModalManager.empty)
        }
    }
}
