//
//  AccountViewExtensions.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-25.
//

import SwiftUI

extension View {
    func accountListSection() -> some View {
        return self
            .padding(.horizontal, Theme.Spacing.xlarge)
            .padding(.vertical, Theme.Spacing.xlarge)
            .background(Theme.Colors.SurfacePrimary100)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xlarge))
    }
    
    func accountListItem() -> some View {
        return self
            .padding(.horizontal, 0)
            .padding(.vertical, Theme.Spacing.xsmall)
    }
}
