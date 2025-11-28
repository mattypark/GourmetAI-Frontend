//
//  AIService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import UIKit

actor AIService {
    static let shared = AIService()

    private init() {}

    /// Placeholder AI function to analyze fridge contents
    /// TODO: Replace with real AI integration (Vision/CoreML or external API)
    func analyzeFridge(
        image: UIImage?,
        manualItems: [String]
    ) async throws -> AnalysisResult {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Mock extraction from image
        let extractedIngredients = extractIngredientsFromImage(image)

        // Generate mock recipes based on ingredients
        let suggestedRecipes = generateMockRecipes(
            ingredients: extractedIngredients.map { $0.name } + manualItems
        )

        // Compress image for storage (0.7 compression quality)
        let imageData = image?.jpegData(compressionQuality: 0.7)

        return AnalysisResult(
            extractedIngredients: extractedIngredients,
            suggestedRecipes: suggestedRecipes,
            imageData: imageData,
            manuallyAddedItems: manualItems
        )
    }

    // MARK: - Private Helpers

    /// TODO: Replace with real Vision/CoreML model
    nonisolated private func extractIngredientsFromImage(_ image: UIImage?) -> [Ingredient] {
        guard image != nil else { return [] }
        // Return mock ingredients for now
        return [
            Ingredient(name: "Eggs", category: .dairy, confidence: 0.95),
            Ingredient(name: "Milk", category: .dairy, confidence: 0.92),
            Ingredient(name: "Chicken Breast", category: .meat, confidence: 0.88),
            Ingredient(name: "Broccoli", category: .produce, confidence: 0.90),
            Ingredient(name: "Rice", category: .grains, confidence: 0.85)
        ]
    }

    /// TODO: Replace with real AI recipe generation
    nonisolated private func generateMockRecipes(ingredients: [String]) -> [Recipe] {
        // Return mock recipes for now
        return [
            Recipe(
                name: "Chicken Stir Fry",
                instructions: [
                    "Cut chicken into bite-sized pieces",
                    "Heat oil in a wok or large pan",
                    "Cook chicken until golden brown",
                    "Add broccoli and stir fry for 3-4 minutes",
                    "Season with soy sauce and serve over rice"
                ],
                ingredients: [
                    RecipeIngredient(name: "Chicken Breast", amount: "1", unit: "lb"),
                    RecipeIngredient(name: "Broccoli", amount: "2", unit: "cups"),
                    RecipeIngredient(name: "Rice", amount: "1", unit: "cup"),
                    RecipeIngredient(name: "Soy Sauce", amount: "2", unit: "tbsp")
                ],
                tags: ["Quick Meals", "High-Protein", "Asian"],
                prepTime: 10,
                cookTime: 15,
                servings: 4,
                difficulty: .easy
            ),
            Recipe(
                name: "Veggie Omelet",
                instructions: [
                    "Beat eggs in a bowl",
                    "Heat butter in a pan",
                    "Pour eggs and cook until edges set",
                    "Add chopped vegetables",
                    "Fold and serve"
                ],
                ingredients: [
                    RecipeIngredient(name: "Eggs", amount: "3", unit: nil),
                    RecipeIngredient(name: "Broccoli", amount: "1/2", unit: "cup"),
                    RecipeIngredient(name: "Butter", amount: "1", unit: "tbsp")
                ],
                tags: ["Breakfast", "Vegetarian", "Quick Meals"],
                prepTime: 5,
                cookTime: 8,
                servings: 1,
                difficulty: .easy
            ),
            Recipe(
                name: "Chicken & Rice Bowl",
                instructions: [
                    "Cook rice according to package directions",
                    "Season and grill chicken breast",
                    "Steam broccoli",
                    "Assemble bowl with rice, chicken, and vegetables",
                    "Top with your favorite sauce"
                ],
                ingredients: [
                    RecipeIngredient(name: "Chicken Breast", amount: "8", unit: "oz"),
                    RecipeIngredient(name: "Rice", amount: "1", unit: "cup"),
                    RecipeIngredient(name: "Broccoli", amount: "1", unit: "cup")
                ],
                tags: ["Healthy", "High-Protein", "Meal Prep"],
                prepTime: 10,
                cookTime: 25,
                servings: 2,
                difficulty: .medium
            )
        ]
    }
}
