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
    let isOptional: Bool

    init(id: Int, title: String, subtitle: String? = nil, type: QuestionType, isOptional: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.isOptional = isOptional
    }

    enum QuestionType {
        case singleChoice([String])
        case multipleChoice([String])
        case textInput(placeholder: String)
        case physicalStats  // Combined weight, height, age pickers (legacy)
        case agePicker  // Age only picker
        case weightHeightPicker  // Weight and height pickers combined
        case organicOrProcessed  // Special organic vs processed question
        case daysPerWeek  // 0-7 days picker
        case custom  // For summary page
    }
}
