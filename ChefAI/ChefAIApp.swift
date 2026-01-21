//
//  ChefAIApp.swift
//  ChefAI
//
//  Created by Matthew Park on 11/27/25.
//

import SwiftUI
import GoogleSignIn
// TODO: Add SuperwallKit package in Xcode before uncommenting
// import SuperwallKit

@main
struct ChefAIApp: App {
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    init() {
        // Initialize Superwall with your API key
        // Get your API key from: https://superwall.com/dashboard
        // TODO: Uncomment after adding SuperwallKit package
        // Superwall.configure(apiKey: "pk_l2iDq2lf10Bfq7lnjPTFE")

        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingFlowView()
                }
            }
            .onOpenURL { url in
                // Handle Google Sign-In callback
                GIDSignIn.sharedInstance.handle(url)

                // Handle Supabase OAuth callback
                Task {
                    await SupabaseManager.shared.handleOAuthCallback(url: url)
                }
            }
        }
    }
}
