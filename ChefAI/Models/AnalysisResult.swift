//
//  AnalysisResult.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import UIKit

struct AnalysisResult: Identifiable, Hashable {
    let id: UUID
    var extractedIngredients: [Ingredient]
    var suggestedRecipes: [Recipe]
    let date: Date
    var imagesData: [Data]
    var manuallyAddedItems: [String]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        lhs.id == rhs.id
    }

    init(
        id: UUID = UUID(),
        extractedIngredients: [Ingredient] = [],
        suggestedRecipes: [Recipe] = [],
        date: Date = Date(),
        imagesData: [Data] = [],
        manuallyAddedItems: [String] = []
    ) {
        self.id = id
        self.extractedIngredients = extractedIngredients
        self.suggestedRecipes = suggestedRecipes
        self.date = date
        self.imagesData = imagesData
        self.manuallyAddedItems = manuallyAddedItems
    }

    /// Backward-compatible convenience init accepting a single image
    init(
        id: UUID = UUID(),
        extractedIngredients: [Ingredient] = [],
        suggestedRecipes: [Recipe] = [],
        date: Date = Date(),
        imageData: Data?,
        manuallyAddedItems: [String] = []
    ) {
        self.id = id
        self.extractedIngredients = extractedIngredients
        self.suggestedRecipes = suggestedRecipes
        self.date = date
        self.imagesData = imageData.map { [$0] } ?? []
        self.manuallyAddedItems = manuallyAddedItems
    }

    /// First image data (backward compat for code expecting single image)
    var imageData: Data? {
        imagesData.first
    }

    var thumbnailImage: UIImage? {
        guard let data = imagesData.first else { return nil }
        return UIImage(data: data)
    }

    var thumbnailImages: [UIImage] {
        imagesData.compactMap { UIImage(data: $0) }
    }

    var ingredientSummary: String {
        let count = extractedIngredients.count + manuallyAddedItems.count
        return "\(count) ingredient\(count == 1 ? "" : "s")"
    }

    var allIngredientNames: [String] {
        extractedIngredients.map { $0.name } + manuallyAddedItems
    }
}

// MARK: - Codable (backward-compatible)

extension AnalysisResult: Codable {
    enum CodingKeys: String, CodingKey {
        case id, extractedIngredients, suggestedRecipes, date
        case imageData, imagesData, manuallyAddedItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        extractedIngredients = try container.decodeIfPresent([Ingredient].self, forKey: .extractedIngredients) ?? []
        suggestedRecipes = try container.decodeIfPresent([Recipe].self, forKey: .suggestedRecipes) ?? []
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        manuallyAddedItems = try container.decodeIfPresent([String].self, forKey: .manuallyAddedItems) ?? []

        // Try new multi-image format first, fall back to legacy single-image
        if let multi = try? container.decode([Data].self, forKey: .imagesData), !multi.isEmpty {
            imagesData = multi
        } else if let single = try? container.decodeIfPresent(Data.self, forKey: .imageData) {
            imagesData = [single]
        } else {
            imagesData = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(extractedIngredients, forKey: .extractedIngredients)
        try container.encode(suggestedRecipes, forKey: .suggestedRecipes)
        try container.encode(date, forKey: .date)
        try container.encode(imagesData, forKey: .imagesData)
        try container.encode(manuallyAddedItems, forKey: .manuallyAddedItems)
    }
}
