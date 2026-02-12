//
//  ChefAIApp.swift
//  ChefAI
//
//  Created by Matthew Park on 11/27/25.
//

import SwiftUI
import GoogleSignIn
import Auth
// TODO: Add SuperwallKit package in Xcode before uncommenting
// import SuperwallKit

@main
struct ChefAIApp: App {
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false
    @StateObject private var supabase = SupabaseManager.shared

    init() {
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
            .onAppear {
                // On launch, if user has a persisted session, check per-user onboarding flag
                // (covers case where global flag was cleared but per-user flag persists)
                if let userId = supabase.currentUser?.id.uuidString {
                    UserDefaults.standard.set(userId, forKey: StorageKeys.currentUserId)
                    if StorageService.shared.hasCompletedOnboarding(for: userId) {
                        hasCompletedOnboarding = true
                    }
                }
            }
            .onChange(of: supabase.isAuthenticated) { _, isAuth in
                if isAuth, let userId = supabase.currentUser?.id.uuidString {
                    // User just logged in — check if they've already completed onboarding
                    UserDefaults.standard.set(userId, forKey: StorageKeys.currentUserId)
                    if StorageService.shared.hasCompletedOnboarding(for: userId) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}
