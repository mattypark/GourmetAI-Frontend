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
    @StateObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var welcomeOverlay = WelcomeOverlayManager.shared

    init() {
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                    checkPerUserOnboarding()
                    Task {
                        await subscriptionService.refreshStatus()
                    }
                    if HealthKitService.shared.isEnabled {
                        Task {
                            await HealthKitService.shared.refreshTodayData()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await subscriptionService.refreshStatus()
                    }
                }
                .onChange(of: supabase.isAuthenticated) { _, isAuth in
                    if isAuth {
                        checkPerUserOnboarding()
                    } else {
                        hasCompletedOnboarding = false
                    }
                }
                .onReceive(supabase.$currentUser) { user in
                    if user != nil {
                        checkPerUserOnboarding()
                    }
                }

                // Welcome gradient overlay — shown once per fresh launch for entitled users
                if welcomeOverlay.isShowingOverlay {
                    WelcomeGradientOverlayView(
                        userName: UserDefaults.standard.string(forKey: "settings.userName") ?? "Chef",
                        onDismiss: {
                            welcomeOverlay.dismiss()
                        }
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            // Trigger welcome overlay check when home becomes visible
            .onChange(of: hasCompletedOnboarding) { _, completed in
                if completed {
                    triggerWelcomeOverlayIfNeeded()
                }
            }
            .onChange(of: subscriptionService.hasAccess) { _, _ in
                triggerWelcomeOverlayIfNeeded()
            }
        }
    }

    /// Check if the current user has already completed onboarding and restore the flag
    private func checkPerUserOnboarding() {
        guard let userId = supabase.currentUser?.id.uuidString else { return }
        UserDefaults.standard.set(userId, forKey: StorageKeys.currentUserId)
        if StorageService.shared.hasCompletedOnboarding(for: userId) {
            hasCompletedOnboarding = true
        }
    }

    /// Show the welcome gradient overlay if all conditions are met
    private func triggerWelcomeOverlayIfNeeded() {
        welcomeOverlay.checkAndShow(
            isOnboarded: hasCompletedOnboarding,
            isAuthenticated: supabase.isAuthenticated,
            hasAccess: subscriptionService.hasAccess
        )
    }
}
