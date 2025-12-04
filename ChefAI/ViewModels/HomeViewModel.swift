//
//  HomeViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var analyses: [AnalysisResult] = []
    @Published var likedRecipes: [Recipe] = []
    @Published var pantryIngredients: [Ingredient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService: StorageService
    private let inventoryService = InventoryService.shared

    init(storageService: StorageService = .shared) {
        self.storageService = storageService
    }

    func loadData() {
        isLoading = true

        // Load from storage
        analyses = storageService.loadAnalyses()
        likedRecipes = storageService.loadLikedRecipes()
        pantryIngredients = inventoryService.getAllIngredients()

        isLoading = false
    }

    func toggleRecipeLike(_ recipe: Recipe) {
        var updatedRecipe = recipe
        updatedRecipe.isLiked.toggle()

        if updatedRecipe.isLiked {
            // Add to liked recipes if not already there
            if !likedRecipes.contains(where: { $0.id == recipe.id }) {
                likedRecipes.append(updatedRecipe)
            }
        } else {
            // Remove from liked recipes
            likedRecipes.removeAll { $0.id == recipe.id }
        }

        // Update in all analyses
        for i in analyses.indices {
            if let recipeIndex = analyses[i].suggestedRecipes.firstIndex(where: { $0.id == recipe.id }) {
                analyses[i].suggestedRecipes[recipeIndex] = updatedRecipe
            }
        }

        storageService.saveLikedRecipes(likedRecipes)
        storageService.saveAnalyses(analyses)
    }

    func deleteAnalysis(_ analysis: AnalysisResult) {
        analyses.removeAll { $0.id == analysis.id }
        storageService.saveAnalyses(analyses)
    }

    func clearAllData() {
        analyses.removeAll()
        likedRecipes.removeAll()
        storageService.clearAllData()
    }

    var savedRecipeImages: [Recipe] {
        likedRecipes.filter { $0.savedImageData != nil }
    }

    var pantryCount: Int {
        pantryIngredients.count
    }

    var hasPantryItems: Bool {
        !pantryIngredients.isEmpty
    }

    func removeFromPantry(_ ingredient: Ingredient) {
        inventoryService.removeIngredient(ingredient.id)
        pantryIngredients = inventoryService.getAllIngredients()
    }

    func clearPantry() {
        inventoryService.clearAll()
        pantryIngredients = []
    }
}
