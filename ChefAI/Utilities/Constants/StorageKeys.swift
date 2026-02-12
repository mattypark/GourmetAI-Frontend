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
}
