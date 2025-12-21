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

    init(recipe: Recipe, storageService: StorageService? = nil) {
        self.recipe = recipe
        self.storageService = storageService ?? StorageService.shared
    }

    func saveRecipeImage(_ imageData: Data) {
        recipe.savedImageData = imageData
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
