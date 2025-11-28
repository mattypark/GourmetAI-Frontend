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

        do {
            let result = try await aiService.analyzeFridge(
                image: selectedImage,
                manualItems: manualItems
            )

            analysisResult = result

            // Save to storage
            var analyses = storageService.loadAnalyses()
            analyses.insert(result, at: 0)
            storageService.saveAnalyses(analyses)

            // Reset state
            resetAfterAnalysis()
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    func resetAfterAnalysis() {
        selectedImage = nil
        manualItems.removeAll()
        currentManualItem = ""
        isShowingPreview = false
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
