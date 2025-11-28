//
//  OnboardingQuestion.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

struct OnboardingQuestion: Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let type: QuestionType

    enum QuestionType {
        case singleChoice([String])
        case multipleChoice([String])
        case custom
    }
}
