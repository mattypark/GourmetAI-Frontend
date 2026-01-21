//
//  RecipeJobService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-20.
//

import Foundation
import Combine

@MainActor
class RecipeJobService: ObservableObject {
    static let shared = RecipeJobService()

    @Published private(set) var activeJobs: [RecipeJob] = []
    @Published private(set) var completedJobs: [RecipeJob] = []

    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let storageKey = "chefai_recipe_jobs"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadJobs()
    }

    // MARK: - Public Methods

    /// Start a new recipe generation job
    @discardableResult
    func startRecipeGeneration(
        analysisId: UUID,
        ingredients: [Ingredient],
        thumbnailData: Data?
    ) -> RecipeJob {
        let job = RecipeJob(
            analysisId: analysisId,
            ingredients: ingredients.map { $0.name },
            thumbnailData: thumbnailData
        )

        activeJobs.insert(job, at: 0)
        saveJobs()

        // Start the recipe generation task
        let task = Task {
            await generateRecipes(jobId: job.id)
        }
        tasks[job.id] = task

        print("🚀 RecipeJobService: Started job \(job.id) with \(ingredients.count) ingredients")
        return job
    }

    /// Cancel a job
    func cancelJob(_ jobId: UUID) {
        tasks[jobId]?.cancel()
        tasks.removeValue(forKey: jobId)
        activeJobs.removeAll { $0.id == jobId }
        saveJobs()
        print("❌ RecipeJobService: Cancelled job \(jobId)")
    }

    /// Get a job by ID
    func job(byId id: UUID) -> RecipeJob? {
        activeJobs.first { $0.id == id } ?? completedJobs.first { $0.id == id }
    }

    /// Clear completed jobs
    func clearCompletedJobs() {
        completedJobs.removeAll()
        saveJobs()
    }

    // MARK: - Recipe Generation (with simulated status updates)

    private func generateRecipes(jobId: UUID) async {
        guard let jobIndex = activeJobs.firstIndex(where: { $0.id == jobId }) else {
            return
        }

        let job = activeJobs[jobIndex]

        guard let url = URL(string: "\(Config.backendBaseURL)/api/v1/recipes/generate-stream") else {
            updateJob(jobId: jobId, status: .error, errorMessage: "Invalid URL")
            return
        }

        // Step 1: Thinking
        updateJobStatus(jobId: jobId, status: .thinking)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay for UX

        // Check for cancellation
        if Task.isCancelled { return }

        // Step 2: Searching
        updateJobStatus(jobId: jobId, status: .searching)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.backendAPIKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 120

        // Build request body
        let body: [String: Any] = [
            "ingredients": job.ingredients.map { ["name": $0] },
            "count": 5
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            updateJob(jobId: jobId, status: .error, errorMessage: "Failed to encode request")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check for cancellation
            if Task.isCancelled { return }

            guard let httpResponse = response as? HTTPURLResponse else {
                updateJob(jobId: jobId, status: .error, errorMessage: "Invalid response")
                return
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                updateJob(jobId: jobId, status: .error, errorMessage: "Server error: \(httpResponse.statusCode) - \(errorMessage)")
                return
            }

            // Parse response
            let apiResponse = try decoder.decode(GenerateRecipesWithSourcesResponse.self, from: data)

            guard apiResponse.success else {
                updateJob(jobId: jobId, status: .error, errorMessage: apiResponse.message ?? "Unknown error")
                return
            }

            // Step 3: Sources found
            let sources = apiResponse.sources
            updateJobWithSources(jobId: jobId, status: .sourcesFound, sourceCount: apiResponse.sourceCount, sources: sources)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay for UX

            // Check for cancellation
            if Task.isCancelled { return }

            // Step 4: Calculating
            updateJobStatus(jobId: jobId, status: .calculating)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay for UX

            // Check for cancellation
            if Task.isCancelled { return }

            // Step 5: Finished - convert recipes
            let recipes = apiResponse.recipes.map { $0.toRecipe() }
            finishJob(jobId: jobId, recipes: recipes, sources: sources, sourceCount: apiResponse.sourceCount)

        } catch {
            if !Task.isCancelled {
                updateJob(jobId: jobId, status: .error, errorMessage: error.localizedDescription)
            }
        }
    }

    private func updateJobStatus(jobId: UUID, status: RecipeJobStatus) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else {
            return
        }
        activeJobs[index].status = status
        saveJobs()
        print("📡 RecipeJobService: Status update for job \(jobId): \(status.rawValue)")
    }

    private func updateJobWithSources(jobId: UUID, status: RecipeJobStatus, sourceCount: Int, sources: [RecipeSourceInfo]) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else {
            return
        }
        activeJobs[index].status = status
        activeJobs[index].sourceCount = sourceCount
        activeJobs[index].sources = sources
        saveJobs()
        print("📡 RecipeJobService: Sources found for job \(jobId): \(sourceCount)")
    }

    private func finishJob(jobId: UUID, recipes: [Recipe], sources: [RecipeSourceInfo], sourceCount: Int) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else {
            return
        }

        activeJobs[index].status = .finished
        activeJobs[index].recipes = recipes
        activeJobs[index].sources = sources
        activeJobs[index].sourceCount = sourceCount
        activeJobs[index].completedAt = Date()

        // Move to completed jobs
        let completedJob = activeJobs.remove(at: index)
        completedJobs.insert(completedJob, at: 0)

        // Clean up task
        tasks.removeValue(forKey: jobId)

        saveJobs()
        print("✅ RecipeJobService: Job \(jobId) completed with \(recipes.count) recipes")
    }

    private func updateJob(jobId: UUID, status: RecipeJobStatus, errorMessage: String? = nil) {
        guard let index = activeJobs.firstIndex(where: { $0.id == jobId }) else {
            return
        }

        activeJobs[index].status = status
        activeJobs[index].errorMessage = errorMessage

        if status == .error || status == .finished {
            activeJobs[index].completedAt = Date()
            let job = activeJobs.remove(at: index)
            completedJobs.insert(job, at: 0)
            tasks.removeValue(forKey: jobId)
        }

        saveJobs()
    }

    // MARK: - Persistence

    private func loadJobs() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("📦 RecipeJobService: No saved jobs found")
            return
        }

        do {
            let allJobs = try decoder.decode([RecipeJob].self, from: data)

            // Separate active and completed jobs
            activeJobs = allJobs.filter { $0.status.isProcessing }
            completedJobs = allJobs.filter { !$0.status.isProcessing }

            // Restart any active jobs that were interrupted
            for job in activeJobs {
                let task = Task {
                    await generateRecipes(jobId: job.id)
                }
                tasks[job.id] = task
            }

            print("📦 RecipeJobService: Loaded \(activeJobs.count) active, \(completedJobs.count) completed jobs")
        } catch {
            print("❌ RecipeJobService: Failed to load jobs: \(error)")
        }
    }

    private func saveJobs() {
        do {
            let allJobs = activeJobs + completedJobs
            let data = try encoder.encode(allJobs)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ RecipeJobService: Failed to save jobs: \(error)")
        }
    }
}

// MARK: - API Response Model

struct GenerateRecipesWithSourcesResponse: Codable {
    let success: Bool
    let recipes: [APIRecipeForJob]
    let sources: [RecipeSourceInfo]
    let sourceCount: Int
    let message: String?
}

// API Recipe model for parsing (similar to SSEStatusEvent's nested model)
struct APIRecipeForJob: Codable {
    let id: UUID
    let name: String
    let description: String?
    let instructions: [String]
    let detailedSteps: [APIRecipeStepForJob]?
    let ingredients: [APIRecipeIngredientForJob]
    let imageURL: String?
    let tags: [String]?
    let prepTime: Int?
    let cookTime: Int?
    let servings: Int?
    let difficulty: String?
    let cuisineType: String?
    let nutritionPerServing: APINutritionInfoForJob?
    let tips: [String]?
    let source: APIRecipeSourceForJob?
    let dateGenerated: Date?

    func toRecipe() -> Recipe {
        let recipeIngredients = ingredients.map { $0.toRecipeIngredient() }
        let recipeSteps = detailedSteps?.map { $0.toRecipeStep() } ?? []

        var nutritionInfo: NutritionInfo?
        if let nutrition = nutritionPerServing {
            nutritionInfo = nutrition.toNutritionInfo()
        }

        var recipeSource: RecipeSource?
        if let src = source {
            recipeSource = RecipeSource(name: src.name, url: src.url, author: src.author)
        }

        let difficultyLevel: DifficultyLevel?
        switch difficulty?.lowercased() {
        case "easy", "beginner", "simple":
            difficultyLevel = .easy
        case "medium", "intermediate":
            difficultyLevel = .medium
        case "hard", "difficult", "advanced":
            difficultyLevel = .hard
        case "expert", "professional":
            difficultyLevel = .expert
        default:
            difficultyLevel = .easy
        }

        return Recipe(
            id: id,
            name: name,
            description: description,
            instructions: instructions,
            detailedSteps: recipeSteps,
            ingredients: recipeIngredients,
            imageURL: imageURL,
            tags: tags ?? [],
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: difficultyLevel,
            cuisineType: cuisineType,
            nutritionPerServing: nutritionInfo,
            tips: tips ?? [],
            source: recipeSource,
            dateGenerated: dateGenerated ?? Date()
        )
    }
}

struct APIRecipeStepForJob: Codable {
    let id: UUID?
    let stepNumber: Int
    let instruction: String
    let duration: Int?
    let technique: String?
    let gifURL: String?
    let videoURL: String?
    let tips: [String]?

    func toRecipeStep() -> RecipeStep {
        RecipeStep(
            id: id ?? UUID(),
            stepNumber: stepNumber,
            instruction: instruction,
            duration: duration,
            technique: technique,
            gifURL: gifURL,
            videoURL: videoURL,
            tips: tips ?? []
        )
    }
}

struct APIRecipeIngredientForJob: Codable {
    let id: UUID?
    let name: String
    let amount: String
    let unit: String?
    let isOptional: Bool?
    let substitutes: [String]?

    func toRecipeIngredient() -> RecipeIngredient {
        RecipeIngredient(
            id: id ?? UUID(),
            name: name,
            amount: amount,
            unit: unit,
            isOptional: isOptional ?? false,
            substitutes: substitutes ?? []
        )
    }
}

struct APINutritionInfoForJob: Codable {
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sodium: Double?
    let sugar: Double?
    let servingSize: String?

    func toNutritionInfo() -> NutritionInfo {
        NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sodium: sodium,
            sugar: sugar,
            servingSize: servingSize
        )
    }
}

struct APIRecipeSourceForJob: Codable {
    let name: String
    let url: String?
    let author: String?
}
