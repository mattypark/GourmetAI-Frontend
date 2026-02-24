//
//  StorageKeys.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

struct StorageKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userProfileKey = "userProfile"
    static let currentUserId = "currentUserId"

    /// Per-user onboarding key: "onboarding_complete_<userId>"
    static func onboardingKey(for userId: String) -> String {
        "onboarding_complete_\(userId)"
    }

    static let subscriptionCache = "subscriptionCache"
    static let freeTrialExpiry = "freeTrialExpiry"
    static let appliedPromoCode = "appliedPromoCode"
    static let promoCodeExpiry = "promoCodeExpiry"

    // HealthKit settings
    static let healthKitEnabled = "healthKit.enabled"
    static let healthKitSendCalories = "healthKit.sendCalories"
    static let healthKitSendMacros = "healthKit.sendMacros"
    static let healthKitReadBurnedCalories = "healthKit.readBurnedCalories"
    static let healthKitReadRestingEnergy = "healthKit.readRestingEnergy"
    static let healthKitReadSteps = "healthKit.readSteps"
    static let healthKitReadWorkouts = "healthKit.readWorkouts"
    static let healthKitOnboardingChoice = "healthKit.onboardingChoice"

    // Nutrition goals
    static let nutritionGoalCalories = "nutrition.goalCalories"
    static let nutritionGoalProteinPercent = "nutrition.goalProteinPercent"
    static let nutritionGoalCarbsPercent = "nutrition.goalCarbsPercent"
    static let nutritionGoalFatPercent = "nutrition.goalFatPercent"
}
