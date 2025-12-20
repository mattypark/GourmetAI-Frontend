//
//  Ingredient.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

// MARK: - Ingredient Model

struct Ingredient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var brandName: String?
    var quantity: String?
    var unit: String?
    var category: IngredientCategory?
    var confidence: Double?
    var nutritionInfo: NutritionInfo?
    var barcode: String?
    var expirationDate: Date?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        name: String,
        brandName: String? = nil,
        quantity: String? = nil,
        unit: String? = nil,
        category: IngredientCategory? = nil,
        confidence: Double? = nil,
        nutritionInfo: NutritionInfo? = nil,
        barcode: String? = nil,
        expirationDate: Date? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brandName = brandName
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.confidence = confidence
        self.nutritionInfo = nutritionInfo
        self.barcode = barcode
        self.expirationDate = expirationDate
        self.dateAdded = dateAdded
    }

    var displayName: String {
        if let brand = brandName, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }

    var quantityDisplay: String? {
        guard let qty = quantity else { return nil }
        if let unit = unit {
            return "\(qty) \(unit)"
        }
        return qty
    }

    // MARK: - Custom Decoder for backward compatibility

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        category = try container.decodeIfPresent(IngredientCategory.self, forKey: .category)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        nutritionInfo = try container.decodeIfPresent(NutritionInfo.self, forKey: .nutritionInfo)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        // Safe decode with default to Date() if missing (backward compatibility)
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, brandName, quantity, unit, category, confidence
        case nutritionInfo, barcode, expirationDate, dateAdded
    }
}

// MARK: - Nutrition Info

struct NutritionInfo: Codable, Hashable {
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var fiber: Double?
    var sodium: Double?
    var sugar: Double?
    var servingSize: String?

    init(
        calories: Int? = nil,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sodium: Double? = nil,
        sugar: Double? = nil,
        servingSize: String? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sodium = sodium
        self.sugar = sugar
        self.servingSize = servingSize
    }

    var hasMacros: Bool {
        protein != nil || carbs != nil || fat != nil
    }

    var macrosSummary: String {
        var parts: [String] = []
        if let p = protein { parts.append("P: \(Int(p))g") }
        if let c = carbs { parts.append("C: \(Int(c))g") }
        if let f = fat { parts.append("F: \(Int(f))g") }
        return parts.joined(separator: " | ")
    }
}

// MARK: - Ingredient Category

enum IngredientCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case seafood = "Seafood"
    case grains = "Grains"
    case pantryStaples = "Pantry Staples"
    case condiments = "Condiments"
    case spices = "Spices"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case bakery = "Bakery"
    case other = "Other"

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .meat: return "fork.knife"
        case .seafood: return "fish.fill"
        case .grains: return "wheat"
        case .pantryStaples: return "cabinet.fill"
        case .condiments: return "drop.fill"
        case .spices: return "sparkle"
        case .frozen: return "snowflake"
        case .beverages: return "cup.and.saucer"
        case .snacks: return "bag.fill"
        case .bakery: return "birthday.cake.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .produce: return "green"
        case .dairy: return "blue"
        case .meat: return "red"
        case .seafood: return "cyan"
        case .grains: return "yellow"
        case .pantryStaples: return "brown"
        case .condiments: return "orange"
        case .spices: return "purple"
        case .frozen: return "mint"
        case .beverages: return "teal"
        case .snacks: return "pink"
        case .bakery: return "indigo"
        case .other: return "gray"
        }
    }
}
