//
//  HomeView.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-14.
//

import SwiftUI

enum HomeViewScreen: Equatable {
    case stats
    case chat
}

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        ConversationScreen()
            .id(HomeViewScreen.chat)
            .onAppear {
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { _, _ in }
                )
            }
    }
}


#Preview {
    HomeView()
}
