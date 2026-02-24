//
//  OnboardingResponse.swift
//  ChefAI
//
//  Data model for personalized response screens shown after specific onboarding questions.
//

import Foundation

struct OnboardingResponse: Identifiable {
    let id: Int
    let triggerAfterQuestionId: Int
    let lines: [String]  // Lines that fade in sequentially

    init(id: Int, triggerAfterQuestionId: Int, lines: [String]) {
        self.id = id
        self.triggerAfterQuestionId = triggerAfterQuestionId
        self.lines = lines
    }
}

// MARK: - Response Configurations

extension OnboardingResponse {
    /// Dictionary mapping question IDs to their responses
    /// Add/remove entries here to control which questions show response screens
    static let responses: [Int: OnboardingResponse] = [
        // After Q6 (Activity Level)
        6: OnboardingResponse(
            id: 1,
            triggerAfterQuestionId: 6,
            lines: [
                "Great!",
                "We'll use your activity level to personalize your calorie and nutrition goals.",
                "Let's learn about your cooking habits next."
            ]
        ),

        // After Q9 (Time Availability)
        9: OnboardingResponse(
            id: 2,
            triggerAfterQuestionId: 9,
            lines: [
                "Time is precious!",
                "Research shows meal planning saves 3+ hours per week.",
                "We'll keep your recipes quick and delicious."
            ]
        ),

        // After Q11 (Adventure Level)
        11: OnboardingResponse(
            id: 3,
            triggerAfterQuestionId: 11,
            lines: [
                "Love it!",
                "Food is an adventure waiting to happen.",
                "Let's explore new flavors together."
            ]
        ),

        // After Q14 (Health Improvement Goals)
        14: OnboardingResponse(
            id: 4,
            triggerAfterQuestionId: 14,
            lines: [
                "You're almost there!",
                "We're building your personalized plan right now.",
                "Just one more question..."
            ]
        ),

        // After Q16 (Apple Health)
        16: OnboardingResponse(
            id: 5,
            triggerAfterQuestionId: 16,
            lines: [
                "Great choice!",
                "We'll use your health data to personalize your calorie and nutrition goals.",
                "Now let's learn about your cooking habits."
            ]
        )
    ]

    /// Check if a response should be shown after a given question
    static func shouldShowResponse(afterQuestionId questionId: Int) -> Bool {
        return responses[questionId] != nil
    }

    /// Get the response for a given question ID
    static func getResponse(forQuestionId questionId: Int) -> OnboardingResponse? {
        return responses[questionId]
    }
}
