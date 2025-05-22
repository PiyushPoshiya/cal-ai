//
//  AccountView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI
import os

struct AccountView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var dm: DM
    @EnvironmentObject var um: UserManager
    @StateObject fileprivate var viewModel: AccountViewModel = AccountViewModel()
    @StateObject var modalManager: ModalManager = ModalManager()
    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    VStack(alignment: .center) {
                        Text("Account")
                            .fontWithLineHeight(Theme.Text.h5)
                    }
                    HStack {
                        IconButtonView("arrow-left-long", showBackgroundColor: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        Spacer()
                    }
                }
                .navbar()

                ScrollView {
                    VStack(spacing: Theme.Spacing.small) {
                        VStack(spacing: Theme.Spacing.medium) {
                            NavigationLink {
                                AccountProfileView()
                                    .withoutDefaultNavBar()
                            } label: {
                                AccountListItem(icon: "user", name: "Profile")
                            }

                            NavigationLink {
                                RemindersAndNotificationsView(um: um)
                                    .withoutDefaultNavBar()
                            } label: {
                                AccountListItem(icon: "bell", name: "Reminders & Notifications")
                            }
                        }
                        .accountListSection()

                        VStack(spacing: Theme.Spacing.medium) {

                            Button {
                                viewModel.presentSupportSheet = true
                            } label: {
                                AccountListItem(icon: "chat-lines", name: "Support")
                            }

                            Button {
                                viewModel.presentManagePlanSheet = true
                            } label: {
                                AccountListItem(icon: "mastercard-card", name: "Manage Plan")
                            }

                            Button {
                                viewModel.onTapSignOut()
                            } label: {
                                HStack(spacing: Theme.Spacing.medium) {
                                    ColoredIconView(imageName: "log-out")
                                    Text("Sign Out")
                                        .fontWithLineHeight(Theme.Text.mediumMedium)
                                    Spacer()
                                    ColoredIconView(imageName: "running")
                                }
                                .accountListItem()
                            }
                        }
                        .accountListSection()

                        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                            Button {
                                viewModel.onDeleteAccountTapped()
                            } label: {
                                Text("Delete Account")
                                    .fontWithLineHeight(Theme.Text.smallRegular)
                            }
                            Button {
                            } label: {
                                Text("Terms and Policies")
                                    .fontWithLineHeight(Theme.Text.smallRegular)
                            }
                            Button {
                            } label: {
                                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")")
                                    .fontWithLineHeight(Theme.Text.smallRegular)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Theme.Colors.TextNeutral3)
                        .padding(.vertical, Theme.Spacing.medium)
                        .padding(.horizontal, Theme.Spacing.large)
                    }
                    .padding(.horizontal, Theme.Spacing.horizontalPadding)
                }
            }

            ModalManagerView()
                .environmentObject(modalManager)
        }
        .background(Theme.Colors.SurfaceNeutral05)
        .sheet(isPresented: $viewModel.presentSupportSheet) {
            AccountSupportView(isPresented: $viewModel.presentSupportSheet)
                .modifier(GetHeightModifier(height: $sheetHeight))
                .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $viewModel.presentManagePlanSheet) {
            ManagePlanView(isPresented: $viewModel.presentManagePlanSheet)
                .modifier(GetHeightModifier(height: $sheetHeight))
                .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $viewModel.presentConfirmSignOutModal) {
            ConfirmSignOutSheetView(isPresented: $viewModel.presentConfirmSignOutModal) {
                viewModel.onSignOutConfirmed()
            }
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $viewModel.presentConfirmDeleteAccountModal) {
            ConfirmDeleteAccountSheetView(isPresented: $viewModel.presentConfirmDeleteAccountModal) {
                Task { @MainActor in
                    await viewModel.onDeleteAccountConfirmed()
                }
            }
            .modifier(GetHeightModifier(height: $sheetHeight))
            .presentationDetents([.height(sheetHeight)])
        }
        .sheet(isPresented: $viewModel.presentReauthenticateSheet) {
            ZStack {
                SignInView(titleMessage: "Please re-authenticate to delete your account.", mode: .reauthenticate, onLoginCompleted: viewModel.onReauthenticationCompleted)
                ModalManagerView()
            }
            .environmentObject(modalManager)
            .presentationDetents([.large])
        }
        .onAppear {
            viewModel.onAppear(dm: dm, um: um, modalManager: modalManager)
        }
    }
}


#Preview {
    AccountView()
        .foregroundStyle(Theme.Colors.TextNeutral9)
        .environmentObject(UserManager.sample)
}

@MainActor
fileprivate class AccountViewModel: ObservableObject {
    static let loggerCategory = String(describing: AccountViewModel.self)
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: loggerCategory
    )

    var um: UserManager = .notLoggedIn
    var dm: DM?
    var modalManager: ModalManager = .empty

    @Published public var presentConfirmSignOutModal: Bool = false
    @Published public var presentConfirmDeleteAccountModal: Bool = false
    @Published public var presentReauthenticateSheet: Bool = false
    @Published public var presentSupportSheet: Bool = false
    @Published public var presentManagePlanSheet: Bool = false
    @Published public var deleteCancelled: Bool = false

    func onAppear(dm: DM, um: UserManager, modalManager: ModalManager) {
        self.dm = dm
        self.um = um
        self.modalManager = modalManager
    }

    func onBackTapped() {

    }

    func onTapSignOut() {
        self.presentConfirmSignOutModal = true
    }

    func onSignOutConfirmed() {
        do {
            try um.logout()
            presentConfirmSignOutModal = false
        } catch {
            Self.logger.error("Error trying to sign out: \(error)")
        }
    }

    func onDeleteAccountTapped() {
        self.deleteCancelled = false
        self.presentConfirmDeleteAccountModal = true
    }

    @MainActor
    func onDeleteAccountConfirmed() async {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
        presentConfirmDeleteAccountModal = false
        presentReauthenticateSheet = true
    }

    @MainActor
    func reAuthenticationManuallyClosed() {
        self.modalManager.hideLoadingModal()
        self.deleteCancelled = true
    }

    func onReauthenticationCompleted(success: Bool) {
        WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")

        if !success || self.deleteCancelled {
            Task { @MainActor in
                presentReauthenticateSheet = false
                self.modalManager.hideLoadingModal()
            }
            return
        }

        Task { @MainActor in
            WLogger.shared.log(Self.loggerCategory, "\(#function):\(#line)")
            presentReauthenticateSheet = false

            if self.deleteCancelled {
                self.modalManager.hideLoadingModal()
                return
            }

            self.modalManager.showLoadingModal()

            var deleted: Bool = false
            do {
                deleted = try await self.um.deleteUser()
                if let dm = self.dm {
                    try await dm.clearRealm()
                }
            } catch {
                WLogger.shared.record(error)
            }

            self.modalManager.hideLoadingModal()

            if deleted {
                return
            }

            self.modalManager.showErrorModal(title: "Something Went Wrong", message: "Sorry, something went wrong trying to delete your account. Please try agian later or email support@welling.ai to delete your account.")
        }
    }

    func onTermsAndPoliciesTapped() {

    }
}
