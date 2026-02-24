//
//  RecipeJob.swift
//  ChefAI
//
//  Created by Claude on 2025-01-20.
//

import Foundation
import UIKit

// MARK: - Recipe Job Status

enum RecipeJobStatus: String, Codable {
    case thinking
    case searching
    case sourcesFound = "sources_found"
    case calculating
    case finished
    case error

    var displayText: String {
        switch self {
        case .thinking: return "Thinking"
        case .searching: return "Searching"
        case .sourcesFound: return "sources"
        case .calculating: return "Calculating"
        case .finished: return "Finished"
        case .error: return "Error"
        }
    }

    var isProcessing: Bool {
        switch self {
        case .thinking, .searching, .sourcesFound, .calculating:
            return true
        case .finished, .error:
            return false
        }
    }
}

// MARK: - Recipe Source Info

struct RecipeSourceInfo: Codable, Hashable, Identifiable {
    var id: String { url }
    let name: String
    let url: String
    let domain: String
}

// MARK: - Recipe Job

struct RecipeJob: Identifiable, Codable, Hashable {
    let id: UUID
    let analysisId: UUID
    let ingredients: [String]
    var thumbnailData: Data?
    var status: RecipeJobStatus
    var sourceCount: Int
    var sources: [RecipeSourceInfo]
    var recipes: [Recipe]
    let createdAt: Date
    var completedAt: Date?
    var errorMessage: String?
    var recipeType: String?
    var customPrompt: String?

    init(
        id: UUID = UUID(),
        analysisId: UUID,
        ingredients: [String],
        thumbnailData: Data? = nil,
        recipeType: String? = nil,
        customPrompt: String? = nil
    ) {
        self.id = id
        self.analysisId = analysisId
        self.ingredients = ingredients
        self.thumbnailData = thumbnailData
        self.recipeType = recipeType
        self.customPrompt = customPrompt
        self.status = .thinking
        self.sourceCount = 0
        self.sources = []
        self.recipes = []
        self.createdAt = Date()
    }

    var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }

    var ingredientsSummary: String {
        let names = ingredients.prefix(3)
        if ingredients.count > 3 {
            return names.joined(separator: ", ") + " +\(ingredients.count - 3)"
        }
        return names.joined(separator: ", ")
    }
}

// MARK: - SSE Status Event (from backend)

struct SSEStatusEvent: Codable {
    let status: String
    let sourceCount: Int?
    let message: String?
    let recipes: [APIRecipeResponse]?
    let sources: [RecipeSourceInfo]?

    // Nested API response model for parsing
    struct APIRecipeResponse: Codable {
        let id: UUID
        let name: String
        let description: String?
        let instructions: [String]
        let detailedSteps: [APIRecipeStepResponse]?
        let ingredients: [APIRecipeIngredientResponse]
        let imageURL: String?
        let tags: [String]?
        let prepTime: Int?
        let cookTime: Int?
        let servings: Int?
        let difficulty: String?
        let cuisineType: String?
        let nutritionPerServing: APINutritionInfoResponse?
        let tips: [String]?
        let source: APIRecipeSourceResponse?
        let dateGenerated: Date?

        func toRecipe() -> Recipe {
            let recipeIngredients = ingredients.map { $0.toRecipeIngredient() }
            let recipeSteps = detailedSteps?.map { $0.toRecipeStep() } ?? []

            var nutritionInfo: NutritionInfo?
            if let nutrition = nutritionPerServing {
                nutritionInfo = nutrition.toNutritionInfo()
            }

            var recipeSource: RecipeSource?
            if let src = source {
                recipeSource = RecipeSource(name: src.name, url: src.url, author: src.author)
            }

            let difficultyLevel: DifficultyLevel?
            switch difficulty?.lowercased() {
            case "easy", "beginner", "simple":
                difficultyLevel = .easy
            case "medium", "intermediate":
                difficultyLevel = .medium
            case "hard", "difficult", "advanced":
                difficultyLevel = .hard
            case "expert", "professional":
                difficultyLevel = .expert
            default:
                difficultyLevel = .easy
            }

            return Recipe(
                id: id,
                name: name,
                description: description,
                instructions: instructions,
                detailedSteps: recipeSteps,
                ingredients: recipeIngredients,
                imageURL: imageURL,
                tags: tags ?? [],
                prepTime: prepTime,
                cookTime: cookTime,
                servings: servings,
                difficulty: difficultyLevel,
                cuisineType: cuisineType,
                nutritionPerServing: nutritionInfo,
                tips: tips ?? [],
                source: recipeSource,
                dateGenerated: dateGenerated ?? Date()
            )
        }
    }

    struct APIRecipeStepResponse: Codable {
        let id: UUID?
        let stepNumber: Int
        let instruction: String
        let duration: Int?
        let technique: String?
        let gifURL: String?
        let videoURL: String?
        let tips: [String]?

        func toRecipeStep() -> RecipeStep {
            RecipeStep(
                id: id ?? UUID(),
                stepNumber: stepNumber,
                instruction: instruction,
                duration: duration,
                technique: technique,
                gifURL: gifURL,
                videoURL: videoURL,
                tips: tips ?? []
            )
        }
    }

    struct APIRecipeIngredientResponse: Codable {
        let id: UUID?
        let name: String
        let amount: String
        let unit: String?
        let isOptional: Bool?
        let substitutes: [String]?

        func toRecipeIngredient() -> RecipeIngredient {
            RecipeIngredient(
                id: id ?? UUID(),
                name: name,
                amount: amount,
                unit: unit,
                isOptional: isOptional ?? false,
                substitutes: substitutes ?? []
            )
        }
    }

    struct APINutritionInfoResponse: Codable {
        let calories: Int?
        let protein: Double?
        let carbs: Double?
        let fat: Double?
        let fiber: Double?
        let sodium: Double?
        let sugar: Double?
        let servingSize: String?

        func toNutritionInfo() -> NutritionInfo {
            NutritionInfo(
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sodium: sodium,
                sugar: sugar,
                servingSize: servingSize
            )
        }
    }

    struct APIRecipeSourceResponse: Codable {
        let name: String
        let url: String?
        let author: String?
    }
}
