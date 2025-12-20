//
//  ClaudeModels.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import Foundation

// MARK: - Claude API Request Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

struct ClaudeMessage: Codable {
    let role: String  // "user" or "assistant"
    let content: String
}

// MARK: - Claude API Response Models

struct ClaudeResponse: Codable {
    let id: String?
    let type: String
    let role: String?
    let content: [ClaudeContent]?
    let stopReason: String?
    let usage: ClaudeUsage?
    let error: ClaudeError?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content
        case stopReason = "stop_reason"
        case usage, error
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

// MARK: - Recipe Generation Result from Claude

struct ClaudeRecipeResult: Codable {
    let recipes: [ClaudeRecipe]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recipes = try container.decodeIfPresent([ClaudeRecipe].self, forKey: .recipes) ?? []
    }
}

struct ClaudeRecipe: Codable {
    let name: String
    let description: String?
    let ingredients: [ClaudeRecipeIngredient]
    let instructions: [String]
    let detailedSteps: [ClaudeDetailedStep]?
    let prepTime: Int?
    let cookTime: Int?
    let servings: Int?
    let difficulty: String?
    let cuisineType: String?
    let nutritionPerServing: ClaudeNutrition?
    let tips: [String]?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case name, description, ingredients, instructions, detailedSteps
        case prepTime, cookTime, servings, difficulty, cuisineType
        case nutritionPerServing, tips, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        detailedSteps = try container.decodeIfPresent([ClaudeDetailedStep].self, forKey: .detailedSteps)
        prepTime = try container.decodeIfPresent(Int.self, forKey: .prepTime)
        cookTime = try container.decodeIfPresent(Int.self, forKey: .cookTime)
        servings = try container.decodeIfPresent(Int.self, forKey: .servings)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        cuisineType = try container.decodeIfPresent(String.self, forKey: .cuisineType)
        nutritionPerServing = try container.decodeIfPresent(ClaudeNutrition.self, forKey: .nutritionPerServing)
        tips = try container.decodeIfPresent([String].self, forKey: .tips)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)

        // Handle ingredients that could be strings or objects
        if let ingredientStrings = try? container.decode([String].self, forKey: .ingredients) {
            ingredients = ingredientStrings.map { ClaudeRecipeIngredient(name: $0, amount: "as needed") }
        } else {
            ingredients = try container.decodeIfPresent([ClaudeRecipeIngredient].self, forKey: .ingredients) ?? []
        }
    }
}

struct ClaudeRecipeIngredient: Codable {
    let name: String
    let amount: String
    let unit: String?
    let isOptional: Bool?
    let substitutes: [String]?

    init(name: String, amount: String, unit: String? = nil, isOptional: Bool? = nil, substitutes: [String]? = nil) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isOptional = isOptional
        self.substitutes = substitutes
    }

    enum CodingKeys: String, CodingKey {
        case name, amount, unit, isOptional, substitutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decodeIfPresent(String.self, forKey: .amount) ?? "as needed"
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        isOptional = try container.decodeIfPresent(Bool.self, forKey: .isOptional)
        substitutes = try container.decodeIfPresent([String].self, forKey: .substitutes)
    }
}

struct ClaudeDetailedStep: Codable {
    let stepNumber: Int
    let instruction: String
    let duration: Int?
    let technique: String?
    let tips: [String]?

    enum CodingKeys: String, CodingKey {
        case stepNumber, instruction, duration, technique, tips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stepNumber = try container.decodeIfPresent(Int.self, forKey: .stepNumber) ?? 1
        instruction = try container.decode(String.self, forKey: .instruction)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        technique = try container.decodeIfPresent(String.self, forKey: .technique)
        tips = try container.decodeIfPresent([String].self, forKey: .tips)
    }
}

struct ClaudeNutrition: Codable {
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sodium: Double?
}
