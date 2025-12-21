//
//  RecipeListViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RecipeListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var recipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    @Published var selectedRecipe: Recipe?
    @Published var showingRecipeDetail: Bool = false
    @Published var progress: Double = 0.0

    // MARK: - Private Properties

    private var currentIngredients: [String] = []
    private var userProfile: UserProfile?

    // MARK: - Initialization

    init() {
        loadUserProfile()
    }

    private func loadUserProfile() {
        userProfile = StorageService.shared.loadUserProfile()
    }

    // MARK: - Recipe Generation

    func generateRecipes(from ingredients: [Ingredient]) async {
        let ingredientNames = ingredients.map { $0.displayName }
        await generateRecipes(from: ingredientNames)
    }

    func generateRecipes(from ingredientNames: [String]) async {
        guard !ingredientNames.isEmpty else {
            errorMessage = "No ingredients available to generate recipes"
            return
        }

        currentIngredients = ingredientNames
        isLoading = true
        errorMessage = nil
        progress = 0.0

        // Simulate progress
        let progressTask = Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if !Task.isCancelled {
                    progress = Double(i) / 10.0 * 0.9
                }
            }
        }

        do {
            let generatedRecipes = try await AIService.shared.generateRecipes(
                from: ingredientNames,
                count: 5,
                userProfile: userProfile
            )

            progressTask.cancel()
            progress = 1.0

            recipes = generatedRecipes
            isLoading = false

        } catch {
            progressTask.cancel()
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Recipe generation error: \(error)")
        }
    }

    func refreshRecipes() async {
        guard !currentIngredients.isEmpty else { return }

        isRefreshing = true
        errorMessage = nil

        do {
            let newRecipes = try await AIService.shared.generateRecipes(
                from: currentIngredients,
                count: 5,
                userProfile: userProfile,
                excludingRecipes: recipes
            )

            recipes = newRecipes
            isRefreshing = false

        } catch {
            isRefreshing = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Recipe Selection

    func selectRecipe(_ recipe: Recipe) {
        selectedRecipe = recipe
        showingRecipeDetail = true
    }

    // MARK: - Computed Properties

    var hasRecipes: Bool {
        !recipes.isEmpty
    }

    var recipeCount: Int {
        recipes.count
    }
}

// MARK: - Recipe Filtering

extension RecipeListViewModel {
    enum RecipeFilter: String, CaseIterable {
        case all = "All"
        case quick = "Quick (<30 min)"
        case easy = "Easy"
        case healthy = "Healthy"
    }

    func filteredRecipes(by filter: RecipeFilter) -> [Recipe] {
        switch filter {
        case .all:
            return recipes
        case .quick:
            return recipes.filter { ($0.totalTime ?? 999) < 30 }
        case .easy:
            return recipes.filter { $0.difficulty == .easy }
        case .healthy:
            return recipes.filter { $0.tags.contains("Healthy") }
        }
    }
}
