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
    case insufficientRecipes

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
        case .insufficientRecipes:
            return "Could not generate enough recipes with available ingredients"
        }
    }
}

// MARK: - AI Service

actor AIService {
    static let shared = AIService()

    private init() {}

    // MARK: - Main Analysis Method

    func analyzeFridge(
        image: UIImage?,
        manualItems: [String],
        userProfile: UserProfile? = nil
    ) async throws -> AnalysisResult {
        print("🤖 Starting fridge analysis...")

        var aiResult: AIAnalysisResult?
        if let image = image {
            aiResult = try await callOpenAI(image: image, userProfile: userProfile)
        }

        let ingredients = convertIngredients(from: aiResult)
        let recipes = convertRecipes(from: aiResult, manualItems: manualItems)

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

    // MARK: - Generate Recipes from Ingredients

    func generateRecipes(
        from ingredientNames: [String],
        count: Int = 5,
        userProfile: UserProfile? = nil,
        excludingRecipes: [Recipe] = []
    ) async throws -> [Recipe] {
        print("🍳 Generating \(count) recipes from \(ingredientNames.count) ingredients...")

        guard Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        let prompt = buildRecipeGenerationPrompt(
            ingredients: ingredientNames,
            count: count,
            userProfile: userProfile,
            excludingRecipes: excludingRecipes
        )

        let request = OpenAITextRequest(
            model: Config.openAIModel,
            messages: [
                OpenAITextRequest.Message(role: "system", content: "You are ChefAI, a professional culinary AI that creates detailed, practical recipes."),
                OpenAITextRequest.Message(role: "user", content: prompt)
            ],
            maxTokens: 4000,
            temperature: 0.7
        )

        guard let url = URL(string: Config.apiEndpoint) else {
            throw AIServiceError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIServiceError.invalidResponse
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        let generationResult = try parseRecipeGenerationResponse(content)

        let recipes = generationResult.recipes.map { convertSuggestedRecipe($0) }

        print("✅ Generated \(recipes.count) recipes")
        return recipes
    }

    // MARK: - OpenAI API Call

    private nonisolated func callOpenAI(image: UIImage, userProfile: UserProfile? = nil) async throws -> AIAnalysisResult {
        guard Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        guard let base64Image = convertToBase64(image: image) else {
            throw AIServiceError.imageEncodingFailed
        }

        let request = buildRequest(base64Image: base64Image, userProfile: userProfile)

        guard let url = URL(string: Config.apiEndpoint) else {
            throw AIServiceError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout

        urlRequest.httpBody = try JSONEncoder().encode(request)

        print("📡 Calling OpenAI API...")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
               let error = errorResponse.error {
                throw AIServiceError.apiError(error.message)
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let choice = openAIResponse.choices.first else {
            throw AIServiceError.invalidResponse
        }

        print("📊 Tokens used: \(openAIResponse.usage?.totalTokens ?? 0)")

        let content = choice.message.content
        print("🔍 AI Response: \(content.prefix(300))...")

        return try parseAIResponse(content)
    }

    // MARK: - Image Processing

    private nonisolated func convertToBase64(image: UIImage) -> String? {
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale: CGFloat = size.width > size.height
            ? maxDimension / size.width
            : maxDimension / size.height

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

    // MARK: - Request Building

    private nonisolated func buildRequest(base64Image: String, userProfile: UserProfile?) -> OpenAIRequest {
        let prompt = buildAnalysisPrompt(userProfile: userProfile)

        return OpenAIRequest(
            model: Config.openAIModel,
            messages: [
                OpenAIRequest.Message(
                    role: "user",
                    content: [
                        OpenAIRequest.Content(type: "text", text: prompt, imageUrl: nil),
                        OpenAIRequest.Content(
                            type: "image_url",
                            text: nil,
                            imageUrl: OpenAIRequest.ImageURL(url: "data:image/jpeg;base64,\(base64Image)")
                        )
                    ]
                )
            ],
            maxTokens: Config.maxTokens,
            temperature: Config.temperature
        )
    }

    // MARK: - Prompt Building

    private nonisolated func buildAnalysisPrompt(userProfile: UserProfile?) -> String {
        var userContext = ""
        if let profile = userProfile {
            var preferences: [String] = []
            if !profile.dietaryRestrictions.isEmpty {
                preferences.append("Dietary restrictions: \(profile.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", "))")
            }
            if !profile.cuisinePreferences.isEmpty {
                preferences.append("Preferred cuisines: \(profile.cuisinePreferences.map { $0.rawValue }.joined(separator: ", "))")
            }
            if let skill = profile.cookingSkillLevel {
                preferences.append("Cooking skill: \(skill.rawValue)")
            }
            if !preferences.isEmpty {
                userContext = "\n\nUser preferences:\n" + preferences.joined(separator: "\n")
            }
        }

        return """
        You are ChefAI, a professional food recognition and recipe AI. Analyze this image with EXTREME PRECISION.

        TASK 1 - INGREDIENT DETECTION:
        If food is visible, identify EVERY item with:
        - EXACT product name (e.g., "Kirkland Organic Extra Virgin Olive Oil" not "olive oil")
        - Brand name if visible on packaging
        - Estimated quantity and unit
        - Category: produce/dairy/meat/seafood/grains/pantryStaples/condiments/spices/frozen/beverages/snacks/bakery/other
        - Confidence score (0.0-1.0)
        - Nutrition info if visible on labels

        TASK 2 - RECIPE GENERATION:
        Generate EXACTLY 5 unique recipes using ONLY the detected ingredients. For each recipe:
        - 8-12 detailed cooking steps
        - Technique keywords (julienne, sear, fold, simmer, etc.)
        - Chef tips and tricks
        - Nutrition estimates per serving
        - Difficulty level and timing
        \(userContext)

        CRITICAL RULES:
        - ONLY suggest recipes possible with detected ingredients
        - DO NOT assume ingredients not visible in the image
        - Always generate exactly 5 recipes (never fewer)
        - Include diverse recipe styles (quick meals, hearty dishes, healthy options)

        If NO FOOD detected, respond: {"hasFood": false, "ingredients": [], "suggestedRecipes": [], "message": "No food detected."}

        Return ONLY valid JSON:
        {
          "hasFood": boolean,
          "ingredients": [{
            "name": string,
            "brandName": string|null,
            "quantity": string|null,
            "unit": string|null,
            "category": string,
            "confidence": number,
            "nutrition": {"calories": int, "protein": float, "carbs": float, "fat": float, "servingSize": string}|null
          }],
          "suggestedRecipes": [{
            "name": string,
            "description": string,
            "cuisineType": string,
            "ingredients": [{"name": string, "amount": string, "unit": string, "isOptional": boolean, "substitutes": [string]}],
            "instructions": [string],
            "detailedSteps": [{
              "stepNumber": int,
              "instruction": string,
              "duration": int,
              "technique": string,
              "tips": [string]
            }],
            "prepTime": int,
            "cookTime": int,
            "servings": int,
            "difficulty": "easy"|"medium"|"hard"|"expert",
            "tags": [string],
            "tips": [string],
            "nutritionPerServing": {"calories": int, "protein": float, "carbs": float, "fat": float},
            "source": {"name": "ChefAI Generated", "author": "ChefAI"}
          }]
        }
        """
    }

    private nonisolated func buildRecipeGenerationPrompt(
        ingredients: [String],
        count: Int,
        userProfile: UserProfile?,
        excludingRecipes: [Recipe]
    ) -> String {
        let ingredientList = ingredients.joined(separator: ", ")

        var userContext = ""
        if let profile = userProfile {
            var preferences: [String] = []
            if !profile.dietaryRestrictions.isEmpty {
                preferences.append("Dietary restrictions: \(profile.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", "))")
            }
            if !profile.cuisinePreferences.isEmpty {
                preferences.append("Preferred cuisines: \(profile.cuisinePreferences.map { $0.rawValue }.joined(separator: ", "))")
            }
            if let skill = profile.cookingSkillLevel {
                preferences.append("Skill level: \(skill.rawValue)")
            }
            if !preferences.isEmpty {
                userContext = "\n\nUser preferences:\n" + preferences.joined(separator: "\n")
            }
        }

        var excludeContext = ""
        if !excludingRecipes.isEmpty {
            let excludeNames = excludingRecipes.map { $0.name }.joined(separator: ", ")
            excludeContext = "\n\nDO NOT suggest these recipes (already shown): \(excludeNames)"
        }

        return """
        Generate EXACTLY \(count) unique, creative recipes using ONLY these ingredients:
        \(ingredientList)
        \(userContext)\(excludeContext)

        REQUIREMENTS:
        1. Each recipe must use ONLY ingredients from the list above
        2. Provide 8-12 detailed steps per recipe
        3. Include technique keywords (dice, julienne, sear, fold, simmer, etc.)
        4. Vary difficulty levels and cooking styles
        5. Include chef tips and nutrition estimates

        Return ONLY valid JSON:
        {
          "recipes": [{
            "name": string,
            "description": string,
            "cuisineType": string,
            "ingredients": [{"name": string, "amount": string, "unit": string, "isOptional": boolean}],
            "instructions": [string],
            "detailedSteps": [{
              "stepNumber": int,
              "instruction": string,
              "duration": int,
              "technique": string,
              "tips": [string]
            }],
            "prepTime": int,
            "cookTime": int,
            "servings": int,
            "difficulty": "easy"|"medium"|"hard"|"expert",
            "tags": [string],
            "tips": [string],
            "nutritionPerServing": {"calories": int, "protein": float, "carbs": float, "fat": float},
            "source": {"name": "ChefAI Generated", "author": "ChefAI"}
          }]
        }
        """
    }

    // MARK: - Response Parsing

    private nonisolated func parseAIResponse(_ content: String) throws -> AIAnalysisResult {
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
            return try JSONDecoder().decode(AIAnalysisResult.self, from: data)
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 Content: \(jsonString.prefix(500))")
            throw AIServiceError.jsonParsingError
        }
    }

    private nonisolated func parseRecipeGenerationResponse(_ content: String) throws -> RecipeGenerationResult {
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
            return try JSONDecoder().decode(RecipeGenerationResult.self, from: data)
        } catch {
            print("❌ Recipe generation JSON parsing error: \(error)")
            throw AIServiceError.jsonParsingError
        }
    }

    // MARK: - Model Conversion

    private nonisolated func convertIngredients(from aiResult: AIAnalysisResult?) -> [Ingredient] {
        guard let aiResult = aiResult, aiResult.hasFood else { return [] }

        return aiResult.ingredients.map { detected in
            var nutritionInfo: NutritionInfo?
            if let nutrition = detected.nutrition {
                nutritionInfo = NutritionInfo(
                    calories: nutrition.calories,
                    protein: nutrition.protein,
                    carbs: nutrition.carbs,
                    fat: nutrition.fat,
                    servingSize: nutrition.servingSize
                )
            }

            return Ingredient(
                name: detected.name,
                brandName: detected.brandName,
                quantity: detected.quantity,
                unit: detected.unit,
                category: mapCategory(detected.category),
                confidence: detected.confidence,
                nutritionInfo: nutritionInfo
            )
        }
    }

    private nonisolated func convertRecipes(from aiResult: AIAnalysisResult?, manualItems: [String]) -> [Recipe] {
        guard let aiResult = aiResult, aiResult.hasFood else {
            if !manualItems.isEmpty {
                return generateFallbackRecipes(ingredients: manualItems)
            }
            return []
        }

        return aiResult.suggestedRecipes.map { convertSuggestedRecipe($0) }
    }

    private nonisolated func convertSuggestedRecipe(_ suggested: AIAnalysisResult.SuggestedRecipe) -> Recipe {
        let ingredients = suggested.ingredients.map { ingredient in
            RecipeIngredient(
                name: ingredient.name,
                amount: ingredient.amount,
                unit: ingredient.unit,
                isOptional: ingredient.isOptional ?? false,
                substitutes: ingredient.substitutes ?? []
            )
        }

        var detailedSteps: [RecipeStep] = []
        if let steps = suggested.detailedSteps {
            detailedSteps = steps.enumerated().map { index, step in
                RecipeStep(
                    stepNumber: step.stepNumber,
                    instruction: step.instruction,
                    duration: step.duration,
                    technique: step.technique,
                    tips: step.tips ?? []
                )
            }
        }

        var nutritionInfo: NutritionInfo?
        if let nutrition = suggested.nutritionPerServing {
            nutritionInfo = NutritionInfo(
                calories: nutrition.calories,
                protein: nutrition.protein,
                carbs: nutrition.carbs,
                fat: nutrition.fat
            )
        }

        var source: RecipeSource?
        if let sourceInfo = suggested.source {
            source = RecipeSource(
                name: sourceInfo.name,
                url: sourceInfo.url,
                author: sourceInfo.author
            )
        }

        return Recipe(
            name: suggested.name,
            description: suggested.description,
            instructions: suggested.instructions,
            detailedSteps: detailedSteps,
            ingredients: ingredients,
            tags: suggested.tags,
            prepTime: suggested.prepTime,
            cookTime: suggested.cookTime,
            servings: suggested.servings,
            difficulty: mapDifficulty(suggested.difficulty),
            cuisineType: suggested.cuisineType,
            nutritionPerServing: nutritionInfo,
            tips: suggested.tips ?? [],
            source: source
        )
    }

    private nonisolated func mapCategory(_ categoryString: String?) -> IngredientCategory? {
        guard let category = categoryString?.lowercased() else { return nil }

        switch category {
        case "produce", "vegetables", "fruits", "veggies": return .produce
        case "meat", "protein", "poultry", "beef", "pork", "chicken": return .meat
        case "dairy", "milk", "cheese", "yogurt": return .dairy
        case "grains", "bread", "pasta", "rice": return .grains
        case "seafood", "fish": return .seafood
        case "condiments", "sauces": return .condiments
        case "spices", "seasonings", "herbs": return .spices
        case "pantrystaples", "pantry", "canned": return .pantryStaples
        case "frozen": return .frozen
        case "beverages", "drinks": return .beverages
        case "snacks": return .snacks
        case "bakery", "baked": return .bakery
        default: return .other
        }
    }

    private nonisolated func mapDifficulty(_ difficultyString: String?) -> DifficultyLevel? {
        guard let difficulty = difficultyString?.lowercased() else { return .easy }

        switch difficulty {
        case "easy", "beginner", "simple": return .easy
        case "medium", "intermediate", "moderate": return .medium
        case "hard", "difficult", "advanced": return .hard
        case "expert", "professional", "master": return .expert
        default: return .easy
        }
    }

    private nonisolated func generateFallbackRecipes(ingredients: [String]) -> [Recipe] {
        guard !ingredients.isEmpty else { return [] }

        let ingredientList = ingredients.prefix(5).joined(separator: ", ")

        return [
            Recipe(
                name: "Simple \(ingredients.first ?? "Ingredient") Dish",
                description: "A quick and easy dish using your available ingredients",
                instructions: [
                    "Prepare all ingredients by washing and cutting as needed",
                    "Heat a pan over medium heat with a little oil",
                    "Add ingredients in order of cooking time",
                    "Season to taste with salt and pepper",
                    "Cook until done and serve warm"
                ],
                ingredients: ingredients.map { RecipeIngredient(name: $0, amount: "as needed") },
                tags: ["Quick Meals", "Simple", "Easy"],
                prepTime: 10,
                cookTime: 15,
                servings: 2,
                difficulty: .easy
            )
        ]
    }
}
