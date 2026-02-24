//
//  RecipeCategoryService.swift
//  ChefAI
//

import Foundation
import Combine

class RecipeCategoryService: ObservableObject {
    static let shared = RecipeCategoryService()

    @Published private(set) var categories: [RecipeCategory] = []

    private let storageKey = "chefai_recipe_categories"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadCategories()
    }

    // MARK: - Public Methods

    func addCategory(name: String, colorHex: String, iconName: String? = nil) {
        let category = RecipeCategory(name: name, colorHex: colorHex, iconName: iconName)
        categories.append(category)
        save()
    }

    func updateCategory(_ categoryId: UUID, name: String, colorHex: String, iconName: String?) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[index].name = name
        categories[index].colorHex = colorHex
        categories[index].iconName = iconName
        save()
    }

    func deleteCategory(_ categoryId: UUID) {
        categories.removeAll { $0.id == categoryId }
        save()
    }

    func addRecipe(_ recipeId: UUID, toCategory categoryId: UUID) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        if !categories[index].recipeIds.contains(recipeId) {
            categories[index].recipeIds.append(recipeId)
            save()
        }
    }

    func removeRecipe(_ recipeId: UUID, fromCategory categoryId: UUID) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[index].recipeIds.removeAll { $0 == recipeId }
        save()
    }

    func categoriesForRecipe(_ recipeId: UUID) -> [RecipeCategory] {
        categories.filter { $0.recipeIds.contains(recipeId) }
    }

    func recipes(in category: RecipeCategory) -> [Recipe] {
        let allRecipes = RecipeJobService.shared.completedJobs.flatMap { $0.recipes }
        return allRecipes.filter { category.recipeIds.contains($0.id) }
    }

    // MARK: - Persistence

    private func loadCategories() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            categories = try decoder.decode([RecipeCategory].self, from: data)
        } catch {
            print("Failed to load categories: \(error)")
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(categories)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save categories: \(error)")
        }
    }
}
