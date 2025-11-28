//
//  Ingredient.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

struct Ingredient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: IngredientCategory?
    var confidence: Double? // AI confidence score

    init(
        id: UUID = UUID(),
        name: String,
        category: IngredientCategory? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.confidence = confidence
    }
}

enum IngredientCategory: String, Codable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case seafood = "Seafood"
    case grains = "Grains"
    case spices = "Spices"
    case condiments = "Condiments"
    case other = "Other"
}
