//
//  AnalysisResult.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import UIKit

struct AnalysisResult: Identifiable, Codable, Hashable {
    let id: UUID
    var extractedIngredients: [Ingredient]
    var suggestedRecipes: [Recipe]
    let date: Date
    var imageData: Data?
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
        imageData: Data? = nil,
        manuallyAddedItems: [String] = []
    ) {
        self.id = id
        self.extractedIngredients = extractedIngredients
        self.suggestedRecipes = suggestedRecipes
        self.date = date
        self.imageData = imageData
        self.manuallyAddedItems = manuallyAddedItems
    }

    var thumbnailImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }

    var ingredientSummary: String {
        let count = extractedIngredients.count + manuallyAddedItems.count
        return "\(count) ingredient\(count == 1 ? "" : "s")"
    }

    var allIngredientNames: [String] {
        extractedIngredients.map { $0.name } + manuallyAddedItems
    }
}
