//
//  Inventory.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import Foundation

// MARK: - Inventory Model

struct Inventory: Codable {
    var ingredients: [Ingredient]
    var lastUpdated: Date

    init(ingredients: [Ingredient] = [], lastUpdated: Date = Date()) {
        self.ingredients = ingredients
        self.lastUpdated = lastUpdated
    }

    // MARK: - Mutations

    mutating func addIngredient(_ ingredient: Ingredient) {
        // Check if ingredient with same name already exists
        if let index = ingredients.firstIndex(where: { $0.name.lowercased() == ingredient.name.lowercased() }) {
            // Update existing ingredient
            ingredients[index] = ingredient
        } else {
            ingredients.append(ingredient)
        }
        lastUpdated = Date()
    }

    mutating func addIngredients(_ newIngredients: [Ingredient]) {
        for ingredient in newIngredients {
            addIngredient(ingredient)
        }
    }

    mutating func removeIngredient(_ id: UUID) {
        ingredients.removeAll { $0.id == id }
        lastUpdated = Date()
    }

    mutating func removeIngredients(_ ids: Set<UUID>) {
        ingredients.removeAll { ids.contains($0.id) }
        lastUpdated = Date()
    }

    mutating func updateIngredient(_ ingredient: Ingredient) {
        if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
            ingredients[index] = ingredient
            lastUpdated = Date()
        }
    }

    mutating func clearAll() {
        ingredients.removeAll()
        lastUpdated = Date()
    }

    // MARK: - Queries

    func search(_ query: String) -> [Ingredient] {
        guard !query.isEmpty else { return ingredients }
        let lowercased = query.lowercased()
        return ingredients.filter { ingredient in
            ingredient.name.lowercased().contains(lowercased) ||
            ingredient.brandName?.lowercased().contains(lowercased) == true ||
            ingredient.category?.rawValue.lowercased().contains(lowercased) == true
        }
    }

    func ingredientsByCategory() -> [IngredientCategory: [Ingredient]] {
        var grouped: [IngredientCategory: [Ingredient]] = [:]
        for ingredient in ingredients {
            let category = ingredient.category ?? .other
            if grouped[category] == nil {
                grouped[category] = []
            }
            grouped[category]?.append(ingredient)
        }
        return grouped
    }

    func ingredientNames() -> [String] {
        ingredients.map { $0.name }
    }

    func ingredient(byId id: UUID) -> Ingredient? {
        ingredients.first { $0.id == id }
    }

    func contains(ingredientNamed name: String) -> Bool {
        ingredients.contains { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: - Computed Properties

    var count: Int {
        ingredients.count
    }

    var isEmpty: Bool {
        ingredients.isEmpty
    }

    var sortedByDate: [Ingredient] {
        ingredients.sorted { $0.dateAdded > $1.dateAdded }
    }

    var sortedByName: [Ingredient] {
        ingredients.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    var sortedByCategory: [Ingredient] {
        ingredients.sorted {
            let cat1 = $0.category?.rawValue ?? "ZZZ"
            let cat2 = $1.category?.rawValue ?? "ZZZ"
            if cat1 == cat2 {
                return $0.name.lowercased() < $1.name.lowercased()
            }
            return cat1 < cat2
        }
    }

    var expiringIngredients: [Ingredient] {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return ingredients.filter { ingredient in
            guard let expiration = ingredient.expirationDate else { return false }
            return expiration <= threeDaysFromNow
        }.sorted { ($0.expirationDate ?? Date.distantFuture) < ($1.expirationDate ?? Date.distantFuture) }
    }

    var categorySummary: String {
        let grouped = ingredientsByCategory()
        let parts = grouped.map { "\($0.value.count) \($0.key.rawValue)" }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Inventory Statistics

extension Inventory {
    struct Statistics {
        var totalCount: Int
        var categoryCounts: [IngredientCategory: Int]
        var expiringCount: Int
        var recentlyAddedCount: Int
        var withNutritionCount: Int
    }

    var statistics: Statistics {
        let grouped = ingredientsByCategory()
        let categoryCounts = grouped.mapValues { $0.count }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentlyAdded = ingredients.filter { $0.dateAdded >= sevenDaysAgo }

        let withNutrition = ingredients.filter { $0.nutritionInfo != nil }

        return Statistics(
            totalCount: count,
            categoryCounts: categoryCounts,
            expiringCount: expiringIngredients.count,
            recentlyAddedCount: recentlyAdded.count,
            withNutritionCount: withNutrition.count
        )
    }
}
