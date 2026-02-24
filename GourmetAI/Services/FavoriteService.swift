//
//  FavoriteService.swift
//  ChefAI
//

import Foundation
import Combine

class FavoriteService: ObservableObject {
    static let shared = FavoriteService()

    @Published private(set) var favoriteRecipeIds: Set<UUID> = []

    private let storageKey = "chefai_favorite_recipes"

    private init() {
        load()
    }

    // MARK: - Public Methods

    func isFavorite(_ recipeId: UUID) -> Bool {
        favoriteRecipeIds.contains(recipeId)
    }

    func toggleFavorite(_ recipeId: UUID) {
        if favoriteRecipeIds.contains(recipeId) {
            favoriteRecipeIds.remove(recipeId)
        } else {
            favoriteRecipeIds.insert(recipeId)
        }
        save()
    }

    func addFavorite(_ recipeId: UUID) {
        guard !favoriteRecipeIds.contains(recipeId) else { return }
        favoriteRecipeIds.insert(recipeId)
        save()
    }

    func removeFavorite(_ recipeId: UUID) {
        favoriteRecipeIds.remove(recipeId)
        save()
    }

    /// Returns all favorited Recipe objects by looking up IDs across completed jobs
    func favoriteRecipes() -> [Recipe] {
        let allRecipes = RecipeJobService.shared.completedJobs.flatMap { $0.recipes }
        return allRecipes.filter { favoriteRecipeIds.contains($0.id) }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            favoriteRecipeIds = ids
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(favoriteRecipeIds) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
