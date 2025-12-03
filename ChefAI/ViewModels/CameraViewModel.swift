//
//  CameraViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Combine
import UIKit

@MainActor
class CameraViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isShowingCamera = false
    @Published var isShowingPhotoPicker = false
    @Published var isShowingPreview = false
    @Published var isAnalyzing = false
    @Published var manualItems: [String] = []
    @Published var currentManualItem = ""
    @Published var analysisResult: AnalysisResult?
    @Published var errorMessage: String?
    @Published var showingAnalysisResults = false
    @Published var analysisProgress: Double = 0.0

    private let aiService: AIService
    private let storageService: StorageService

    init(
        aiService: AIService = .shared,
        storageService: StorageService = .shared
    ) {
        self.aiService = aiService
        self.storageService = storageService
    }

    func presentCamera() {
        isShowingCamera = true
    }

    func presentPhotoPicker() {
        isShowingPhotoPicker = true
    }

    func imageSelected(_ image: UIImage) {
        selectedImage = image
        isShowingCamera = false
        isShowingPhotoPicker = false
        isShowingPreview = true
    }

    func addManualItem() {
        let trimmed = currentManualItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        manualItems.append(trimmed)
        currentManualItem = ""
    }

    func removeManualItem(at index: Int) {
        manualItems.remove(at: index)
    }

    func analyzeImage() async {
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.01  // 1% - Started

        do {
            analysisProgress = 0.15  // 15% - Beginning analysis

            let result = try await aiService.analyzeFridge(
                image: selectedImage,
                manualItems: manualItems
            )

            analysisProgress = 0.95  // 95% - Analysis complete, processing results

            // Check if any ingredients were found
            if result.extractedIngredients.isEmpty && manualItems.isEmpty {
                errorMessage = "No food items detected. Try taking a clearer photo of your fridge or add items manually."
                isAnalyzing = false
                analysisProgress = 0.0
                return
            }

            analysisResult = result
            analysisProgress = 1.0  // 100% - Done

            // DON'T save to storage yet - let user review and add missing items
            // DON'T reset state - navigate to results view instead
            showingAnalysisResults = true
            isAnalyzing = false

        } catch AIServiceError.noAPIKey {
            errorMessage = "Please configure your OpenAI API key in Config.swift to use food detection."
            analysisProgress = 0.0
        } catch AIServiceError.noFoodDetected {
            errorMessage = "No food detected in this image. Please take a photo of your fridge contents or add items manually."
            analysisProgress = 0.0
        } catch AIServiceError.networkError(let error) {
            errorMessage = "Network error: \(error.localizedDescription). Check your internet connection."
            analysisProgress = 0.0
        } catch AIServiceError.apiError(let message) {
            errorMessage = "API error: \(message)"
            analysisProgress = 0.0
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
            analysisProgress = 0.0
        }

        isAnalyzing = false
    }

    func completeAnalysis() async {
        guard let result = analysisResult else { return }

        // Merge new manual items with existing result if user added more
        var updatedResult = result
        if !manualItems.isEmpty {
            updatedResult = AnalysisResult(
                id: result.id,
                extractedIngredients: result.extractedIngredients,
                suggestedRecipes: result.suggestedRecipes,
                date: result.date,
                imageData: result.imageData,
                manuallyAddedItems: result.manuallyAddedItems + manualItems
            )
            analysisResult = updatedResult
        }

        // NOW save to storage
        var analyses = storageService.loadAnalyses()
        analyses.insert(updatedResult, at: 0)
        storageService.saveAnalyses(analyses)

        // Reset state after completion
        resetAfterAnalysis()
    }

    func resetAfterAnalysis() {
        selectedImage = nil
        manualItems.removeAll()
        currentManualItem = ""
        isShowingPreview = false
        showingAnalysisResults = false
    }

    func cancel() {
        selectedImage = nil
        manualItems.removeAll()
        currentManualItem = ""
        isShowingPreview = false
        isShowingCamera = false
        isShowingPhotoPicker = false
    }
}
