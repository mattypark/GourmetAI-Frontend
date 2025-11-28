//
//  Recipe.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var instructions: [String]
    var ingredients: [RecipeIngredient]
    var imageURL: String?
    var savedImageData: Data? // User-saved recipe image for gallery
    var isLiked: Bool
    var tags: [String]
    var prepTime: Int? // minutes
    var cookTime: Int? // minutes
    var servings: Int?
    var difficulty: DifficultyLevel?

    init(
        id: UUID = UUID(),
        name: String,
        instructions: [String] = [],
        ingredients: [RecipeIngredient] = [],
        imageURL: String? = nil,
        savedImageData: Data? = nil,
        isLiked: Bool = false,
        tags: [String] = [],
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        servings: Int? = nil,
        difficulty: DifficultyLevel? = nil
    ) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.ingredients = ingredients
        self.imageURL = imageURL
        self.savedImageData = savedImageData
        self.isLiked = isLiked
        self.tags = tags
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.difficulty = difficulty
    }

    var totalTime: Int? {
        guard let prep = prepTime, let cook = cookTime else { return nil }
        return prep + cook
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Recipe Ingredient

struct RecipeIngredient: Codable, Hashable {
    var name: String
    var amount: String
    var unit: String?

    var displayText: String {
        if let unit = unit {
            return "\(amount) \(unit) \(name)"
        }
        return "\(amount) \(name)"
    }
}

// MARK: - Difficulty Level

enum DifficultyLevel: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .medium: return "2.circle.fill"
        case .hard: return "3.circle.fill"
        }
    }
}
