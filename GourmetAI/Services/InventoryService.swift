//
//  InventoryService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import Foundation
import Combine

// MARK: - Inventory Service

@MainActor
class InventoryService: ObservableObject {
    static let shared = InventoryService()

    @Published private(set) var inventory: Inventory
    @Published var searchQuery: String = ""
    @Published var selectedCategory: IngredientCategory?

    private let storageKey = "chefai_inventory"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        self.inventory = Inventory()
        loadInventory()
    }

    // MARK: - Persistence

    func loadInventory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("📦 No saved inventory found")
            return
        }

        do {
            inventory = try decoder.decode(Inventory.self, from: data)
            print("📦 Loaded inventory: \(inventory.count) ingredients")
        } catch {
            print("❌ Failed to load inventory: \(error)")
            inventory = Inventory()
        }
    }

    func saveInventory() {
        do {
            let data = try encoder.encode(inventory)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("💾 Saved inventory: \(inventory.count) ingredients")
        } catch {
            print("❌ Failed to save inventory: \(error)")
        }
    }

    // MARK: - Ingredient Management

    func addIngredient(_ ingredient: Ingredient) {
        inventory.addIngredient(ingredient)
        saveInventory()
    }

    func addIngredients(_ ingredients: [Ingredient]) {
        inventory.addIngredients(ingredients)
        saveInventory()
    }

    func removeIngredient(_ id: UUID) {
        inventory.removeIngredient(id)
        saveInventory()
    }

    func removeIngredients(_ ids: Set<UUID>) {
        inventory.removeIngredients(ids)
        saveInventory()
    }

    func updateIngredient(_ ingredient: Ingredient) {
        inventory.updateIngredient(ingredient)
        saveInventory()
    }

    func clearAll() {
        inventory.clearAll()
        saveInventory()
    }

    // MARK: - Query Methods

    func getAllIngredients() -> [Ingredient] {
        inventory.ingredients
    }

    func getIngredientNames() -> [String] {
        inventory.ingredientNames()
    }

    func getIngredientNamesForRecipes() -> [String] {
        // Return names suitable for recipe generation (without quantities)
        inventory.ingredients.map { ingredient in
            if let brand = ingredient.brandName, !brand.isEmpty {
                return "\(brand) \(ingredient.name)"
            }
            return ingredient.name
        }
    }

    func searchIngredients(_ query: String) -> [Ingredient] {
        inventory.search(query)
    }

    func ingredientsByCategory() -> [IngredientCategory: [Ingredient]] {
        inventory.ingredientsByCategory()
    }

    // MARK: - Filtered Ingredients

    var filteredIngredients: [Ingredient] {
        var result = inventory.ingredients

        // Apply search filter
        if !searchQuery.isEmpty {
            result = inventory.search(searchQuery)
        }

        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Sort by date added (newest first)
        return result.sorted { $0.dateAdded > $1.dateAdded }
    }

    // MARK: - Add from Analysis Result

    func addFromAnalysisResult(_ result: AnalysisResult) {
        // Add extracted ingredients
        addIngredients(result.extractedIngredients)

        // Add manually added items as ingredients
        let manualIngredients = result.manuallyAddedItems.map { name in
            Ingredient(name: name)
        }
        addIngredients(manualIngredients)
    }

    // MARK: - Computed Properties

    var ingredientCount: Int {
        inventory.count
    }

    var isEmpty: Bool {
        inventory.isEmpty
    }

    var expiringIngredients: [Ingredient] {
        inventory.expiringIngredients
    }

    var statistics: Inventory.Statistics {
        inventory.statistics
    }

    var categories: [IngredientCategory] {
        Array(Set(inventory.ingredients.compactMap { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }
}

// MARK: - Batch Operations

extension InventoryService {
    func importIngredients(from names: [String], category: IngredientCategory? = nil) {
        let ingredients = names.map { name in
            Ingredient(name: name, category: category)
        }
        addIngredients(ingredients)
    }

    func removeExpired() {
        let now = Date()
        let expiredIds = inventory.ingredients
            .filter { ($0.expirationDate ?? Date.distantFuture) < now }
            .map { $0.id }
        removeIngredients(Set(expiredIds))
    }

    func updateQuantity(for id: UUID, quantity: String?, unit: String?) {
        guard var ingredient = inventory.ingredient(byId: id) else { return }
        ingredient.quantity = quantity
        ingredient.unit = unit
        updateIngredient(ingredient)
    }
}
