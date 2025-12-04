//
//  OpenAIModels.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import Foundation

// MARK: - Request Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }

    struct Message: Codable {
        let role: String
        let content: [Content]
    }

    struct Content: Codable {
        let type: String
        let text: String?
        let imageUrl: ImageURL?

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageUrl = "image_url"
        }
    }

    struct ImageURL: Codable {
        let url: String
    }
}

// MARK: - Response Models

struct OpenAIResponse: Codable {
    let id: String
    let choices: [Choice]
    let usage: Usage?
    let error: APIError?

    struct Choice: Codable {
        let message: Message
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }

    struct APIError: Codable {
        let message: String
        let type: String
        let code: String?
    }
}

// MARK: - Analysis Result from GPT-4

struct AIAnalysisResult: Codable {
    let hasFood: Bool
    let ingredients: [DetectedIngredient]
    let suggestedRecipes: [SuggestedRecipe]
    let message: String?

    struct DetectedIngredient: Codable {
        let name: String
        let brandName: String?
        let quantity: String?
        let unit: String?
        let category: String?
        let confidence: Double
        let nutrition: DetectedNutrition?

        enum CodingKeys: String, CodingKey {
            case name, brandName, quantity, unit, category, confidence, nutrition
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
            quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
            unit = try container.decodeIfPresent(String.self, forKey: .unit)
            category = try container.decodeIfPresent(String.self, forKey: .category)
            confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.8
            nutrition = try container.decodeIfPresent(DetectedNutrition.self, forKey: .nutrition)
        }
    }

    struct DetectedNutrition: Codable {
        let calories: Int?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let servingSize: String?
    }

    struct SuggestedRecipe: Codable {
        let name: String
        let description: String?
        let ingredients: [RecipeIngredientDetail]
        let instructions: [String]
        let detailedSteps: [DetailedStep]?
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let cuisineType: String?
        let tags: [String]
        let tips: [String]?
        let nutritionPerServing: DetectedNutrition?
        let source: SourceInfo?

        enum CodingKeys: String, CodingKey {
            case name, description, ingredients, instructions, detailedSteps
            case prepTime, cookTime, servings, difficulty, cuisineType
            case tags, tips, nutritionPerServing, source
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
            detailedSteps = try container.decodeIfPresent([DetailedStep].self, forKey: .detailedSteps)
            prepTime = try container.decodeIfPresent(Int.self, forKey: .prepTime)
            cookTime = try container.decodeIfPresent(Int.self, forKey: .cookTime)
            servings = try container.decodeIfPresent(Int.self, forKey: .servings)
            difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
            cuisineType = try container.decodeIfPresent(String.self, forKey: .cuisineType)
            tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
            tips = try container.decodeIfPresent([String].self, forKey: .tips)
            nutritionPerServing = try container.decodeIfPresent(DetectedNutrition.self, forKey: .nutritionPerServing)
            source = try container.decodeIfPresent(SourceInfo.self, forKey: .source)

            // Handle ingredients that could be strings or objects
            if let ingredientStrings = try? container.decode([String].self, forKey: .ingredients) {
                ingredients = ingredientStrings.map { RecipeIngredientDetail(name: $0, amount: "as needed") }
            } else {
                ingredients = try container.decodeIfPresent([RecipeIngredientDetail].self, forKey: .ingredients) ?? []
            }
        }
    }

    struct RecipeIngredientDetail: Codable {
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

    struct DetailedStep: Codable {
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

    struct SourceInfo: Codable {
        let name: String
        let url: String?
        let author: String?
    }
}

// MARK: - Recipe Generation Result

struct RecipeGenerationResult: Codable {
    let recipes: [AIAnalysisResult.SuggestedRecipe]
}

// MARK: - Text-Only OpenAI Request

struct OpenAITextRequest: Codable {
    let model: String
    let messages: [Message]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }

    struct Message: Codable {
        let role: String
        let content: String
    }
}
