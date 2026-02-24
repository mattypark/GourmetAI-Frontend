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
    case detectingIngredients   // Step 1: Backend API
    case ingredientsDetected    // User review phase
    case generatingRecipes      // Step 2: Backend API
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

enum ScanMode {
    case ingredients   // Fridge scan → ingredient list → recipes
    case dish          // Photo of a cooked dish → single detailed recipe
}

@MainActor
class CameraViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []
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
    @Published var showingMultiImageReview = false

    // Two-step flow state
    @Published var detectedIngredients: [Ingredient] = []
    @Published var isDetectingIngredients = false
    @Published var isGeneratingRecipes = false
    @Published var showingIngredientReview = false

    // Dish scan state
    @Published var scanMode: ScanMode = .ingredients
    @Published var dishScanResult: Recipe?
    @Published var showingDishScanResult = false
    @Published var dishScanName: String = ""

    // Subscription gating
    @Published var showPaywallPrompt = false

    // Authentication state for save
    @Published var needsAuthentication = false

    private let apiClient: APIClient
    private let storageService: StorageService
    private let subscriptionService: SubscriptionService

    init(
        apiClient: APIClient? = nil,
        storageService: StorageService? = nil,
        subscriptionService: SubscriptionService? = nil
    ) {
        self.apiClient = apiClient ?? APIClient.shared
        self.storageService = storageService ?? StorageService.shared
        self.subscriptionService = subscriptionService ?? SubscriptionService.shared
    }

    // MARK: - Multi-Image Management

    /// Backward-compatible computed property for code expecting a single image
    var selectedImage: UIImage? {
        selectedImages.first
    }

    var canAddMoreImages: Bool {
        selectedImages.count < AppConstants.maxCapturedImages
    }

    var remainingImageSlots: Int {
        AppConstants.maxCapturedImages - selectedImages.count
    }

    func addImage(_ image: UIImage) {
        guard selectedImages.count < AppConstants.maxCapturedImages else { return }
        selectedImages.append(image)
    }

    func removeImage(at index: Int) {
        guard index >= 0 && index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }

    // MARK: - Subscription Check

    func checkSubscriptionAndAnalyze() async {
        if subscriptionService.hasAccess {
            await analyzeImage()
        } else {
            showPaywallPrompt = true
        }
    }

    func checkSubscriptionAndDetectIngredients() async {
        if subscriptionService.hasAccess {
            await detectIngredients()
        } else {
            showPaywallPrompt = true
        }
    }

    func presentCamera() {
        isShowingCamera = true
    }

    func presentPhotoPicker() {
        isShowingPhotoPicker = true
    }

    func imageSelected(_ image: UIImage) {
        addImage(image)
        isShowingCamera = false
        isShowingPhotoPicker = false
        isShowingPreview = true
    }

    func addManualItem() {
        let trimmed = currentManualItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // OWASP: Enforce length limit (matches backend validation of 100 chars)
        guard trimmed.count <= 100 else {
            errorMessage = "Ingredient name must be 100 characters or less"
            return
        }

        // Enforce maximum manual items
        guard manualItems.count < AppConstants.maxManualItems else {
            errorMessage = "Maximum of \(AppConstants.maxManualItems) manual items reached"
            return
        }

        manualItems.append(trimmed)
        currentManualItem = ""
    }

    func removeManualItem(at index: Int) {
        manualItems.remove(at: index)
    }

    // MARK: - Multi-Image Analysis (Parallel)

    /// Analyzes multiple images in parallel, collecting successes and tolerating partial failures.
    /// Updates `analysisProgress` as each image completes (0.05 → 0.50 range).
    private func analyzeMultipleImages(_ images: [UIImage]) async throws -> [Ingredient] {
        var allIngredients: [[Ingredient]] = []
        var failureCount = 0
        let totalCount = images.count
        var completedCount = 0

        await withTaskGroup(of: Result<[Ingredient], Error>.self) { group in
            for image in images {
                group.addTask { [apiClient] in
                    do {
                        let ingredients = try await apiClient.analyzeImage(image)
                        return .success(ingredients)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            for await result in group {
                completedCount += 1
                // Progress from 0.05 to 0.50 proportional to completed images
                analysisProgress = 0.05 + Double(completedCount) / Double(totalCount) * 0.45

                switch result {
                case .success(let ingredients):
                    allIngredients.append(ingredients)
                case .failure:
                    failureCount += 1
                }
            }
        }

        // Handle partial or total failure
        if allIngredients.isEmpty {
            // All failed — throw the generic error so callers handle it
            throw APIClientError.serverError(500, "No food detected in any of the images.")
        }

        if failureCount > 0 {
            let successCount = totalCount - failureCount
            errorMessage = "\(successCount) of \(totalCount) photos analyzed successfully"
        }

        let flatIngredients = allIngredients.flatMap { $0 }
        return deduplicateIngredients(flatIngredients)
    }

    /// Deduplicates ingredients by lowercased name, keeping highest confidence and merging fields
    private func deduplicateIngredients(_ ingredients: [Ingredient]) -> [Ingredient] {
        var seen: [String: Ingredient] = [:]

        for ingredient in ingredients {
            let key = ingredient.name.lowercased().trimmingCharacters(in: .whitespaces)

            if let existing = seen[key] {
                let existingConfidence = existing.confidence ?? 0.0
                let newConfidence = ingredient.confidence ?? 0.0

                if newConfidence > existingConfidence {
                    var better = ingredient
                    if better.quantity == nil && existing.quantity != nil {
                        better.quantity = existing.quantity
                        better.unit = existing.unit
                    }
                    if better.category == nil && existing.category != nil {
                        better.category = existing.category
                    }
                    seen[key] = better
                } else {
                    var kept = existing
                    if kept.quantity == nil && ingredient.quantity != nil {
                        kept.quantity = ingredient.quantity
                        kept.unit = ingredient.unit
                    }
                    if kept.category == nil && ingredient.category != nil {
                        kept.category = ingredient.category
                    }
                    seen[key] = kept
                }
            } else {
                seen[key] = ingredient
            }
        }

        return Array(seen.values).sorted { ($0.confidence ?? 0) > ($1.confidence ?? 0) }
    }

    // MARK: - Step 1: Detect Ingredients (Backend API)

    func detectIngredients() async {
        guard !selectedImages.isEmpty else {
            errorMessage = "No images selected"
            return
        }

        isDetectingIngredients = true
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.05
        analysisStatus = .detectingIngredients

        do {
            let ingredients = try await analyzeMultipleImages(selectedImages)

            // Add manual items as ingredients
            var allIngredients = ingredients
            for item in manualItems {
                allIngredients.append(Ingredient(name: item, confidence: 1.0))
            }

            detectedIngredients = allIngredients
            analysisProgress = 0.5
            analysisStatus = .ingredientsDetected

            showingIngredientReview = true

        } catch APIClientError.unauthorized {
            errorMessage = "Unauthorized - check your API key configuration"
        } catch APIClientError.rateLimited(let retryAfter) {
            errorMessage = "Too many requests. Please wait \(retryAfter) seconds and try again."
            analysisStatus = .idle
            analysisProgress = 0.0
        } catch APIClientError.serverError(_, let message) {
            if message?.contains("No food detected") == true || message?.contains("noFoodDetected") == true {
                if !manualItems.isEmpty {
                    detectedIngredients = manualItems.map { Ingredient(name: $0, confidence: 1.0) }
                    analysisStatus = .ingredientsDetected
                    showingIngredientReview = true
                } else {
                    errorMessage = "No food detected in images. Try clearer photos or add items manually."
                    analysisStatus = .idle
                    analysisProgress = 0.0
                }
            } else {
                errorMessage = message ?? "Server error occurred"
                analysisStatus = .idle
                analysisProgress = 0.0
            }
        } catch APIClientError.networkError {
            errorMessage = "Connection failed - please check your internet and ensure the backend server is running"
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

    // MARK: - Step 2: Generate Recipes (Backend API)

    func generateRecipesFromIngredients(userProfile: UserProfile? = nil) async {
        guard !detectedIngredients.isEmpty else {
            errorMessage = "No ingredients to generate recipes from"
            return
        }

        isGeneratingRecipes = true
        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.55
        analysisStatus = .generatingRecipes

        do {
            let profile = userProfile ?? storageService.loadUserProfile()

            let recipes = try await apiClient.generateRecipes(
                from: detectedIngredients,
                userProfile: profile,
                count: 5
            )

            let imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
            analysisResult = AnalysisResult(
                extractedIngredients: detectedIngredients,
                suggestedRecipes: recipes,
                imagesData: imagesData,
                manuallyAddedItems: manualItems
            )

            analysisProgress = 1.0
            analysisStatus = .finished

            showingAnalysisResults = true

        } catch APIClientError.unauthorized {
            errorMessage = "Unauthorized - check your API key configuration"
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        } catch APIClientError.rateLimited(let retryAfter) {
            errorMessage = "Too many requests. Please wait \(retryAfter) seconds and try again."
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        } catch APIClientError.serverError(_, let message) {
            errorMessage = message ?? "Failed to generate recipes"
            analysisStatus = .ingredientsDetected
            analysisProgress = 0.5
        } catch APIClientError.networkError {
            errorMessage = "Connection failed - please check your internet"
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

    // MARK: - Combined Analysis (Two-Step: Backend API)

    func analyzeImage() async {
        guard !selectedImages.isEmpty else {
            errorMessage = "No images selected"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.05
        analysisStatus = .detectingIngredients

        // STEP 1: Detect ingredients (Backend API) — parallel for all images
        do {
            let ingredients = try await analyzeMultipleImages(selectedImages)

            // Add manual items as ingredients
            var allIngredients = ingredients
            for item in manualItems {
                allIngredients.append(Ingredient(name: item, confidence: 1.0))
            }

            if allIngredients.isEmpty {
                errorMessage = "No food items detected. Try taking clearer photos or add items manually."
                isAnalyzing = false
                analysisProgress = 0.0
                analysisStatus = .idle
                return
            }

            detectedIngredients = allIngredients
            analysisProgress = 0.5
            analysisStatus = .ingredientsDetected

            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

        } catch APIClientError.unauthorized {
            errorMessage = "Unauthorized - check your API key configuration"
            analysisProgress = 0.0
            analysisStatus = .idle
            isAnalyzing = false
            return
        } catch APIClientError.rateLimited(let retryAfter) {
            errorMessage = "Too many requests. Please wait \(retryAfter) seconds and try again."
            analysisProgress = 0.0
            analysisStatus = .idle
            isAnalyzing = false
            return
        } catch APIClientError.serverError(_, let message) {
            if message?.contains("No food detected") == true {
                if !manualItems.isEmpty {
                    detectedIngredients = manualItems.map { Ingredient(name: $0, confidence: 1.0) }
                } else {
                    errorMessage = "No food detected in images. Try clearer photos or add items manually."
                    analysisProgress = 0.0
                    analysisStatus = .idle
                    isAnalyzing = false
                    return
                }
            } else {
                errorMessage = message ?? "Server error occurred"
                analysisProgress = 0.0
                analysisStatus = .idle
                isAnalyzing = false
                return
            }
        } catch APIClientError.networkError {
            errorMessage = "Connection failed - is the backend server running? (localhost:8080)"
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
        analysisProgress = 0.90

        let imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
        analysisResult = AnalysisResult(
            extractedIngredients: detectedIngredients,
            suggestedRecipes: [],
            imagesData: imagesData,
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
            let recipes = try await apiClient.generateRecipes(
                from: ingredients,
                userProfile: profile,
                count: 5
            )

            let imagesData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.7) }
            analysisResult = AnalysisResult(
                id: analysisResult?.id ?? UUID(),
                extractedIngredients: ingredients,
                suggestedRecipes: recipes,
                date: analysisResult?.date ?? Date(),
                imagesData: imagesData,
                manuallyAddedItems: manualItems
            )

            analysisStatus = .finished

            var analyses = storageService.loadAnalyses()
            analyses.removeAll { $0.id == analysisResult?.id }
            if let result = analysisResult {
                analyses.insert(result, at: 0)
                storageService.saveAnalyses(analyses)
                #if DEBUG
                print("💾 Saved analysis with \(result.extractedIngredients.count) ingredients and \(result.suggestedRecipes.count) recipes")
                #endif
            }

        } catch APIClientError.unauthorized {
            errorMessage = "Unauthorized - check your API key configuration"
        } catch APIClientError.rateLimited(let retryAfter) {
            errorMessage = "Too many requests. Please wait \(retryAfter) seconds and try again."
        } catch APIClientError.serverError(_, let message) {
            errorMessage = message ?? "Failed to generate recipes"
        } catch APIClientError.networkError {
            errorMessage = "Connection failed - please check your internet"
        } catch {
            errorMessage = "Failed to generate recipes: \(error.localizedDescription)"
        }

        isGeneratingRecipes = false
        isAnalyzing = false
    }

    func completeAnalysis() async {
        guard let result = analysisResult else { return }

        var updatedResult = result
        if !manualItems.isEmpty {
            updatedResult = AnalysisResult(
                id: result.id,
                extractedIngredients: result.extractedIngredients,
                suggestedRecipes: result.suggestedRecipes,
                date: result.date,
                imagesData: result.imagesData,
                manuallyAddedItems: result.manuallyAddedItems + manualItems
            )
            analysisResult = updatedResult
        }

        var analyses = storageService.loadAnalyses()
        analyses.insert(updatedResult, at: 0)
        storageService.saveAnalyses(analyses)
    }

    /// Save analysis without generating recipes (just ingredients + image)
    func saveAnalysisOnly() async {
        guard let result = analysisResult else { return }

        var updatedResult = result
        if !manualItems.isEmpty {
            updatedResult = AnalysisResult(
                id: result.id,
                extractedIngredients: result.extractedIngredients,
                suggestedRecipes: [],
                date: result.date,
                imagesData: result.imagesData,
                manuallyAddedItems: result.manuallyAddedItems + manualItems
            )
            analysisResult = updatedResult
        }

        // Always save locally
        var analyses = storageService.loadAnalyses()
        analyses.insert(updatedResult, at: 0)
        storageService.saveAnalyses(analyses)

        // Also sync to Supabase if authenticated
        let supabase = SupabaseManager.shared
        if supabase.isAuthenticated {
            do {
                let ingredientItems = updatedResult.extractedIngredients.map {
                    IngredientItem(name: $0.name, quantity: $0.quantity, unit: $0.unit)
                }
                try await supabase.saveIngredientHistory(ingredients: ingredientItems)
                #if DEBUG
                print("Saved ingredients to Supabase")
                #endif
            } catch {
                #if DEBUG
                print("Failed to save to Supabase: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Dish Scan (Photo of cooked meal → single detailed recipe)

    func analyzeDishFromImage() async {
        guard let image = selectedImages.first else {
            errorMessage = "No image selected"
            return
        }

        isAnalyzing = true
        errorMessage = nil
        analysisProgress = 0.1
        analysisStatus = .detectingIngredients

        do {
            analysisProgress = 0.3
            let (dishName, recipe) = try await apiClient.analyzeDish(image)
            analysisProgress = 0.9

            dishScanName = dishName
            dishScanResult = recipe

            analysisProgress = 1.0
            analysisStatus = .finished
            showingDishScanResult = true

        } catch APIClientError.unauthorized {
            errorMessage = "Unauthorized - check your API key configuration"
            analysisStatus = .idle
            analysisProgress = 0.0
        } catch APIClientError.rateLimited(let retryAfter) {
            errorMessage = "Too many requests. Please wait \(retryAfter) seconds and try again."
            analysisStatus = .idle
            analysisProgress = 0.0
        } catch APIClientError.serverError(_, let message) {
            errorMessage = message ?? "Could not identify the dish. Try a clearer photo."
            analysisStatus = .idle
            analysisProgress = 0.0
        } catch APIClientError.networkError {
            errorMessage = "Connection failed - please check your internet connection."
            analysisStatus = .idle
            analysisProgress = 0.0
        } catch {
            errorMessage = "Failed to analyze dish: \(error.localizedDescription)"
            analysisStatus = .idle
            analysisProgress = 0.0
        }

        isAnalyzing = false
    }

    func resetAfterAnalysis() {
        selectedImages = []
        manualItems.removeAll()
        currentManualItem = ""
        isShowingPreview = false
        showingAnalysisResults = false
        showingIngredientReview = false
        showingMultiImageReview = false
        showingDishScanResult = false
        dishScanResult = nil
        dishScanName = ""
        analysisStatus = .idle
        analysisProgress = 0.0
        detectedIngredients = []
        isDetectingIngredients = false
        isGeneratingRecipes = false
    }

    func cancel() {
        selectedImages = []
        manualItems.removeAll()
        currentManualItem = ""
        isShowingPreview = false
        isShowingCamera = false
        isShowingPhotoPicker = false
        showingMultiImageReview = false
        showingDishScanResult = false
        dishScanResult = nil
        dishScanName = ""
        scanMode = .ingredients
    }
}
