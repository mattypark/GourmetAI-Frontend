//
//  AIService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import UIKit

// MARK: - AI Service Error

enum AIServiceError: LocalizedError {
    case noAPIKey
    case imageEncodingFailed
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case noFoodDetected
    case jsonParsingError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured. Please add your API key to Config.swift"
        case .imageEncodingFailed:
            return "Failed to encode image for analysis"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let message):
            return "API error: \(message)"
        case .noFoodDetected:
            return "No food items detected in this image"
        case .jsonParsingError:
            return "Failed to parse AI response"
        }
    }
}

// MARK: - AI Service

actor AIService {
    static let shared = AIService()

    private init() {}

    /// Analyzes fridge photo using OpenAI GPT-4 Vision API
    func analyzeFridge(
        image: UIImage?,
        manualItems: [String]
    ) async throws -> AnalysisResult {
        print("🤖 Starting fridge analysis...")

        // If there's an image, call OpenAI API
        var aiResult: AIAnalysisResult?
        if let image = image {
            aiResult = try await callOpenAI(image: image)
        }

        // Convert AI result to app models
        let ingredients = convertIngredients(from: aiResult)
        let recipes = try await generateRecipes(
            from: aiResult,
            manualItems: manualItems,
            allIngredients: ingredients.map { $0.name } + manualItems
        )

        // Compress image for storage
        let imageData = image?.jpegData(compressionQuality: 0.7)

        let result = AnalysisResult(
            extractedIngredients: ingredients,
            suggestedRecipes: recipes,
            imageData: imageData,
            manuallyAddedItems: manualItems
        )

        print("✅ Analysis complete: \(ingredients.count) ingredients, \(recipes.count) recipes")
        return result
    }

    // MARK: - OpenAI API Integration

    private nonisolated func callOpenAI(image: UIImage) async throws -> AIAnalysisResult {
        // Check API key
        guard Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        // Convert image to base64
        guard let base64Image = convertToBase64(image: image) else {
            throw AIServiceError.imageEncodingFailed
        }

        // Build request
        let request = buildRequest(base64Image: base64Image)

        // Make API call
        guard let url = URL(string: Config.apiEndpoint) else {
            throw AIServiceError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        print("📡 Calling OpenAI API...")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
               let error = errorResponse.error {
                throw AIServiceError.apiError(error.message)
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        let decoder = JSONDecoder()
        let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)

        guard let choice = openAIResponse.choices.first else {
            throw AIServiceError.invalidResponse
        }

        print("📊 Tokens used: \(openAIResponse.usage?.totalTokens ?? 0)")

        // Parse JSON content from GPT-4
        let content = choice.message.content
        print("🔍 AI Response: \(content.prefix(200))...")

        return try parseAIResponse(content)
    }

    // MARK: - Helper Methods

    private nonisolated func convertToBase64(image: UIImage) -> String? {
        // Resize image to reduce API costs
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale: CGFloat

        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let resizedImage = resizedImage,
              let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }

        return imageData.base64EncodedString()
    }

    private nonisolated func buildRequest(base64Image: String) -> OpenAIRequest {
        let prompt = buildPrompt()

        return OpenAIRequest(
            model: Config.openAIModel,
            messages: [
                OpenAIRequest.Message(
                    role: "user",
                    content: [
                        OpenAIRequest.Content(
                            type: "text",
                            text: prompt,
                            imageUrl: nil
                        ),
                        OpenAIRequest.Content(
                            type: "image_url",
                            text: nil,
                            imageUrl: OpenAIRequest.ImageURL(
                                url: "data:image/jpeg;base64,\(base64Image)"
                            )
                        )
                    ]
                )
            ],
            maxTokens: Config.maxTokens,
            temperature: Config.temperature
        )
    }

    private nonisolated func buildPrompt() -> String {
        """
        You are a food recognition AI for a recipe app. Analyze this image and:

        1. Determine if there is ANY FOOD visible in the image
        2. If NO FOOD is detected (e.g., flowers, furniture, empty fridge, non-food items), respond with:
           {"hasFood": false, "ingredients": [], "suggestedRecipes": [], "message": "No food items detected in this image."}

        3. If FOOD is detected, extract:
           - All visible food ingredients with confidence scores (0.0-1.0)
           - Categorize each ingredient (produce, meat, dairy, grains, condiments, etc.)
           - Suggest 3 practical recipes using these ingredients
           - Include prep time (minutes), cook time (minutes), servings, difficulty (easy/medium/hard) for each recipe
           - Add relevant tags for each recipe (e.g., "Quick Meals", "Healthy", "Vegetarian")

        Return ONLY valid JSON matching this exact schema:
        {
          "hasFood": boolean,
          "ingredients": [{"name": string, "category": string, "confidence": number}],
          "suggestedRecipes": [
            {
              "name": string,
              "description": string,
              "ingredients": [string],
              "instructions": [string],
              "prepTime": number,
              "cookTime": number,
              "servings": number,
              "difficulty": string,
              "tags": [string]
            }
          ],
          "message": string (only if no food detected)
        }
        """
    }

    private nonisolated func parseAIResponse(_ content: String) throws -> AIAnalysisResult {
        // Extract JSON from markdown code blocks if present
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = jsonString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        do {
            let result = try JSONDecoder().decode(AIAnalysisResult.self, from: data)
            return result
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 Content: \(jsonString)")
            throw AIServiceError.jsonParsingError
        }
    }

    private nonisolated func convertIngredients(from aiResult: AIAnalysisResult?) -> [Ingredient] {
        guard let aiResult = aiResult, aiResult.hasFood else {
            return []
        }

        return aiResult.ingredients.map { detected in
            let category = mapCategory(detected.category)
            return Ingredient(
                name: detected.name,
                category: category,
                confidence: detected.confidence
            )
        }
    }

    private nonisolated func mapCategory(_ categoryString: String?) -> IngredientCategory? {
        guard let categoryString = categoryString?.lowercased() else { return nil }

        switch categoryString {
        case "produce", "vegetables", "fruits", "veggies":
            return .produce
        case "meat", "protein", "poultry", "beef", "pork", "chicken":
            return .meat
        case "dairy", "milk", "cheese", "yogurt":
            return .dairy
        case "grains", "bread", "pasta", "rice":
            return .grains
        case "seafood", "fish":
            return .seafood
        case "condiments", "sauces", "spices":
            return .condiments
        default:
            return nil
        }
    }

    private nonisolated func generateRecipes(
        from aiResult: AIAnalysisResult?,
        manualItems: [String],
        allIngredients: [String]
    ) async throws -> [Recipe] {
        // If AI detected recipes, use those
        if let aiResult = aiResult, aiResult.hasFood, !aiResult.suggestedRecipes.isEmpty {
            return aiResult.suggestedRecipes.map { suggested in
                let difficulty = mapDifficulty(suggested.difficulty)

                return Recipe(
                    name: suggested.name,
                    instructions: suggested.instructions,
                    ingredients: suggested.ingredients.map {
                        RecipeIngredient(name: $0, amount: "as needed")
                    },
                    tags: suggested.tags,
                    prepTime: suggested.prepTime,
                    cookTime: suggested.cookTime,
                    servings: suggested.servings,
                    difficulty: difficulty
                )
            }
        }

        // If only manual items, generate simple recipes
        if !manualItems.isEmpty {
            return generateFallbackRecipes(ingredients: allIngredients)
        }

        return []
    }

    private nonisolated func mapDifficulty(_ difficultyString: String?) -> DifficultyLevel? {
        guard let difficultyString = difficultyString?.lowercased() else { return nil }

        switch difficultyString {
        case "easy", "beginner", "simple":
            return .easy
        case "medium", "intermediate", "moderate":
            return .medium
        case "hard", "difficult", "advanced", "expert":
            return .hard
        default:
            return .easy
        }
    }

    private nonisolated func generateFallbackRecipes(ingredients: [String]) -> [Recipe] {
        let ingredientList = ingredients.prefix(3).joined(separator: ", ")

        return [
            Recipe(
                name: "Simple \(ingredients.first ?? "Ingredient") Dish",
                instructions: [
                    "Prepare your ingredients: \(ingredientList)",
                    "Combine ingredients in a bowl or pan",
                    "Cook or mix according to your preference",
                    "Season to taste and serve"
                ],
                ingredients: ingredients.map {
                    RecipeIngredient(name: $0, amount: "as needed")
                },
                tags: ["Quick Meals", "Simple"],
                prepTime: 5,
                cookTime: 15,
                servings: 2,
                difficulty: .easy
            )
        ]
    }
}
