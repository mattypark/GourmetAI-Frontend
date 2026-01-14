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
    private var hasAttemptedGeneration: Bool = false
    private var userProfile: UserProfile?
    private let apiClient: APIClient

    // MARK: - Initialization

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
        loadUserProfile()
    }

    private func loadUserProfile() {
        userProfile = StorageService.shared.loadUserProfile()
    }

    // MARK: - Recipe Generation

    func generateRecipes(from ingredients: [Ingredient]) async {
        // Prevent duplicate generation calls
        guard !hasAttemptedGeneration else {
            print("⚠️ Recipe generation already attempted, skipping duplicate call")
            return
        }

        guard !ingredients.isEmpty else {
            errorMessage = "No ingredients available to generate recipes"
            return
        }

        hasAttemptedGeneration = true
        currentIngredients = ingredients.map { $0.displayName }
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
            // Use Backend API for recipe generation
            let generatedRecipes = try await apiClient.generateRecipes(
                from: ingredients,
                userProfile: userProfile,
                count: 5
            )

            progressTask.cancel()
            progress = 1.0

            recipes = generatedRecipes
            isLoading = false

        } catch APIClientError.networkError {
            progressTask.cancel()
            isLoading = false
            errorMessage = "Connection failed - is the backend server running?"
            print("❌ Recipe generation error: Network error")
        } catch APIClientError.unauthorized {
            progressTask.cancel()
            isLoading = false
            errorMessage = "Unauthorized - check API key configuration"
            print("❌ Recipe generation error: Unauthorized")
        } catch {
            progressTask.cancel()
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Recipe generation error: \(error)")
        }
    }

    func generateRecipes(from ingredientNames: [String]) async {
        // Convert string names to Ingredient objects
        let ingredients = ingredientNames.map { Ingredient(name: $0, confidence: 1.0) }
        await generateRecipes(from: ingredients)
    }

    func refreshRecipes() async {
        guard !currentIngredients.isEmpty else { return }

        isRefreshing = true
        errorMessage = nil

        do {
            // Convert current ingredient names to Ingredient objects
            let ingredients = currentIngredients.map { Ingredient(name: $0, confidence: 1.0) }

            let newRecipes = try await apiClient.generateRecipes(
                from: ingredients,
                userProfile: userProfile,
                count: 5
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
