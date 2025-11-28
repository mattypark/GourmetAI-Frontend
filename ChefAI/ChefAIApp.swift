//
//  ChefAIApp.swift
//  ChefAI
//
//  Created by Matthew Park on 11/27/25.
//

import SwiftUI

@main
struct ChefAIApp: App {
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
    }
}
