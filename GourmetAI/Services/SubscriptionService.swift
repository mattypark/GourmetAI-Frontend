//
//  SubscriptionService.swift
//  ChefAI
//
//  Service for managing subscription state and feature gating.
//  Checks Supabase for active subscriptions and free trials.
//

import Foundation
import Combine

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var hasAccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentPlan: String? = nil
    @Published var isTrialing: Bool = false
    @Published var appliedPromoCode: String? = nil

    private let userDefaults = UserDefaults.standard

    private init() {
        // Load cached state for instant UI
        loadCachedStatus()
    }

    // MARK: - Refresh from Supabase

    /// Refresh subscription status by checking the backend (which queries Supabase)
    func refreshStatus() async {
        // Promo code grants access locally — no backend call needed
        if hasActivePromoCode() {
            hasAccess = true
            return
        }

        guard let userId = UserDefaults.standard.string(forKey: StorageKeys.currentUserId) else {
            hasAccess = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let status = try await APIClient.shared.getSubscriptionStatus(userId: userId)
            hasAccess = status.hasActiveSubscription
            currentPlan = status.plan
            isTrialing = status.isTrialing

            // Cache locally
            userDefaults.set(status.hasActiveSubscription, forKey: StorageKeys.subscriptionCache)

            // Cache free trial expiry if present
            if let expiresAt = status.freeTrialExpiresAt {
                userDefaults.set(expiresAt, forKey: StorageKeys.freeTrialExpiry)
            }
        } catch {
            #if DEBUG
            print("Failed to refresh subscription status: \(error.localizedDescription)")
            #endif
            // Fall back to cached value
            loadCachedStatus()
        }
    }

    // MARK: - Promo Code

    /// Apply a promo code and grant access accordingly
    func applyPromoCode(_ code: String) -> (success: Bool, message: String) {
        guard let promo = PromoCode.validate(code) else {
            return (false, "Invalid promo code")
        }

        // Store the applied code
        userDefaults.set(promo.code, forKey: StorageKeys.appliedPromoCode)
        appliedPromoCode = promo.code

        switch promo.type {
        case .lifetime:
            // No expiry — free forever
            userDefaults.removeObject(forKey: StorageKeys.promoCodeExpiry)
            userDefaults.set(true, forKey: StorageKeys.subscriptionCache)
            hasAccess = true
            currentPlan = "Promo — \(promo.description)"
            return (true, "Code applied! You have free access forever.")

        case .duration(let days):
            let expiry = Calendar.current.date(byAdding: .day, value: days, to: Date())!
            let formatter = ISO8601DateFormatter()
            userDefaults.set(formatter.string(from: expiry), forKey: StorageKeys.promoCodeExpiry)
            userDefaults.set(true, forKey: StorageKeys.subscriptionCache)
            hasAccess = true
            currentPlan = "Promo — \(promo.description)"
            return (true, "Code applied! You have \(days) days of free access.")

        case .discount:
            // Discount codes don't grant immediate access — they apply at checkout
            return (true, "Discount code applied! It will be applied at checkout.")
        }
    }

    /// Check if user has an active (non-expired) promo code
    func hasActivePromoCode() -> Bool {
        guard let code = userDefaults.string(forKey: StorageKeys.appliedPromoCode),
              let promo = PromoCode.validate(code) else {
            return false
        }

        switch promo.type {
        case .lifetime:
            return true
        case .duration:
            if let expiryString = userDefaults.string(forKey: StorageKeys.promoCodeExpiry) {
                let formatter = ISO8601DateFormatter()
                if let expiryDate = formatter.date(from: expiryString) {
                    return Date() < expiryDate
                }
            }
            return false
        case .discount:
            return false // Discounts don't grant direct access
        }
    }

    /// Get the currently applied discount percentage (for checkout), or nil
    func activeDiscountPercent() -> Int? {
        guard let code = userDefaults.string(forKey: StorageKeys.appliedPromoCode),
              let promo = PromoCode.validate(code) else {
            return nil
        }
        if case .discount(let percent) = promo.type {
            return percent
        }
        return nil
    }

    // MARK: - Local Cache

    private func loadCachedStatus() {
        // Check promo code first
        if hasActivePromoCode() {
            hasAccess = true
            appliedPromoCode = userDefaults.string(forKey: StorageKeys.appliedPromoCode)
            if let code = appliedPromoCode, let promo = PromoCode.validate(code) {
                currentPlan = "Promo — \(promo.description)"
            }
            return
        }

        let cached = userDefaults.bool(forKey: StorageKeys.subscriptionCache)

        // Also check local free trial expiry
        if let expiryString = userDefaults.string(forKey: StorageKeys.freeTrialExpiry) {
            let formatter = ISO8601DateFormatter()
            if let expiryDate = formatter.date(from: expiryString), Date() < expiryDate {
                hasAccess = true
                return
            }
        }

        hasAccess = cached
    }

    // MARK: - Feature Gating

    func canAccessPremiumFeature(_ feature: PremiumFeature) -> Bool {
        return hasAccess
    }

    var canUploadImages: Bool { hasAccess }
    var canAccessMealPlanning: Bool { hasAccess }
    var canExportShoppingLists: Bool { hasAccess }
    var canTrackNutrition: Bool { hasAccess }

    // MARK: - Status Display

    func getSubscriptionStatusSummary() -> String {
        if !hasAccess {
            return "No active subscription"
        }
        if appliedPromoCode != nil, let plan = currentPlan {
            return plan
        }
        if isTrialing {
            return "Free Trial"
        }
        if let plan = currentPlan {
            return "\(plan.capitalized) Premium"
        }
        return "Active"
    }

    // MARK: - Clear (for logout)

    func clearSubscription() {
        hasAccess = false
        currentPlan = nil
        isTrialing = false
        appliedPromoCode = nil
        userDefaults.removeObject(forKey: StorageKeys.subscriptionCache)
        userDefaults.removeObject(forKey: StorageKeys.freeTrialExpiry)
        userDefaults.removeObject(forKey: StorageKeys.appliedPromoCode)
        userDefaults.removeObject(forKey: StorageKeys.promoCodeExpiry)
    }
}
