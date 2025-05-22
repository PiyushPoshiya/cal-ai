//
//  ModalManager.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-12.
//

import Foundation
import SwiftUI

class ModalManager: ObservableObject {
    static let empty: ModalManager = .init()

    @Published public var showModal: Bool = false
    @Published public var presentLoadingModal: Bool = false
    @Published public var presentErrorToast: Bool = false
    @Published public var presentErrorModal: Bool = false
    @Published public var presentConfirmModal: Bool = false
    @Published public var presentAlertModal: Bool = false

    @Published var errorToastTitle: String = "Toast Error"
    @Published var errorToastMessage: String = "Toast error message"

    @Published public var errorModalTitle: String = "Error"
    @Published public var errorModalMessage: String = "There was a problem"
    private var onErrorClose: () -> Void = {}

    @Published public var confirmModalTitle: LocalizedStringKey = "Are you sure?"
    @Published public var confirmModalMessage: LocalizedStringKey = ""
    @Published public var confirmModalConfirmButtonText: LocalizedStringKey = "Ok"
    @Published public var confirmModalCancelButtonText: LocalizedStringKey = "Cancel"
    @Published public var confirmModalConfirmButtonRole: ButtonRole? = .cancel
    private var onConfirmClose: ((_ confirm: Bool) -> Void)?
    
    @Published var alertModalTitle: LocalizedStringKey = "Hello"

    init() {}

    init(showModal: Bool) {
        self.showModal = showModal
    }

    @MainActor
    func showLoadingModal() {
        showModal = true
        presentLoadingModal = true
        presentErrorModal = false
        presentConfirmModal = false
        presentErrorToast = false
        presentAlertModal = false
    }

    @MainActor
    func hideLoadingModal() {
        showModal = false
        presentLoadingModal = false
    }

    @MainActor
    func showErrorModal(title: String, message: String, onClose: @escaping () -> Void = {}) {
        errorModalTitle = title
        errorModalMessage = message
        showModal = true
        onErrorClose = onClose
        presentLoadingModal = false
        presentErrorModal = true
        presentConfirmModal = false
        presentErrorToast = false
        presentAlertModal = false
    }

    @MainActor
    func hideErrorModal() {
        showModal = false
        presentErrorModal = false
        onErrorClose()
    }

    @MainActor
    func showConfirmModal(title: LocalizedStringKey, message: LocalizedStringKey, confirmButtonText: LocalizedStringKey = "Ok", cancelButtonText: LocalizedStringKey = "Cancel", isDangerous: Bool = false, onConfirmClose: @escaping (_ confirm: Bool) -> Void) {
        confirmModalTitle = title
        confirmModalMessage = message
        confirmModalConfirmButtonText = confirmButtonText
        confirmModalCancelButtonText = cancelButtonText
        confirmModalConfirmButtonRole = isDangerous ? ButtonRole.destructive : ButtonRole.cancel
        showModal = true
        self.onConfirmClose = onConfirmClose
        presentLoadingModal = false
        presentErrorModal = false
        presentConfirmModal = true
        presentErrorToast = false
        presentAlertModal = false
    }

    @MainActor
    func showErrorToast(title: String, message: String) {
        errorToastTitle = title
        errorToastMessage = message
        showModal = true
        presentLoadingModal = false
        presentErrorModal = false
        presentConfirmModal = false
        presentAlertModal = false
        presentErrorToast = true
    }

    @MainActor
    func hideConfirmModal(confirm: Bool) {
        showModal = false
        presentConfirmModal = false
        if let onConfirmClose = onConfirmClose {
            onConfirmClose(confirm)
        }
    }
    
    @MainActor
    func showAlertModal(title: LocalizedStringKey) {
        alertModalTitle = title
        presentAlertModal = true
    }
    
    @MainActor
    func hideAlertModal() {
        presentAlertModal = false
    }
}
