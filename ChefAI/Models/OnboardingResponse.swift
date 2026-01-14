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
        // After Q10 (Main Goal)
        10: OnboardingResponse(
            id: 1,
            triggerAfterQuestionId: 10,
            lines: [
                "Great choice!",
                "Did you know 73% of people want to cook more but don't know where to start?",
                "ChefAI will make it easy for you."
            ]
        ),

        // After Q13 (Skill Level)
        13: OnboardingResponse(
            id: 2,
            triggerAfterQuestionId: 13,
            lines: [
                "Perfect!",
                "We'll match recipes to your exact skill level.",
                "No more overly complicated recipes."
            ]
        ),

        // After Q17 (Time Availability)
        17: OnboardingResponse(
            id: 3,
            triggerAfterQuestionId: 17,
            lines: [
                "Time is precious!",
                "Research shows meal planning saves 3+ hours per week.",
                "We'll keep your recipes quick and delicious."
            ]
        ),

        // After Q20 (Adventure Level)
        20: OnboardingResponse(
            id: 4,
            triggerAfterQuestionId: 20,
            lines: [
                "Love it!",
                "Food is an adventure waiting to happen.",
                "Let's explore new flavors together."
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
