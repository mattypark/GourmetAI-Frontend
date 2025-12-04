//
//  Recipe.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

// MARK: - Recipe Model

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var instructions: [String]
    var detailedSteps: [RecipeStep]
    var ingredients: [RecipeIngredient]
    var imageURL: String?
    var savedImageData: Data?
    var isLiked: Bool
    var tags: [String]
    var prepTime: Int?
    var cookTime: Int?
    var servings: Int?
    var difficulty: DifficultyLevel?
    var cuisineType: String?
    var nutritionPerServing: NutritionInfo?
    var tips: [String]
    var source: RecipeSource?
    var dateGenerated: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        instructions: [String] = [],
        detailedSteps: [RecipeStep] = [],
        ingredients: [RecipeIngredient] = [],
        imageURL: String? = nil,
        savedImageData: Data? = nil,
        isLiked: Bool = false,
        tags: [String] = [],
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        servings: Int? = nil,
        difficulty: DifficultyLevel? = nil,
        cuisineType: String? = nil,
        nutritionPerServing: NutritionInfo? = nil,
        tips: [String] = [],
        source: RecipeSource? = nil,
        dateGenerated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.instructions = instructions
        self.detailedSteps = detailedSteps
        self.ingredients = ingredients
        self.imageURL = imageURL
        self.savedImageData = savedImageData
        self.isLiked = isLiked
        self.tags = tags
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.difficulty = difficulty
        self.cuisineType = cuisineType
        self.nutritionPerServing = nutritionPerServing
        self.tips = tips
        self.source = source
        self.dateGenerated = dateGenerated
    }

    var totalTime: Int? {
        guard let prep = prepTime, let cook = cookTime else { return nil }
        return prep + cook
    }

    var totalTimeDisplay: String {
        guard let total = totalTime else { return "N/A" }
        if total >= 60 {
            let hours = total / 60
            let mins = total % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(total) min"
    }

    var hasDetailedSteps: Bool {
        !detailedSteps.isEmpty
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Recipe Step (Detailed instruction with media)

struct RecipeStep: Identifiable, Codable, Hashable {
    let id: UUID
    var stepNumber: Int
    var instruction: String
    var duration: Int?
    var technique: String?
    var gifURL: String?
    var videoURL: String?
    var tips: [String]

    init(
        id: UUID = UUID(),
        stepNumber: Int,
        instruction: String,
        duration: Int? = nil,
        technique: String? = nil,
        gifURL: String? = nil,
        videoURL: String? = nil,
        tips: [String] = []
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.duration = duration
        self.technique = technique
        self.gifURL = gifURL
        self.videoURL = videoURL
        self.tips = tips
    }

    var hasTechnique: Bool {
        technique != nil && !technique!.isEmpty
    }

    var hasMedia: Bool {
        gifURL != nil || videoURL != nil
    }

    var durationDisplay: String? {
        guard let dur = duration else { return nil }
        if dur >= 60 {
            let mins = dur / 60
            let secs = dur % 60
            return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
        }
        return "\(dur)s"
    }
}

// MARK: - Recipe Ingredient

struct RecipeIngredient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: String
    var unit: String?
    var isOptional: Bool
    var substitutes: [String]
    var isChecked: Bool

    init(
        id: UUID = UUID(),
        name: String,
        amount: String,
        unit: String? = nil,
        isOptional: Bool = false,
        substitutes: [String] = [],
        isChecked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isOptional = isOptional
        self.substitutes = substitutes
        self.isChecked = isChecked
    }

    var displayText: String {
        var text = ""
        if !amount.isEmpty {
            text += amount
            if let unit = unit, !unit.isEmpty {
                text += " \(unit)"
            }
            text += " "
        }
        text += name
        if isOptional {
            text += " (optional)"
        }
        return text
    }

    var hasSubstitutes: Bool {
        !substitutes.isEmpty
    }
}

// MARK: - Recipe Source

struct RecipeSource: Codable, Hashable {
    var name: String
    var url: String?
    var author: String?

    init(name: String, url: String? = nil, author: String? = nil) {
        self.name = name
        self.url = url
        self.author = author
    }

    var attribution: String {
        var text = name
        if let author = author {
            text += " by \(author)"
        }
        return text
    }
}

// MARK: - Difficulty Level

enum DifficultyLevel: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        case .expert: return "star.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .expert: return "red"
        }
    }
}
