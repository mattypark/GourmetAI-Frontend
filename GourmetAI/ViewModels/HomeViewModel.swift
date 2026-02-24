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
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageService: StorageService

    init(storageService: StorageService? = nil) {
        self.storageService = storageService ?? StorageService.shared
    }

    func loadData() {
        isLoading = true
        storageService.removeDuplicateAnalyses()  // Clean up any duplicate analyses
        analyses = storageService.loadAnalyses()
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
}
