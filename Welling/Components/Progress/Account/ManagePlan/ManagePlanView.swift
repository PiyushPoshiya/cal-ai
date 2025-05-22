//
//  ManagePlanView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-07-19.
//

import SwiftUI
import SuperwallKit
import StoreKit

struct ManagePlanView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var um: UserManager
    
    @State var loadingSubscriptionState: Bool = true
    @State var errorLoadingStatus: Bool = false
    @State var productNameDisplay: String = ""
    @State var expirationDateDisplay: String = ""
    @State var expirationDateTitle: String = ""

    var body: some View {
        VStack (spacing: 0) {
            ZStack {
                VStack(alignment: .center) {
                    Text("Manage Plan")
                        .fontWithLineHeight(Theme.Text.h5)
                }
                HStack {
                    IconButtonView("xmark", showBackgroundColor: true) {
                        isPresented = false
                    }
                    Spacer()
                }
            }
            .navbar()
            
            VStack (spacing: 0) {
                ManagePlanRowView(title: "Status", value: Superwall.shared.subscriptionStatus.description.localizedCapitalized)
                
                if loadingSubscriptionState {
                    ProgressView()
                        .padding(.top, Theme.Spacing.large)
                } else if errorLoadingStatus {
                } else {
                    if expirationDateTitle.count > 0 {
                        ManagePlanRowView(title: expirationDateTitle, value: expirationDateDisplay)
                    }
                    if productNameDisplay.count > 0 {
                        ManagePlanRowView(title: "Plan", value: productNameDisplay)
                    }
                }
                
            }
            .card(small: true)
            .padding(.horizontal, Theme.Spacing.horizontalPadding)
            
            Text("This subscription is managed on iTunes or Apple App Store. To cancel or manage your subscription, go to your phone Settings > Apple ID > Subscriptions.")
                .fontWithLineHeight(Theme.Text.regularRegular)
                .foregroundStyle(Theme.Colors.TextNeutral05)
                .padding(.horizontal, Theme.Spacing.xxlarge)
                .padding(.vertical, Theme.Spacing.large)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            Task { @MainActor in
                await loadLatestSubscriptionInfo()
            }
        }
    }
    
    @MainActor
    func loadLatestSubscriptionInfo() async {
        do {
            let latestTransaction: StoreKit.Transaction? = await um.getLatestSubscriptionTransaction()
            
            guard let latestTransaction = latestTransaction else {
                loadingSubscriptionState = false
                return
            }
            
            let products: [StoreKit.Product] = try await StoreKit.Product.products(for: [latestTransaction.productID])
            
            if products.count != 1 {
                errorLoadingStatus = true
                loadingSubscriptionState = false
                return
            }
            
            productNameDisplay = products[0].displayPrice
            if let subscription = products[0].subscription {
                productNameDisplay += "/"
                if subscription.subscriptionPeriod.value > 1 {
                    productNameDisplay += "\(subscription.subscriptionPeriod.value) "
                }
                if let firstChar = subscription.subscriptionPeriod.unit.localizedDescription.lowercased().first {
                    productNameDisplay += String(firstChar)
                }
            }
            
            if let expirationDate = latestTransaction.expirationDate {
                expirationDateDisplay = Date.subscriptionRenewaFormatter.string(from: expirationDate)
            } else {
                expirationDateDisplay = "-"
            }
            
            let subscriptionStatus: StoreKit.Product.SubscriptionInfo.Status? = await latestTransaction.subscriptionStatus
            
            
            if let subscriptionStatus = subscriptionStatus {
                if try subscriptionStatus.renewalInfo.payloadValue.willAutoRenew {
                    expirationDateTitle = "Renewal Date"
                } else {
                   expirationDateTitle = "Valid Until"
                }
            } else {
                expirationDateTitle = "-"
            }
            loadingSubscriptionState = false
        } catch {
            WLogger.shared.record(error)
            errorLoadingStatus = true
            loadingSubscriptionState = false
        }
    }
}

struct ManagePlanRowView: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack (spacing: 0) {
            HStack {
                Text(title)
                    .fontWithLineHeight(Theme.Text.mediumSemiBold)
                    .foregroundStyle(Theme.Colors.TextNeutral9)
                Spacer()
                Text(value)
                    .fontWithLineHeight(Theme.Text.regularRegular)
                    .foregroundStyle(Theme.Colors.TextNeutral9)
                    .opacity(0.75)
            }
            .frame(height: 65)
            Divider()
                .frame(height: 1)
                .overlay(Theme.Colors.BorderNeutral05)
        }
    }
}

#Preview {
    ManagePlanView(isPresented: .constant(true))
        .environmentObject(UserManager.sample)
}
