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
        let category: String?
        let confidence: Double
    }

    struct SuggestedRecipe: Codable {
        let name: String
        let description: String?
        let ingredients: [String]
        let instructions: [String]
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let tags: [String]
    }
}
