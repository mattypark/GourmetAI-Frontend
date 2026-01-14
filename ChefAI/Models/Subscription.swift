//
//  Subscription.swift
//  ChefAI
//
//  Subscription models for managing free trial and premium tiers
//

import Foundation

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable {
    case free = "Free Trial"
    case monthly = "Monthly Premium"
    case yearly = "Yearly Premium"
}

// MARK: - Subscription Model

struct Subscription: Codable {
    var tier: SubscriptionTier
    var startDate: Date
    var expiryDate: Date?
    var isActive: Bool
    var trialEndDate: Date?

    /// Check if user is currently in trial period
    var isInTrial: Bool {
        guard let trialEnd = trialEndDate else { return false }
        return Date() < trialEnd && isActive
    }

    /// Calculate days remaining in trial
    var daysRemainingInTrial: Int {
        guard let trialEnd = trialEndDate else { return 0 }
        let components = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd)
        return max(0, components.day ?? 0)
    }

    /// Check if subscription has expired
    var hasExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return Date() > expiry
    }

    /// Create a new 3-day free trial subscription
    static func createFreeTrial() -> Subscription {
        let now = Date()
        let trialEnd = Calendar.current.date(byAdding: .day, value: 3, to: now)!

        return Subscription(
            tier: .free,
            startDate: now,
            expiryDate: trialEnd,
            isActive: true,
            trialEndDate: trialEnd
        )
    }

    /// Create a monthly subscription
    static func createMonthly(startDate: Date = Date()) -> Subscription {
        let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)

        return Subscription(
            tier: .monthly,
            startDate: startDate,
            expiryDate: expiryDate,
            isActive: true,
            trialEndDate: nil
        )
    }

    /// Create a yearly subscription
    static func createYearly(startDate: Date = Date()) -> Subscription {
        let expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)

        return Subscription(
            tier: .yearly,
            startDate: startDate,
            expiryDate: expiryDate,
            isActive: true,
            trialEndDate: nil
        )
    }
}

// MARK: - Premium Features

enum PremiumFeature: String, CaseIterable {
    case unlimitedRecipes = "Unlimited recipe generations"
    case mealPlanning = "Meal planning & calendar"
    case shoppingLists = "Smart shopping lists"
    case nutritionTracking = "Nutrition tracking"
    case advancedFilters = "Advanced recipe filters"
    case adFree = "Ad-free experience"
    case prioritySupport = "Priority customer support"
    case offlineMode = "Offline recipe access"

    var icon: String {
        switch self {
        case .unlimitedRecipes: return "infinity.circle.fill"
        case .mealPlanning: return "calendar.circle.fill"
        case .shoppingLists: return "list.bullet.circle.fill"
        case .nutritionTracking: return "chart.bar.fill"
        case .advancedFilters: return "slider.horizontal.3"
        case .adFree: return "eye.slash.fill"
        case .prioritySupport: return "person.fill.checkmark"
        case .offlineMode: return "arrow.down.circle.fill"
        }
    }

    var description: String {
        return self.rawValue
    }
}
