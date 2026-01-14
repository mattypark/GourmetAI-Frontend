//
//  ChefAIApp.swift
//  ChefAI
//
//  Created by Matthew Park on 11/27/25.
//

import SwiftUI
import SuperwallKit

@main
struct ChefAIApp: App {
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    init() {
        // Initialize Superwall with your API key
        // Get your API key from: https://superwall.com/dashboard
        Superwall.configure(apiKey: "pk_l2iDq2lf10Bfq7lnjPTFE")
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
    }
}
