//
//  RecipeDetailViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Combine

@MainActor
class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var showingSaveImagePicker = false

    private let storageService: StorageService

    init(recipe: Recipe, storageService: StorageService = .shared) {
        self.recipe = recipe
        self.storageService = storageService
    }

    func toggleLike() {
        recipe.isLiked.toggle()

        // Update in liked recipes
        var likedRecipes = storageService.loadLikedRecipes()

        if recipe.isLiked {
            // Add to liked recipes if not already there
            if !likedRecipes.contains(where: { $0.id == recipe.id }) {
                likedRecipes.append(recipe)
            } else {
                // Update existing
                if let index = likedRecipes.firstIndex(where: { $0.id == recipe.id }) {
                    likedRecipes[index] = recipe
                }
            }
        } else {
            // Remove from liked recipes
            likedRecipes.removeAll { $0.id == recipe.id }
        }

        storageService.saveLikedRecipes(likedRecipes)

        // Also update in analyses
        updateInAnalyses()
    }

    func saveRecipeImage(_ imageData: Data) {
        recipe.savedImageData = imageData

        // Update in liked recipes
        var likedRecipes = storageService.loadLikedRecipes()
        if let index = likedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            likedRecipes[index].savedImageData = imageData
            storageService.saveLikedRecipes(likedRecipes)
        }

        // Update in analyses
        updateInAnalyses()
    }

    private func updateInAnalyses() {
        var analyses = storageService.loadAnalyses()
        var updated = false

        for i in analyses.indices {
            if let recipeIndex = analyses[i].suggestedRecipes.firstIndex(where: { $0.id == recipe.id }) {
                analyses[i].suggestedRecipes[recipeIndex] = recipe
                updated = true
            }
        }

        if updated {
            storageService.saveAnalyses(analyses)
        }
    }
}
