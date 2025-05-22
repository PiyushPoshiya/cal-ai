//
//  AccountListItem.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

struct AccountListItem: View {
    var icon: String
    var name: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ColoredIconView(imageName: icon)
            Text(name)
                .fontWithLineHeight(Theme.Text.mediumMedium)
            Spacer()
            ColoredIconView(imageName: "nav-arrow-right")
        }
        .accountListItem()
    }
}

#Preview {
    VStack {
        AccountListItem(icon: "user", name: "Profile")
    }
    .accountListSection()
}
