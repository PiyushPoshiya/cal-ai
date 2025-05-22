//
//  ConversationImageView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-06-17.
//

import SwiftUI
import os
import NukeUI

struct ConversationImageView: View {
    @Binding var image: MobileMessageImage
    
    var body: some View {
        HStack {
            MobileMessageImageView(image: $image)
        }
        .frame(width: 270, height: 324)
        .background(Theme.Colors.SurfaceNeutral3)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }
}
