//
//  SubscriptionService.swift
//  ChefAI
//
//  Service for managing subscription state and feature gating
//

import Foundation

final class SubscriptionService {
    static let shared = SubscriptionService()

    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "userSubscription"

    private init() {}

    // MARK: - Subscription Management

    /// Save subscription to local storage
    func saveSubscription(_ subscription: Subscription) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let encoded = try? encoder.encode(subscription) {
            userDefaults.set(encoded, forKey: subscriptionKey)
            print("✅ Subscription saved: \(subscription.tier.rawValue)")
        }
    }

    /// Load subscription from local storage
    func loadSubscription() -> Subscription? {
        guard let data = userDefaults.data(forKey: subscriptionKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(Subscription.self, from: data)
    }

    /// Check if user has an active subscription (including free trial)
    func hasActiveSubscription() -> Bool {
        guard let subscription = loadSubscription() else {
            return false
        }

        // Check if subscription is active and not expired
        guard subscription.isActive else {
            return false
        }

        // Check expiry date
        if let expiry = subscription.expiryDate {
            return Date() < expiry
        }

        // No expiry date means lifetime subscription
        return true
    }

    /// Check if user is currently in trial period
    func isInTrial() -> Bool {
        guard let subscription = loadSubscription() else {
            return false
        }

        return subscription.isInTrial
    }

    /// Get days remaining in trial
    func daysRemainingInTrial() -> Int {
        guard let subscription = loadSubscription() else {
            return 0
        }

        return subscription.daysRemainingInTrial
    }

    /// Check if user can access a specific premium feature
    func canAccessPremiumFeature(_ feature: PremiumFeature) -> Bool {
        return hasActiveSubscription()
    }

    /// Start a 3-day free trial
    func startFreeTrial() {
        let trial = Subscription.createFreeTrial()
        saveSubscription(trial)
        print("🎉 Free trial started! Expires: \(trial.expiryDate!)")
    }

    /// Activate a monthly subscription
    func activateMonthlySubscription() {
        let monthly = Subscription.createMonthly()
        saveSubscription(monthly)
        print("✅ Monthly subscription activated!")
    }

    /// Activate a yearly subscription
    func activateYearlySubscription() {
        let yearly = Subscription.createYearly()
        saveSubscription(yearly)
        print("✅ Yearly subscription activated!")
    }

    /// Cancel current subscription
    func cancelSubscription() {
        guard var subscription = loadSubscription() else {
            return
        }

        subscription.isActive = false
        saveSubscription(subscription)
        print("❌ Subscription cancelled")
    }

    /// Clear subscription data (for testing/logout)
    func clearSubscription() {
        userDefaults.removeObject(forKey: subscriptionKey)
        print("🗑️ Subscription data cleared")
    }

    /// Restore previous purchases
    func restorePurchases() {
        // TODO: Implement actual StoreKit restore purchases logic
        // For now, just print a message - this would normally call StoreKit
        print("🔄 Restoring purchases...")
        // In a real implementation:
        // Task {
        //     try await AppStore.sync()
        //     // Check for active subscriptions and restore them
        // }
    }

    // MARK: - Feature Gating Helpers

    /// Check if user can upload images for recipe generation
    var canUploadImages: Bool {
        return hasActiveSubscription()
    }

    /// Check if user can access meal planning
    var canAccessMealPlanning: Bool {
        return hasActiveSubscription()
    }

    /// Check if user can export shopping lists
    var canExportShoppingLists: Bool {
        return hasActiveSubscription()
    }

    /// Check if user can track nutrition
    var canTrackNutrition: Bool {
        return hasActiveSubscription()
    }

    /// Get subscription status summary for display
    func getSubscriptionStatusSummary() -> String {
        guard let subscription = loadSubscription() else {
            return "No active subscription"
        }

        if subscription.isInTrial {
            let daysLeft = subscription.daysRemainingInTrial
            return "Free Trial - \(daysLeft) day\(daysLeft == 1 ? "" : "s") remaining"
        }

        switch subscription.tier {
        case .free:
            return "Free Trial"
        case .monthly:
            return "Monthly Premium"
        case .yearly:
            return "Yearly Premium"
        }
    }
}
