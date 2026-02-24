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

    enum CodingKeys: String, CodingKey {
        case hasFood, ingredients, suggestedRecipes, message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // hasFood defaults to true if ingredients exist
        hasFood = try container.decodeIfPresent(Bool.self, forKey: .hasFood) ?? true
        ingredients = try container.decodeIfPresent([DetectedIngredient].self, forKey: .ingredients) ?? []
        suggestedRecipes = try container.decodeIfPresent([SuggestedRecipe].self, forKey: .suggestedRecipes) ?? []
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

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

        enum CodingKeys: String, CodingKey {
            case calories, protein, carbs, fat, servingSize
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)

            // Handle calories as Int, Double, or String
            if let intCal = try? container.decode(Int.self, forKey: .calories) {
                calories = intCal
            } else if let doubleCal = try? container.decode(Double.self, forKey: .calories) {
                calories = Int(doubleCal)
            } else if let stringCal = try? container.decode(String.self, forKey: .calories) {
                calories = Int(stringCal)
            } else {
                calories = nil
            }

            // Handle protein as Double, Int, or String
            if let doubleVal = try? container.decode(Double.self, forKey: .protein) {
                protein = doubleVal
            } else if let intVal = try? container.decode(Int.self, forKey: .protein) {
                protein = Double(intVal)
            } else if let stringVal = try? container.decode(String.self, forKey: .protein) {
                protein = Double(stringVal)
            } else {
                protein = nil
            }

            // Handle carbs as Double, Int, or String
            if let doubleVal = try? container.decode(Double.self, forKey: .carbs) {
                carbs = doubleVal
            } else if let intVal = try? container.decode(Int.self, forKey: .carbs) {
                carbs = Double(intVal)
            } else if let stringVal = try? container.decode(String.self, forKey: .carbs) {
                carbs = Double(stringVal)
            } else {
                carbs = nil
            }

            // Handle fat as Double, Int, or String
            if let doubleVal = try? container.decode(Double.self, forKey: .fat) {
                fat = doubleVal
            } else if let intVal = try? container.decode(Int.self, forKey: .fat) {
                fat = Double(intVal)
            } else if let stringVal = try? container.decode(String.self, forKey: .fat) {
                fat = Double(stringVal)
            } else {
                fat = nil
            }
        }
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

            // Handle amount as either String or Number
            if let stringAmount = try? container.decode(String.self, forKey: .amount) {
                amount = stringAmount
            } else if let intAmount = try? container.decode(Int.self, forKey: .amount) {
                amount = String(intAmount)
            } else if let doubleAmount = try? container.decode(Double.self, forKey: .amount) {
                amount = String(doubleAmount)
            } else {
                amount = "as needed"
            }

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
            technique = try container.decodeIfPresent(String.self, forKey: .technique)
            tips = try container.decodeIfPresent([String].self, forKey: .tips)

            // Handle duration as Int, String, or Double
            if let intDuration = try? container.decode(Int.self, forKey: .duration) {
                duration = intDuration
            } else if let stringDuration = try? container.decode(String.self, forKey: .duration) {
                // Parse "300" or "300 seconds" -> 300
                let digits = stringDuration.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                duration = Int(digits)
            } else if let doubleDuration = try? container.decode(Double.self, forKey: .duration) {
                duration = Int(doubleDuration)
            } else {
                duration = nil
            }
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
