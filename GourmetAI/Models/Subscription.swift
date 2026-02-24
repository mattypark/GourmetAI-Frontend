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
    case weekly = "Weekly Premium"
    case monthly = "Monthly Premium"
    case yearly = "Yearly Premium"
}

// MARK: - Subscription Plan (for paywall UI)

enum SubscriptionPlan: String, CaseIterable {
    case weekly
    case monthly
    case yearly

    var displayPrice: String {
        switch self {
        case .weekly: return "$4.99"
        case .monthly: return "$9.99"
        case .yearly: return "$59.99"
        }
    }

    var period: String {
        switch self {
        case .weekly: return "/week"
        case .monthly: return "/month"
        case .yearly: return "/year"
        }
    }

    var trialText: String {
        "3-day free trial, then \(displayPrice)\(period)"
    }

    var savingsLabel: String? {
        switch self {
        case .yearly: return "BEST VALUE"
        case .monthly: return nil
        case .weekly: return nil
        }
    }
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

// MARK: - Promo Code

struct PromoCode {
    let code: String
    let type: PromoType
    let description: String

    enum PromoType {
        case lifetime           // Free forever
        case duration(days: Int) // Free for X days
        case discount(percent: Int) // % off subscription
    }

    var displayLabel: String {
        switch type {
        case .lifetime:
            return "Free Forever"
        case .duration(let days):
            return "\(days) Days Free"
        case .discount(let percent):
            return "\(percent)% Off"
        }
    }

    /// All valid promo codes. Add new creator/partner codes here.
    static let validCodes: [String: PromoCode] = [
        // Owner / developer code — free forever
        "GOURMETAI-DEV": PromoCode(
            code: "GOURMETAI-DEV",
            type: .lifetime,
            description: "Developer access"
        ),

        // Creator codes — free forever for partners
        "CREATOR2026": PromoCode(
            code: "CREATOR2026",
            type: .lifetime,
            description: "Creator partner access"
        ),

        // Beta tester code — 90 days free
        "BETA90": PromoCode(
            code: "BETA90",
            type: .duration(days: 90),
            description: "Beta tester — 90 days free"
        ),

        // Launch promo — 30 days free
        "LAUNCH30": PromoCode(
            code: "LAUNCH30",
            type: .duration(days: 30),
            description: "Launch promo — 30 days free"
        ),

        // Discount code — 50% off
        "HALF50": PromoCode(
            code: "HALF50",
            type: .discount(percent: 50),
            description: "50% off any plan"
        ),
    ]

    static func validate(_ code: String) -> PromoCode? {
        return validCodes[code.uppercased().trimmingCharacters(in: .whitespaces)]
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
