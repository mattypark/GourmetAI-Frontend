//
//  CameraViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Analysis Status Enum

enum AnalysisStatus: Equatable {
    case idle
    case detectingIngredients   // Step 1: OpenAI Vision
    case ingredientsDetected    // User review phase
    case generatingRecipes      // Step 2: OpenAI
    case finished

    var displayText: String {
        switch self {
        case .idle: return ""
        case .detectingIngredients: return "Detecting ingredients..."
        case .ingredientsDetected: return "Review ingredients"
        case .generatingRecipes: return "Searching for recipes..."
        case .finished: return "Found recipes!"
        }
    }

    var isFinished: Bool {
        self == .finished
    }
}

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
    @Published var analysisStatus: AnalysisStatus = .idle

    // Two-step flow state
    @Published var detectedIngredients: [Ingredient] = []
    @Published var isDetectingIngredients = false
    @Published var isGeneratingRecipes = false
    @Published var showingIngredientReview = false

    private let aiService: AIService
    private let storageService: StorageService

    init(
        aiService: AIService? = nil,
        storageService: StorageService? = nil
    ) {
        self.aiService = aiService ?? AIService.shared
        self.storageService = storageService ?? StorageService.shared
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

    // MARK: - Step 1: Detect Ingredients (Gemini Flash)

    func detectIngredients() async {
        guard let image = selectedImage else {
            errorMessage = "No image selected"
            return
        }

        isDetectingIngredients = true
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.1
        analysisStatus = .detectingIngredients

        do {
            // Call Gemini Flash API to detect ingredients only
            let ingredients = try await aiService.analyzeImageWithGemini(image)

            // Add manual items as ingredients
            var allIngredients = ingredients
            for item in manualItems {
                allIngredients.append(Ingredient(name: item, confidence: 1.0))
            }

            detectedIngredients = allIngredients
            analysisProgress = 0.5
            analysisStatus = .ingredientsDetected

            // Navigate to ingredient review screen
            showingIngredientReview = true

        } catch AIServiceError.noAPIKey {
            errorMessage = "Please configure your Gemini API key in Config.swift"
        } catch AIServiceError.noFoodDetected {
            // Allow user to continue with manual items only
            if !manualItems.isEmpty {
                detectedIngredients = manualItems.map { Ingredient(name: $0, confidence: 1.0) }
                analysisStatus = .ingredientsDetected
                showingIngredientReview = true
            } else {
                errorMessage = "No food detected in image. Try a clearer photo or add items manually."
                analysisStatus = .idle
                analysisProgress = 0.0
            }
        } catch AIServiceError.networkError {
            errorMessage = "API connection failed - please check your internet"
            analysisStatus = .idle
            analysisProgress = 0.0
        } catch {
            errorMessage = "Failed to detect ingredients: \(error.localizedDescription)"
            analysisStatus = .idle
            analysisProgress = 0.0
        }

        isDetectingIngredients = false
        isAnalyzing = false
    }

    // MARK: - Step 2: Generate Recipes (Tavily + Gemini)

    func generateRecipesFromIngredients(userProfile: UserProfile? = nil) async {
        guard !detectedIngredients.isEmpty else {
            errorMessage = "No ingredients to generate recipes from"
            return
        }

        isGeneratingRecipes = true
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.6
        analysisStatus = .generatingRecipes

        do {
            // Get user profile from storage if not provided
            let profile = userProfile ?? storageService.loadUserProfile()

            // Call Tavily + Gemini to generate recipes
            let recipes = try await aiService.generateRecipesWithTavily(
                from: detectedIngredients,
                userProfile: profile,
                count: 5
            )

            // Create analysis result with ingredients and recipes
            let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
            analysisResult = AnalysisResult(
                extractedIngredients: detectedIngredients,
                suggestedRecipes: recipes,
                imageData: imageData,
                manuallyAddedItems: manualItems
            )

            analysisProgress = 1.0
            analysisStatus = .finished

            // Navigate to results view
            showingAnalysisResults = true

        } catch AIServiceError.noAPIKey {
            errorMessage = "Please configure your API keys in Config.swift"
            analysisStatus = .ingredientsDetected  // Go back to review state
            analysisProgress = 0.5
        } catch AIServiceError.recipeGenerationFailed {
            errorMessage = "Unable to generate recipes - please try again"
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        } catch AIServiceError.apiError(let message) {
            errorMessage = "Recipe generation error: \(message)"
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        } catch AIServiceError.networkError {
            errorMessage = "API connection failed - please check your internet"
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        } catch {
            errorMessage = "Failed to generate recipes: \(error.localizedDescription)"
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        }

        isGeneratingRecipes = false
        isAnalyzing = false
    }

    // MARK: - Combined Analysis (Two-Step: Gemini + Tavily)

    func analyzeImage() async {
        guard let image = selectedImage else {
            errorMessage = "No image selected"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.1
        analysisStatus = .detectingIngredients

        // STEP 1: Detect ingredients (Gemini Flash)
        do {
            let ingredients = try await aiService.analyzeImageWithGemini(image)

            // Add manual items as ingredients
            var allIngredients = ingredients
            for item in manualItems {
                allIngredients.append(Ingredient(name: item, confidence: 1.0))
            }

            // Check if any ingredients were found
            if allIngredients.isEmpty {
                errorMessage = "No food items detected. Try taking a clearer photo or add items manually."
                isAnalyzing = false
                analysisProgress = 0.0
                analysisStatus = .idle
                return
            }

            detectedIngredients = allIngredients
            analysisProgress = 0.5
            analysisStatus = .ingredientsDetected

            // Brief pause to show ingredients detected state
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

        } catch AIServiceError.noAPIKey {
            errorMessage = "Please configure your API keys in Config.swift"
            analysisProgress = 0.0
            analysisStatus = .idle
            isAnalyzing = false
            return
        } catch AIServiceError.noFoodDetected {
            // Allow user to continue with manual items only
            if !manualItems.isEmpty {
                detectedIngredients = manualItems.map { Ingredient(name: $0, confidence: 1.0) }
            } else {
                errorMessage = "No food detected in image. Try a clearer photo or add items manually."
                analysisProgress = 0.0
                analysisStatus = .idle
                isAnalyzing = false
                return
            }
        } catch AIServiceError.networkError {
            errorMessage = "API connection failed - please check your internet"
            analysisProgress = 0.0
            analysisStatus = .idle
            isAnalyzing = false
            return
        } catch {
            errorMessage = "Failed to detect ingredients: \(error.localizedDescription)"
            analysisProgress = 0.0
            analysisStatus = .idle
            isAnalyzing = false
            return
        }

        // Step 2 is triggered manually when user taps "Generate Recipes" button
        // Create analysisResult with just ingredients (no recipes yet)
        let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
        analysisResult = AnalysisResult(
            extractedIngredients: detectedIngredients,
            suggestedRecipes: [],  // Empty - will be populated when user generates recipes
            imageData: imageData,
            manuallyAddedItems: manualItems
        )

        analysisProgress = 1.0
        analysisStatus = .ingredientsDetected
        showingAnalysisResults = true
        isAnalyzing = false
    }

    // MARK: - Generate Recipes with Selected Ingredients

    func generateRecipesWithSelectedIngredients(_ ingredients: [Ingredient]) async {
        isGeneratingRecipes = true
        isAnalyzing = true
        errorMessage = nil
        analysisStatus = .generatingRecipes

        do {
            let profile = storageService.loadUserProfile()
            let recipes = try await aiService.generateRecipesWithTavily(
                from: ingredients,
                userProfile: profile,
                count: 5
            )

            // Update analysisResult with the selected ingredients and new recipes
            let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
            analysisResult = AnalysisResult(
                id: analysisResult?.id ?? UUID(),
                extractedIngredients: ingredients,
                suggestedRecipes: recipes,
                date: analysisResult?.date ?? Date(),
                imageData: imageData,
                manuallyAddedItems: manualItems
            )

            analysisStatus = .finished

            // Save the updated analysis with recipes
            var analyses = storageService.loadAnalyses()
            // Remove any existing analysis with same ID
            analyses.removeAll { $0.id == analysisResult?.id }
            if let result = analysisResult {
                analyses.insert(result, at: 0)
                storageService.saveAnalyses(analyses)
                print("💾 Saved analysis with \(result.extractedIngredients.count) ingredients and \(result.suggestedRecipes.count) recipes")
            }

        } catch AIServiceError.noAPIKey {
            errorMessage = "Please configure your API keys in Config.swift"
        } catch AIServiceError.recipeGenerationFailed {
            errorMessage = "Unable to generate recipes - please try again"
        } catch AIServiceError.apiError(let message) {
            errorMessage = "Recipe search error: \(message)"
        } catch AIServiceError.networkError {
            errorMessage = "Connection failed - please check your internet"
        } catch {
            errorMessage = "Failed to generate recipes: \(error.localizedDescription)"
        }

        isGeneratingRecipes = false
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

        // NOTE: Do NOT call resetAfterAnalysis() here.
        // Let the view call dismiss() first, then reset state via onDismiss callback
        // to avoid race condition with fullScreenCover binding.
    }

    func resetAfterAnalysis() {
        selectedImage = nil
        manualItems.removeAll()
        currentManualItem = ""
        isShowingPreview = false
        showingAnalysisResults = false
        showingIngredientReview = false
        analysisStatus = .idle
        analysisProgress = 0.0
        detectedIngredients = []
        isDetectingIngredients = false
        isGeneratingRecipes = false
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
