//
//  LoadMoreView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-26.
//

import SwiftUI

struct LoadMoreView: View {
    @Binding var isLoading: Bool
    
    var body: some View {
        ProgressView()
            .opacity(isLoading ? 100 : 0)
    }
}

