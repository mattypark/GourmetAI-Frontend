//
//  HomeViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var analyses: [AnalysisResult] = []
    @Published var pantryIngredients: [Ingredient] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService: StorageService
    private let inventoryService = InventoryService.shared

    init(storageService: StorageService? = nil) {
        self.storageService = storageService ?? StorageService.shared
    }

    func loadData() {
        isLoading = true

        // Load from storage
        analyses = storageService.loadAnalyses()
        pantryIngredients = inventoryService.getAllIngredients()

        isLoading = false
    }

    func deleteAnalysis(_ analysis: AnalysisResult) {
        analyses.removeAll { $0.id == analysis.id }
        storageService.saveAnalyses(analyses)
    }

    func clearAllData() {
        analyses.removeAll()
        storageService.clearAllData()
    }

    var pantryCount: Int {
        pantryIngredients.count
    }

    var hasPantryItems: Bool {
        !pantryIngredients.isEmpty
    }

    func removeFromPantry(_ ingredient: Ingredient) {
        inventoryService.removeIngredient(ingredient.id)
        pantryIngredients = inventoryService.getAllIngredients()
    }

    func clearPantry() {
        inventoryService.clearAll()
        pantryIngredients = []
    }
}
