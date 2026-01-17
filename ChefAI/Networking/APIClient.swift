//
//  APIClient.swift
//  ChefAI
//
//  HTTP client for communicating with ChefAI Backend
//

import Foundation
import UIKit

// MARK: - API Client Error

enum APIClientError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int, String?)
    case decodingError(Error)
    case imageEncodingFailed
    case unauthorized
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .imageEncodingFailed:
            return "Failed to encode image"
        case .unauthorized:
            return "Unauthorized - check API key"
        case .noData:
            return "No data received from server"
        }
    }
}

// MARK: - API Response Models

struct AnalyzeImageResponse: Codable {
    let success: Bool
    let ingredients: [APIIngredient]
    let message: String?
}

struct GenerateRecipesResponse: Codable {
    let success: Bool
    let recipes: [APIRecipe]
    let message: String?
}

// MARK: - API Models (for decoding server responses)

struct APIIngredient: Codable {
    let id: UUID
    let name: String
    let brandName: String?
    let quantity: String?
    let unit: String?
    let category: String?
    let confidence: Double?
    let nutritionInfo: APINutritionInfo?
    let dateAdded: Date?

    // Convert to app's Ingredient model
    func toIngredient() -> Ingredient {
        Ingredient(
            id: id,
            name: name,
            brandName: brandName,
            quantity: quantity,
            unit: unit,
            category: mapCategory(category),
            confidence: confidence,
            nutritionInfo: nutritionInfo?.toNutritionInfo(),
            dateAdded: dateAdded ?? Date()
        )
    }

    private func mapCategory(_ categoryString: String?) -> IngredientCategory? {
        guard let category = categoryString else { return nil }
        return IngredientCategory(rawValue: category)
    }
}

struct APINutritionInfo: Codable {
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

struct APIRecipe: Codable {
    let id: UUID
    let name: String
    let description: String?
    let instructions: [String]
    let detailedSteps: [APIRecipeStep]?
    let ingredients: [APIRecipeIngredient]
    let imageURL: String?
    let tags: [String]?
    let prepTime: Int?
    let cookTime: Int?
    let servings: Int?
    let difficulty: String?
    let cuisineType: String?
    let nutritionPerServing: APINutritionInfo?
    let tips: [String]?
    let source: APIRecipeSource?
    let dateGenerated: Date?

    // Convert to app's Recipe model
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

struct APIRecipeStep: Codable {
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

struct APIRecipeIngredient: Codable {
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

struct APIRecipeSource: Codable {
    let name: String
    let url: String?
    let author: String?
}

// MARK: - API Client

final class APIClient: @unchecked Sendable {
    static let shared = APIClient()

    // Backend server URL
    private let baseURL: String

    // API Key for authentication
    private let apiKey: String

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        self.baseURL = Config.backendBaseURL
        self.apiKey = Config.backendAPIKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Analyze Image

    /// Analyzes an image and returns detected ingredients
    func analyzeImage(_ image: UIImage) async throws -> [Ingredient] {
        print("📡 APIClient: Sending image to backend for analysis...")

        // Resize image to reduce payload size (max 512px on longest side for Render.com limits)
        let resizedImage = resizeImage(image, maxDimension: 512)

        // Use low compression quality to keep well under payload limits
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.3) else {
            throw APIClientError.imageEncodingFailed
        }

        let base64Image = imageData.base64EncodedString()

        guard let url = URL(string: "\(baseURL)/api/v1/analyze/image") else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let body = ["image": base64Image]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📊 Image size: \(imageData.count) bytes, base64 length: \(base64Image.count)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.noData
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIClientError.unauthorized
            }
            let message = String(data: data, encoding: .utf8)
            let preview = message.map { String($0.prefix(500)) } ?? "nil"
            print("❌ APIClient: Error response preview: \(preview)")
            throw APIClientError.serverError(httpResponse.statusCode, message)
        }

        let apiResponse = try decoder.decode(AnalyzeImageResponse.self, from: data)

        if !apiResponse.success {
            throw APIClientError.serverError(400, apiResponse.message)
        }

        let ingredients = apiResponse.ingredients.map { $0.toIngredient() }
        print("✅ APIClient: Received \(ingredients.count) ingredients from backend")

        return ingredients
    }

    // MARK: - Generate Recipes

    /// Generates recipes from a list of ingredients
    func generateRecipes(
        from ingredients: [Ingredient],
        userProfile: UserProfile? = nil,
        count: Int = 5
    ) async throws -> [Recipe] {
        print("📡 APIClient: Requesting \(count) recipes from backend...")

        guard let url = URL(string: "\(baseURL)/api/v1/recipes/generate") else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        // Build request body
        var ingredientInputs: [[String: Any]] = []
        for ingredient in ingredients {
            var input: [String: Any] = ["name": ingredient.name]
            if let qty = ingredient.quantity { input["quantity"] = qty }
            if let unit = ingredient.unit { input["unit"] = unit }
            if let category = ingredient.category { input["category"] = category.rawValue }
            ingredientInputs.append(input)
        }

        var body: [String: Any] = [
            "ingredients": ingredientInputs,
            "count": count
        ]

        // Add user profile if available
        if let profile = userProfile {
            var profileInput: [String: Any] = [:]
            if let skill = profile.cookingSkillLevel {
                profileInput["cookingSkillLevel"] = skill.rawValue
            }
            if !profile.dietaryRestrictions.isEmpty {
                profileInput["dietaryRestrictions"] = profile.dietaryRestrictions
                    .filter { $0 != .none }
                    .map { $0.rawValue }
            }
            if let time = profile.timeAvailability {
                profileInput["timeAvailability"] = time.maxMinutes
            }
            if let goal = profile.mainGoal {
                profileInput["mainGoal"] = goal.rawValue
            }
            if !profileInput.isEmpty {
                body["userProfile"] = profileInput
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.noData
        }

        print("📥 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw APIClientError.unauthorized
            }
            let message = String(data: data, encoding: .utf8)
            throw APIClientError.serverError(httpResponse.statusCode, message)
        }

        let apiResponse = try decoder.decode(GenerateRecipesResponse.self, from: data)

        if !apiResponse.success {
            throw APIClientError.serverError(400, apiResponse.message)
        }

        let recipes = apiResponse.recipes.map { $0.toRecipe() }
        print("✅ APIClient: Received \(recipes.count) recipes from backend")

        return recipes
    }

    // MARK: - Health Check

    /// Checks if the backend server is reachable
    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            return false
        }

        do {
            let (_, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            print("⚠️ Backend health check failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Image Helpers

    /// Resizes an image to fit within a square of maxDimension, cropping to center if needed
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // First, crop to square from center
        let minDim = min(size.width, size.height)
        let cropRect = CGRect(
            x: (size.width - minDim) / 2,
            y: (size.height - minDim) / 2,
            width: minDim,
            height: minDim
        )

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Now resize the square image to maxDimension x maxDimension
        let targetSize = CGSize(width: maxDimension, height: maxDimension)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        print("📐 Resized image from \(Int(size.width))x\(Int(size.height)) to \(Int(targetSize.width))x\(Int(targetSize.height))")
        return resizedImage
    }
}
