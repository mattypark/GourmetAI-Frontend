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
    case recipeGenerationFailed

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured. Please add your API key to Config.swift"
        case .imageEncodingFailed:
            return "Failed to encode image for analysis"
        case .networkError(let error):
            return "API connection failed - please check your internet. (\(error.localizedDescription))"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .apiError(let message):
            return "API error: \(message)"
        case .noFoodDetected:
            return "No food detected in image"
        case .jsonParsingError:
            return "Failed to parse AI response"
        case .insufficientRecipes:
            return "Could not generate enough recipes with available ingredients"
        case .recipeGenerationFailed:
            return "Unable to generate recipes - please try again"
        }
    }
}

// MARK: - Ingredient Detection Result (for Step 1)

struct IngredientDetectionResult: Codable {
    let ingredients: [DetectedIngredientItem]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ingredients = try container.decodeIfPresent([DetectedIngredientItem].self, forKey: .ingredients) ?? []
    }
}

struct DetectedIngredientItem: Codable {
    let name: String
    let brand: String?
    let quantity: String?
    let unit: String?
    let category: String?
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case name, brand, quantity, unit, category, confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0.8
    }
}

// MARK: - Gemini Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        candidates = try container.decodeIfPresent([GeminiCandidate].self, forKey: .candidates)
    }
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
}

// MARK: - Tavily Response Models

struct TavilyResponse: Codable {
    let results: [TavilyResult]
}

struct TavilyResult: Codable {
    let title: String
    let url: String
    let content: String
    let score: Double?
}

// MARK: - AI Service

final class AIService: @unchecked Sendable {
    static let shared = AIService()

    private var lastTavilyResults: [TavilyResult] = []

    func getLastTavilyResults() -> [TavilyResult] {
        return lastTavilyResults
    }

    private init() {}

    // MARK: - Main Analysis Method

    func analyzeFridge(
        image: UIImage?,
        manualItems: [String],
        userProfile: UserProfile? = nil
    ) async throws -> AnalysisResult {
        print("🤖 Starting fridge analysis (two-step flow)...")

        // Step 1: Detect ingredients from image (Gemini Flash 2.0)
        var ingredients: [Ingredient] = []
        if let image = image {
            ingredients = try await analyzeImageWithGemini(image)
        }

        // Add manual items as ingredients
        for item in manualItems {
            ingredients.append(Ingredient(name: item, confidence: 1.0))
        }

        // Check if we have any ingredients to work with
        if ingredients.isEmpty {
            throw AIServiceError.noFoodDetected
        }

        // Step 2 removed - recipes generated when user taps "Generate Recipes" button
        let recipes: [Recipe] = []

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

        // Strip markdown fences before parsing
        let jsonString = try extractAndValidateJSON(content)
        print("🔍 Full JSON to parse (\(jsonString.count) chars): \(jsonString.prefix(2000))...")

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        do {
            let generationResult = try JSONDecoder().decode(RecipeGenerationResult.self, from: jsonData)

            let recipes = generationResult.recipes.map { convertSuggestedRecipe($0) }

            print("✅ Generated \(recipes.count) recipes")
            return recipes

        } catch let decodingError as DecodingError {
            print("❌ JSON Decode Error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key '\(key.stringValue)' at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown: \(decodingError)")
            }
            throw AIServiceError.jsonParsingError
        }
    }

    // MARK: - Step 1: Ingredient Detection Only (OpenAI Vision)

    func analyzeImageForIngredients(_ image: UIImage) async throws -> [Ingredient] {
        print("🔍 Step 1: Detecting ingredients from image...")

        guard !Config.openAIAPIKey.isEmpty && Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        guard let base64Image = convertToBase64(image: image) else {
            throw AIServiceError.imageEncodingFailed
        }

        let prompt = buildIngredientDetectionPrompt()

        let request = OpenAIRequest(
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
            maxTokens: Config.openAIMaxTokens,
            temperature: Config.temperature
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

        print("📡 Calling OpenAI Vision API for ingredient detection...")

        let (data, response) = try await performRequestWithRetry(urlRequest: urlRequest)

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

        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        print("📊 Tokens used: \(openAIResponse.usage?.totalTokens ?? 0)")
        print("🔍 Response preview: \(content.prefix(300))...")

        // Parse the ingredient-only response
        let jsonString = try extractAndValidateJSON(content)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        let ingredientResult = try JSONDecoder().decode(IngredientDetectionResult.self, from: jsonData)

        if ingredientResult.ingredients.isEmpty {
            print("⚠️ No ingredients detected in image")
            throw AIServiceError.noFoodDetected
        }

        let ingredients = ingredientResult.ingredients.map { detected -> Ingredient in
            Ingredient(
                name: detected.name,
                brandName: detected.brand,
                quantity: detected.quantity,
                unit: detected.unit,
                category: mapCategory(detected.category),
                confidence: detected.confidence
            )
        }

        print("✅ Detected \(ingredients.count) ingredients")
        return ingredients
    }

    // MARK: - Step 1: Ingredient Detection (Gemini 2.5 Flash)

    func analyzeImageWithGemini(_ image: UIImage) async throws -> [Ingredient] {
        print("🔍 Step 1: Detecting ingredients with Gemini 2.5 Flash...")

        guard !Config.geminiAPIKey.isEmpty && Config.geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        // Convert image to base64
        guard let base64Image = convertToBase64(image: image) else {
            throw AIServiceError.imageEncodingFailed
        }

        // Build Gemini API request
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(Config.geminiAPIKey)") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Config.requestTimeout

        let prompt = buildIngredientDetectionPrompt()

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📡 Calling Gemini 2.5 Flash API...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Gemini API error: \(responseString)")
            }
            throw AIServiceError.apiError("Gemini HTTP \(httpResponse.statusCode)")
        }

        // Parse Gemini response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let content = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw AIServiceError.invalidResponse
        }

        print("🔍 Response preview: \(content.prefix(300))...")

        // Parse ingredients JSON
        let jsonString = try extractAndValidateJSON(content)

        // Check if response is an array instead of object with "ingredients" key
        var finalJsonString = jsonString
        if jsonString.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
            // Gemini returned array directly, wrap it in ingredients object
            finalJsonString = "{\"ingredients\": \(jsonString)}"
            print("⚠️ Gemini returned array, wrapping in ingredients object")
        }

        guard let jsonData = finalJsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        let ingredientResult = try JSONDecoder().decode(IngredientDetectionResult.self, from: jsonData)

        if ingredientResult.ingredients.isEmpty {
            print("⚠️ No ingredients detected in image")
            throw AIServiceError.noFoodDetected
        }

        let ingredients = ingredientResult.ingredients.map { detected -> Ingredient in
            Ingredient(
                name: detected.name,
                brandName: detected.brand,
                quantity: detected.quantity,
                unit: detected.unit,
                category: mapCategory(detected.category),
                confidence: detected.confidence
            )
        }

        print("✅ Detected \(ingredients.count) ingredients with Gemini 2.5 Flash")
        return ingredients
    }

    // MARK: - Step 2: Recipe Generation (OpenAI)

    func generateRecipesFromIngredients(
        from ingredients: [Ingredient],
        userProfile: UserProfile?,
        count: Int = 5
    ) async throws -> [Recipe] {
        print("🍳 Step 2: Generating \(count) recipes with OpenAI...")

        guard !Config.openAIAPIKey.isEmpty && Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        let prompt = buildRecipePrompt(
            ingredients: ingredients,
            userProfile: userProfile,
            count: count
        )

        let request = OpenAITextRequest(
            model: Config.recipeModel,
            messages: [
                OpenAITextRequest.Message(role: "system", content: "You are ChefAI, a professional culinary AI that creates detailed, personalized recipes."),
                OpenAITextRequest.Message(role: "user", content: prompt)
            ],
            maxTokens: Config.recipeMaxTokens,
            temperature: Config.temperature
        )

        guard let url = URL(string: Config.chatEndpoint) else {
            throw AIServiceError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout
        urlRequest.httpBody = try JSONEncoder().encode(request)

        print("📡 Calling OpenAI API for recipe generation...")

        let (data, response) = try await performRequestWithRetry(urlRequest: urlRequest)

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

        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        print("📊 OpenAI tokens used: \(openAIResponse.usage?.totalTokens ?? 0)")
        print("🔍 Response preview: \(content.prefix(300))...")

        // Parse recipe response
        let jsonString = try extractAndValidateJSON(content)
        print("🔍 Full JSON to parse (\(jsonString.count) chars): \(jsonString.prefix(2000))...")

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        do {
            let recipeResult = try JSONDecoder().decode(RecipeGenerationResult.self, from: jsonData)

            if recipeResult.recipes.isEmpty {
                throw AIServiceError.recipeGenerationFailed
            }

            let recipes = recipeResult.recipes.map { convertSuggestedRecipe($0) }

            print("✅ Generated \(recipes.count) recipes with OpenAI")
            return recipes

        } catch let decodingError as DecodingError {
            print("❌ JSON Decode Error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key '\(key.stringValue)' at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown: \(decodingError)")
            }
            throw AIServiceError.jsonParsingError
        }
    }

    // MARK: - Step 2: Recipe Generation (Tavily Search + Gemini)

    func generateRecipesWithTavily(
        from ingredients: [Ingredient],
        userProfile: UserProfile?,
        count: Int = 5
    ) async throws -> [Recipe] {
        print("🍳 Step 2: Generating \(count) recipes with Tavily Search...")

        guard !Config.tavilyAPIKey.isEmpty && Config.tavilyAPIKey != "YOUR_TAVILY_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        let ingredientNames = ingredients.map { $0.name }.joined(separator: ", ")
        let query = "recipes using \(ingredientNames)"

        // Tavily API request
        guard let url = URL(string: "https://api.tavily.com/search") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Config.requestTimeout

        let requestBody: [String: Any] = [
            "api_key": Config.tavilyAPIKey,
            "query": query,
            "search_depth": "advanced",
            "include_domains": [
                "allrecipes.com",
                "foodnetwork.com",
                "bonappetit.com",
                "seriouseats.com",
                "epicurious.com",
                "delish.com",
                "tasty.co",
                "simplyrecipes.com"
            ],
            "max_results": 10
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📡 Calling Tavily Search API...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Tavily API error: \(responseString)")
            }
            throw AIServiceError.apiError("Tavily HTTP \(httpResponse.statusCode)")
        }

        let tavilyResponse = try JSONDecoder().decode(TavilyResponse.self, from: data)

        // Store results for later display
        self.lastTavilyResults = tavilyResponse.results

        print("✅ Tavily returned \(tavilyResponse.results.count) search results")

        // Use GPT-5o Mini to extract structured recipes from search results
        let recipes = try await extractRecipesWithGPT5oMini(
            from: tavilyResponse.results,
            ingredients: ingredients,
            userProfile: userProfile,
            count: count
        )

        print("✅ Generated \(recipes.count) recipes with Tavily + GPT-5o Mini")
        return recipes
    }

    // MARK: - Extract Recipes from Tavily Results using Gemini

    private func extractRecipesWithGemini(
        from results: [TavilyResult],
        ingredients: [Ingredient],
        userProfile: UserProfile?,
        count: Int
    ) async throws -> [Recipe] {
        guard !Config.geminiAPIKey.isEmpty && Config.geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        // Build context from search results
        var searchContext = ""
        for result in results.prefix(5) {
            searchContext += "Recipe: \(result.title)\nURL: \(result.url)\nContent: \(result.content)\n\n"
        }

        let prompt = buildRecipeExtractionPrompt(
            searchContext: searchContext,
            ingredients: ingredients,
            userProfile: userProfile,
            count: count
        )

        // Call Gemini API
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(Config.geminiAPIKey)") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Config.requestTimeout

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": Config.temperature,
                "maxOutputTokens": Config.recipeMaxTokens
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📡 Calling Gemini 2.5 Flash to extract recipes from search results...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Gemini API error: \(responseString)")
            }
            throw AIServiceError.apiError("Gemini HTTP \(httpResponse.statusCode)")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let content = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw AIServiceError.invalidResponse
        }

        print("🔍 Response preview: \(content.prefix(300))...")

        // Parse recipe response
        let jsonString = try extractAndValidateJSON(content)
        print("🔍 Full JSON to parse (\(jsonString.count) chars): \(jsonString.prefix(2000))...")

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        do {
            let recipeResult = try JSONDecoder().decode(RecipeGenerationResult.self, from: jsonData)

            if recipeResult.recipes.isEmpty {
                throw AIServiceError.recipeGenerationFailed
            }

            let recipes = recipeResult.recipes.map { convertSuggestedRecipe($0) }
            return recipes

        } catch let decodingError as DecodingError {
            print("❌ JSON Decode Error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Missing key '\(key.stringValue)' at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("   Debug: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("   Value not found for \(type) at: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("   Unknown: \(decodingError)")
            }
            throw AIServiceError.jsonParsingError
        }
    }

    // MARK: - Extract Recipes from Tavily Results using GPT-5o Mini

    private func extractRecipesWithGPT5oMini(
        from results: [TavilyResult],
        ingredients: [Ingredient],
        userProfile: UserProfile?,
        count: Int
    ) async throws -> [Recipe] {
        guard !Config.openAIAPIKey.isEmpty && Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        // Build context from search results
        var searchContext = ""
        for result in results.prefix(10) {
            searchContext += "Recipe: \(result.title)\nURL: \(result.url)\nContent: \(result.content)\n\n"
        }

        let prompt = buildRecipeExtractionPrompt(
            searchContext: searchContext,
            ingredients: ingredients,
            userProfile: userProfile,
            count: count
        )

        // Call GPT-5o Mini API
        // Note: GPT-5o Mini only supports default temperature (1.0), so we omit the parameter
        let requestBody: [String: Any] = [
            "model": Config.gpt5oMiniModel,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a recipe extraction assistant. You format web search results into structured recipe JSON. Always return valid, complete JSON with all requested recipes."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_completion_tokens": 10000,
            "response_format": ["type": "json_object"]
        ]

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📡 Calling GPT-5o Mini to extract recipes from search results...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ GPT-5o Mini API error: \(responseString)")
            }
            throw AIServiceError.apiError("GPT-5o Mini HTTP \(httpResponse.statusCode)")
        }

        // Parse OpenAI response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        print("🔍 GPT-5o Mini response preview: \(content.prefix(300))...")
        print("📄 Response length: \(content.count) chars")

        // Parse recipe response (GPT-5o Mini with json_object mode returns clean JSON)
        let jsonString = try extractAndValidateJSON(content)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        let recipeResult = try JSONDecoder().decode(RecipeGenerationResult.self, from: jsonData)

        if recipeResult.recipes.isEmpty {
            throw AIServiceError.recipeGenerationFailed
        }

        let recipes = recipeResult.recipes.map { convertSuggestedRecipe($0) }

        print("✅ Generated \(recipes.count) recipes with GPT-5o Mini")
        return recipes
    }

    // MARK: - Build Recipe Extraction Prompt

    private func buildRecipeExtractionPrompt(
        searchContext: String,
        ingredients: [Ingredient],
        userProfile: UserProfile?,
        count: Int
    ) -> String {
        let ingredientNames = ingredients.map { $0.name }

        // Build user profile context
        var profileContext = ""
        if let profile = userProfile {
            var details: [String] = []

            if let skill = profile.cookingSkillLevel {
                details.append("Cooking Skill: \(skill.rawValue)")
            }

            if !profile.dietaryRestrictions.isEmpty {
                let restrictions = profile.dietaryRestrictions
                    .filter { $0 != .none }
                    .map { $0.rawValue }
                if !restrictions.isEmpty {
                    details.append("Dietary Restrictions: \(restrictions.joined(separator: ", "))")
                }
            }

            if let time = profile.timeAvailability {
                details.append("Available Time: \(time.maxMinutes) minutes max")
            }

            if !details.isEmpty {
                profileContext = "\n\nUSER PROFILE:\n\(details.joined(separator: "\n"))"
            }
        }

        return """
        Based on these recipe search results from trusted cooking websites, create \(count) detailed recipes that use these available ingredients: \(ingredientNames.joined(separator: ", "))
        \(profileContext)

        Search Results:
        \(searchContext)

        Requirements:
        1. Use PRIMARILY the available ingredients listed above
        2. You may suggest common pantry staples if needed (salt, pepper, oil, basic spices)
        3. Include the SOURCE URL from the search results for each recipe
        4. Match the user's skill level and dietary restrictions if specified
        5. Provide accurate prep/cook times and techniques

        Return this exact JSON structure (no markdown):
        {
          "recipes": [
            {
              "name": "Recipe Title",
              "description": "Brief appetizing description",
              "ingredients": [{"name": "item", "amount": "2", "unit": "cups", "isOptional": false, "substitutes": []}],
              "instructions": ["Step 1", "Step 2"],
              "detailedSteps": [{"stepNumber": 1, "instruction": "Do this", "duration": 300, "technique": "sauté", "tips": ["tip"]}],
              "prepTime": 15,
              "cookTime": 30,
              "servings": 4,
              "difficulty": "easy",
              "cuisineType": "Italian",
              "nutritionPerServing": {"calories": 350, "protein": 25.0, "carbs": 30.0, "fat": 12.0},
              "tips": ["Chef tip"],
              "tags": ["quick", "healthy"],
              "source": {"name": "Source Website", "author": null, "url": "URL from search results"}
            }
          ]
        }

        CRITICAL OUTPUT FORMAT:
        - Return ONLY the JSON object
        - DO NOT wrap in ```json or ``` markdown fences
        - DO NOT include any text before or after the JSON
        - Start your response with { and end with }
        """
    }

    // MARK: - OpenAI API Call

    private func callOpenAI(
        image: UIImage,
        userProfile: UserProfile? = nil,
        aggressiveMode: Bool = false,
        retryForFood: Bool = true
    ) async throws -> AIAnalysisResult {
        guard Config.openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw AIServiceError.noAPIKey
        }

        guard let base64Image = convertToBase64(image: image) else {
            throw AIServiceError.imageEncodingFailed
        }

        let request = buildRequest(base64Image: base64Image, userProfile: userProfile, aggressiveMode: aggressiveMode)

        guard let url = URL(string: Config.apiEndpoint) else {
            throw AIServiceError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Config.requestTimeout

        urlRequest.httpBody = try JSONEncoder().encode(request)

        print("📡 Calling OpenAI API\(aggressiveMode ? " (aggressive mode)" : "")...")

        // Perform request with retry logic
        let (data, response) = try await performAPIRequest(urlRequest: urlRequest)

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

        let aiResult = try parseAIResponse(content)

        // If no food detected and we haven't tried aggressive mode yet, retry with aggressive prompt
        if !aiResult.hasFood && retryForFood && !aggressiveMode {
            print("🔄 No food detected, retrying with aggressive prompt...")
            return try await callOpenAI(
                image: image,
                userProfile: userProfile,
                aggressiveMode: true,
                retryForFood: false
            )
        }

        return aiResult
    }

    // MARK: - API Request with Retry and Exponential Backoff

    private func performAPIRequest(urlRequest: URLRequest, retryCount: Int = 0) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: urlRequest)
        } catch let error as URLError where error.code == .timedOut && retryCount < Config.maxRetries {
            print("⚠️ Request timed out, retrying... (attempt \(retryCount + 1))")
            return try await performAPIRequest(urlRequest: urlRequest, retryCount: retryCount + 1)
        } catch {
            throw AIServiceError.networkError(error)
        }
    }

    private func performRequestWithRetry(urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<Config.maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                return (data, response)
            } catch let error as URLError {
                lastError = error
                print("⚠️ Request failed (attempt \(attempt + 1)/\(Config.maxRetries)): \(error.localizedDescription)")

                // Only retry on timeout or network connection issues
                let retryableCodes: [URLError.Code] = [.timedOut, .networkConnectionLost, .notConnectedToInternet]
                guard retryableCodes.contains(error.code) && attempt < Config.maxRetries - 1 else {
                    throw AIServiceError.networkError(error)
                }

                // Exponential backoff: 1s, 2s, 4s...
                let delay = pow(2.0, Double(attempt))
                print("⏳ Waiting \(Int(delay))s before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                throw AIServiceError.networkError(error)
            }
        }

        throw lastError.map { AIServiceError.networkError($0) } ?? AIServiceError.invalidResponse
    }

    // MARK: - JSON Extraction and Validation

    private func extractAndValidateJSON(_ content: String) throws -> String {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        print("📄 Raw response length: \(jsonString.count) chars")
        print("📄 First 100 chars: \(jsonString.prefix(100))")

        // Remove ALL markdown code fences - multiple strategies

        // Strategy 1: Remove ```json or ``` at start
        while jsonString.hasPrefix("```") {
            if jsonString.hasPrefix("```json") {
                jsonString = String(jsonString.dropFirst(7))
            } else {
                jsonString = String(jsonString.dropFirst(3))
            }
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Strategy 2: Remove ``` at end
        while jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Strategy 3: Find first { and last }
        guard let firstBrace = jsonString.firstIndex(of: "{"),
              let lastBrace = jsonString.lastIndex(of: "}") else {
            print("❌ No JSON braces found in response")
            print("📄 Content preview: \(content.prefix(500))")
            throw AIServiceError.jsonParsingError
        }

        jsonString = String(jsonString[firstBrace...lastBrace])

        print("📄 Extracted JSON length: \(jsonString.count) chars")

        // Validate it's parseable JSON before returning
        guard let data = jsonString.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            print("❌ Invalid JSON after extraction")
            print("📄 Attempted JSON: \(jsonString.prefix(500))")
            throw AIServiceError.jsonParsingError
        }

        return jsonString
    }

    // MARK: - Image Processing

    private func convertToBase64(image: UIImage) -> String? {
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

    private func buildRequest(base64Image: String, userProfile: UserProfile?, aggressiveMode: Bool = false) -> OpenAIRequest {
        let prompt = buildAnalysisPrompt(userProfile: userProfile, aggressiveMode: aggressiveMode)

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
            maxTokens: 4000,
            temperature: Config.temperature
        )
    }

    // MARK: - Prompt Building

    private func buildIngredientDetectionPrompt() -> String {
        return """
        You are analyzing an image that may contain food items, grocery receipts, shopping lists, or product packaging.

        DETECT INGREDIENTS FROM ANY OF THESE SOURCES:
        - Actual food items (fresh produce, meats, dairy, etc.)
        - Grocery/shopping receipts (extract purchased item names from line items)
        - Product packaging and labels (read product names from boxes, cans, bottles)
        - Shopping lists (handwritten or typed)
        - Pantry/fridge/shelf photos (packaged or fresh items)
        - Barcodes with visible product labels

        FOR RECEIPTS:
        - Extract each food item name from the receipt line items
        - IGNORE non-food items (cleaning supplies, toiletries, household goods)
        - Use the quantity from the receipt if visible (e.g., "2x" or "QTY: 3")
        - Parse brand names if shown on the receipt

        FOR BARCODES/PACKAGING:
        - Read the product name from the label
        - Include brand name if prominently displayed
        - Note package size/quantity if visible (e.g., "16 oz", "500g")

        FOR SHOPPING LISTS:
        - Extract each food item from the list
        - Handle handwritten text with best-effort recognition
        - Parse quantities if written (e.g., "2 lbs chicken", "1 dozen eggs")

        For each ingredient, extract:
        - name: Exact product name (e.g., "Kirkland Organic Extra Virgin Olive Oil" not just "olive oil")
        - brand: Brand name if visible on packaging/receipt, null otherwise
        - quantity: Amount from source (e.g., "2", "500g", "1 bunch", "1 box")
        - unit: Unit of measurement (e.g., "pieces", "cups", "grams", "lbs", "oz")
        - category: One of: protein, vegetable, grain, dairy, condiment, fruit, beverage, spice, frozen, canned, snack, other
        - confidence: Your confidence score from 0.0 to 1.0

        QUANTITY GUIDELINES (IMPORTANT):
        - For whole items: COUNT them exactly (e.g., "3" peppers, "1" cabbage, "6" eggs)
        - For partial items: estimate fraction (e.g., "0.5" for half an onion)
        - For packaged items: read the label quantity if visible (e.g., "16 oz", "500g")
        - For bunches/groups: estimate count (e.g., "1" bunch of bananas = approximately "6")
        - NEVER use vague terms like "partially visible", "some", or "several"
        - If quantity is truly unclear, use "1" as default with confidence < 0.5

        Handle edge cases:
        - Blurry items: Include with lower confidence (0.3-0.5), still estimate quantity
        - Unclear handwriting: Best-effort with lower confidence
        - No food detected: Return empty ingredients array

        CRITICAL: You MUST return a JSON object with an "ingredients" key containing an array.

        Your response must be EXACTLY this structure with NO other text:
        {
          "ingredients": [
            {
              "name": "ingredient name here",
              "brand": null,
              "quantity": "1",
              "unit": "piece",
              "category": "protein",
              "confidence": 0.9
            }
          ]
        }

        DO NOT return just an array like [{...}].
        DO NOT include markdown fences like ```json.
        DO NOT add any explanation before or after.
        ONLY return the JSON object starting with { and ending with }.
        """
    }

    private func buildRecipePrompt(
        ingredients: [Ingredient],
        userProfile: UserProfile?,
        count: Int
    ) -> String {
        // Build ingredient list
        let ingredientList = ingredients.map { ingredient -> String in
            var desc = ingredient.name
            if let quantity = ingredient.quantity {
                desc = "\(quantity) \(ingredient.unit ?? "") \(desc)"
            }
            if let brand = ingredient.brandName {
                desc += " (\(brand))"
            }
            return "- \(desc)"
        }.joined(separator: "\n")

        // Build user profile context
        var profileContext = ""
        if let profile = userProfile {
            var details: [String] = []

            if let skill = profile.cookingSkillLevel {
                details.append("Cooking Skill: \(skill.rawValue)")
            }

            if !profile.dietaryRestrictions.isEmpty {
                let restrictions = profile.dietaryRestrictions
                    .filter { $0 != .none }
                    .map { $0.rawValue }
                if !restrictions.isEmpty {
                    details.append("Dietary Restrictions: \(restrictions.joined(separator: ", "))")
                }
            }

            if let time = profile.timeAvailability {
                details.append("Available Time: \(time.maxMinutes) minutes max")
            }

            if !profile.cookingEquipment.isEmpty {
                details.append("Equipment: \(profile.cookingEquipment.map { $0.rawValue }.joined(separator: ", "))")
            }

            if let goal = profile.mainGoal {
                details.append("Cooking Goals: \(goal.rawValue)")
            }

            if let adventure = profile.adventureLevel {
                details.append("Recipe Complexity: \(adventure.rawValue)")
            }

            if !details.isEmpty {
                profileContext = """

                USER PROFILE:
                \(details.joined(separator: "\n"))
                """
            }
        }

        return """
        You are a recipe expert with extensive knowledge of recipes from trusted cooking sources.

        AVAILABLE INGREDIENTS:
        \(ingredientList)
        \(profileContext)

        Find \(count) REAL recipes from your knowledge of trusted cooking sources like:
        - NYT Cooking, Serious Eats, Bon Appétit
        - AllRecipes, Epicurious, Food Network
        - America's Test Kitchen, Simply Recipes

        Requirements:
        1. Use PRIMARILY the available ingredients listed above
        2. You may suggest common pantry staples if needed (salt, pepper, oil, basic spices)
        3. Include SOURCE NAME for each recipe (e.g., "Adapted from Serious Eats")
        4. Match the user's skill level and dietary restrictions if specified
        5. Provide accurate prep/cook times and techniques

        Return this exact JSON structure (no markdown):
        {
          "recipes": [
            {
              "name": "Recipe Title",
              "description": "Brief appetizing description",
              "ingredients": [{"name": "item", "amount": "2", "unit": "cups", "isOptional": false, "substitutes": []}],
              "instructions": ["Step 1", "Step 2"],
              "detailedSteps": [{"stepNumber": 1, "instruction": "Do this", "duration": 300, "technique": "sauté", "tips": ["tip"]}],
              "prepTime": 15,
              "cookTime": 30,
              "servings": 4,
              "difficulty": "easy",
              "cuisineType": "Italian",
              "nutritionPerServing": {"calories": 350, "protein": 25.0, "carbs": 30.0, "fat": 12.0},
              "tips": ["Chef tip"],
              "tags": ["quick", "healthy"],
              "source": {"name": "Serious Eats", "author": "J. Kenji López-Alt", "url": null}
            }
          ]
        }
        """
    }

    private func buildUserContext(from profile: UserProfile) -> String {
        var preferences: [String] = []

        // Main goal
        if let goal = profile.mainGoal {
            preferences.append("Main goal: \(goal.rawValue)")
        }

        // Dietary restrictions
        if !profile.dietaryRestrictions.isEmpty {
            let restrictions = profile.dietaryRestrictions
                .filter { $0 != .none }
                .map { $0.rawValue }
            if !restrictions.isEmpty {
                preferences.append("Dietary restrictions: \(restrictions.joined(separator: ", "))")
            }
        }

        // Skill level
        if let skill = profile.cookingSkillLevel {
            preferences.append("Cooking skill: \(skill.rawValue)")
        }

        // Meal preferences
        if !profile.mealPreferences.isEmpty {
            preferences.append("Preferred meal types: \(profile.mealPreferences.map { $0.rawValue }.joined(separator: ", "))")
        }

        // Time availability
        if let time = profile.timeAvailability {
            preferences.append("Max cooking time: \(time.maxMinutes) minutes")
        }

        // Equipment
        if !profile.cookingEquipment.isEmpty {
            preferences.append("Available equipment: \(profile.cookingEquipment.map { $0.rawValue }.joined(separator: ", "))")
        }

        // Cooking struggles
        if !profile.cookingStruggles.isEmpty {
            preferences.append("Areas to help with: \(profile.cookingStruggles.map { $0.rawValue }.joined(separator: ", "))")
        }

        // Adventure level
        if let adventure = profile.adventureLevel {
            preferences.append("Recipe complexity preference: \(adventure.rawValue)")
        }

        // Legacy cuisine preferences
        if !profile.cuisinePreferences.isEmpty {
            preferences.append("Preferred cuisines: \(profile.cuisinePreferences.map { $0.rawValue }.joined(separator: ", "))")
        }

        return preferences.isEmpty ? "" : "\n\nUser preferences:\n" + preferences.joined(separator: "\n")
    }

    private func buildAnalysisPrompt(userProfile: UserProfile?, aggressiveMode: Bool = false) -> String {
        var userContext = ""
        if let profile = userProfile {
            userContext = buildUserContext(from: profile)
        }

        let aggressivePrefix = aggressiveMode ? """
        IMPORTANT: You MUST detect food in this image. Look VERY CAREFULLY for ANY edible items including:
        - Packaged foods, canned goods, bottles, jars, containers
        - Fresh produce, fruits, vegetables (even if partially visible)
        - Meats, dairy products, eggs
        - Condiments, sauces, spices, seasonings
        - Frozen foods visible through packaging
        - Bread, baked goods, snacks
        - Beverages, drinks
        - ANY item that could be consumed as food or used in cooking

        Even if items are partially visible, blurry, in background, or in packaging - IDENTIFY THEM.
        Only return hasFood: false if the image contains ABSOLUTELY NO food items whatsoever (e.g., empty room, furniture only).

        """ : ""

        return """
        \(aggressivePrefix)You are ChefAI, a professional food recognition and recipe AI. Analyze this image with EXTREME PRECISION.

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

    private func buildRecipeGenerationPrompt(
        ingredients: [String],
        count: Int,
        userProfile: UserProfile?,
        excludingRecipes: [Recipe]
    ) -> String {
        let ingredientList = ingredients.joined(separator: ", ")

        var userContext = ""
        var personalizationRules = ""
        if let profile = userProfile {
            userContext = buildUserContext(from: profile)
            personalizationRules = buildPersonalizationRules(from: profile)
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
        \(personalizationRules)

        REQUIREMENTS:
        1. Each recipe must use ONLY ingredients from the list above
        2. Provide 8-12 detailed steps per recipe
        3. Include technique keywords (dice, julienne, sear, fold, simmer, etc.)
        4. Vary difficulty levels and cooking styles
        5. Include chef tips and nutrition estimates
        6. STRICTLY follow the personalization rules above

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

    private func buildPersonalizationRules(from profile: UserProfile) -> String {
        var rules: [String] = []

        // Goal-based nutrition filtering
        if let goal = profile.mainGoal {
            switch goal {
            case .loseWeight:
                rules.append("- Prioritize low-calorie, high-fiber, filling meals under 500 calories per serving")
            case .gainMuscle:
                rules.append("- Prioritize high-protein recipes (30g+ protein per serving), calorie-dense meals")
            case .maintainWeight:
                rules.append("- Provide balanced macros with moderate portions")
            case .eatHealthier:
                rules.append("- Focus on whole foods, vegetables, and minimally processed ingredients")
            case .saveTime:
                rules.append("- Prioritize recipes with minimal prep and cook time")
            case .saveMoney:
                rules.append("- Use budget-friendly ingredients and avoid expensive items")
            case .eatMoreProtein:
                rules.append("- Ensure each recipe has at least 25g protein per serving")
            }
        }

        // Time constraints
        if let time = profile.timeAvailability {
            rules.append("- STRICT: Total prep + cook time must NOT exceed \(time.maxMinutes) minutes")
        }

        // Equipment constraints
        if !profile.cookingEquipment.isEmpty {
            let equipmentNames = profile.cookingEquipment.map { $0.rawValue }
            rules.append("- Only use cooking methods available with: \(equipmentNames.joined(separator: ", "))")
        }

        // Skill + Adventure level combined
        if let skill = profile.cookingSkillLevel, let adventure = profile.adventureLevel {
            switch (skill, adventure) {
            case (.beginner, .simpleBasics):
                rules.append("- Use only basic techniques (boil, fry, bake) with common, familiar ingredients")
            case (.beginner, .sometimesAdventurous):
                rules.append("- Use basic techniques but can include 1-2 new flavor combinations")
            case (.beginner, .surpriseMe):
                rules.append("- Keep techniques simple but experiment with unique spice combinations")
            case (.intermediate, .simpleBasics):
                rules.append("- Use standard techniques with familiar comfort food flavors")
            case (.intermediate, .sometimesAdventurous):
                rules.append("- Mix of familiar and new cuisines, moderate technique complexity")
            case (.intermediate, .surpriseMe):
                rules.append("- Be creative with cuisines and flavors, intermediate techniques welcome")
            case (.advanced, .simpleBasics):
                rules.append("- Can use advanced techniques but keep flavors classic and familiar")
            case (.advanced, .sometimesAdventurous):
                rules.append("- Advanced techniques welcome, include some exotic ingredients")
            case (.advanced, .surpriseMe):
                rules.append("- Go bold! Complex techniques, exotic ingredients, creative fusion welcome")
            }
        }

        // Address cooking struggles in tips
        if !profile.cookingStruggles.isEmpty {
            var struggleTips: [String] = []
            for struggle in profile.cookingStruggles {
                switch struggle {
                case .dontKnowWhatToCook:
                    struggleTips.append("meal planning suggestions")
                case .noTime:
                    struggleTips.append("time-saving shortcuts")
                case .notConfident:
                    struggleTips.append("extra detailed instructions and technique explanations")
                case .wastingIngredients:
                    struggleTips.append("storage tips and leftover ideas")
                case .eatingHealthier:
                    struggleTips.append("nutritional benefits and healthy swaps")
                case .savingMoney:
                    struggleTips.append("budget tips and ingredient substitutions")
                }
            }
            rules.append("- Include tips specifically addressing: \(struggleTips.joined(separator: ", "))")
        }

        // Meal type preferences
        if !profile.mealPreferences.isEmpty {
            let prefNames = profile.mealPreferences.map { $0.rawValue }
            rules.append("- Prioritize recipes matching these styles: \(prefNames.joined(separator: ", "))")
        }

        if rules.isEmpty {
            return ""
        }

        return "\n\nRECIPE PERSONALIZATION RULES (MUST FOLLOW):\n" + rules.joined(separator: "\n")
    }

    // MARK: - Response Parsing

    private func parseAIResponse(_ content: String) throws -> AIAnalysisResult {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Robust JSON extraction - find first { and last }
        guard let startIndex = jsonString.firstIndex(of: "{"),
              let endIndex = jsonString.lastIndex(of: "}") else {
            print("❌ No JSON object found in response")
            print("📄 Content: \(jsonString.prefix(500))")
            throw AIServiceError.jsonParsingError
        }

        jsonString = String(jsonString[startIndex...endIndex])

        // Check for truncation indicators (response cut off mid-word)
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("nul") || trimmed.hasSuffix("tru") ||
           trimmed.hasSuffix("fals") || !trimmed.hasSuffix("}") {
            print("⚠️ Response appears truncated, JSON incomplete")
            print("📄 JSON ends with: ...\(String(trimmed.suffix(50)))")
            throw AIServiceError.jsonParsingError
        }

        print("🔍 Full extracted JSON length: \(jsonString.count) characters")

        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Failed to convert JSON string to UTF-8 data")
            throw AIServiceError.jsonParsingError
        }

        do {
            return try JSONDecoder().decode(AIAnalysisResult.self, from: data)
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Missing key '\(key.stringValue)': \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("❌ Type mismatch for \(type): \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("❌ Value not found \(type): \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("❌ Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("❌ Unknown decoding error: \(decodingError)")
            }
            print("📄 JSON preview: \(jsonString.prefix(800))")
            throw AIServiceError.jsonParsingError
        } catch {
            print("❌ Unexpected error: \(error)")
            throw AIServiceError.jsonParsingError
        }
    }

    private func parseRecipeGenerationResponse(_ content: String) throws -> RecipeGenerationResult {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Robust JSON extraction - find first { and last }
        guard let startIndex = jsonString.firstIndex(of: "{"),
              let endIndex = jsonString.lastIndex(of: "}") else {
            print("❌ No JSON object found in recipe generation response")
            throw AIServiceError.jsonParsingError
        }

        jsonString = String(jsonString[startIndex...endIndex])

        guard let data = jsonString.data(using: .utf8) else {
            throw AIServiceError.jsonParsingError
        }

        do {
            return try JSONDecoder().decode(RecipeGenerationResult.self, from: data)
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ Recipe gen missing key '\(key.stringValue)': \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("❌ Recipe gen type mismatch for \(type): \(context.debugDescription)")
            default:
                print("❌ Recipe gen decoding error: \(decodingError)")
            }
            throw AIServiceError.jsonParsingError
        } catch {
            print("❌ Recipe generation JSON parsing error: \(error)")
            throw AIServiceError.jsonParsingError
        }
    }

    // MARK: - Model Conversion

    private func convertIngredients(from aiResult: AIAnalysisResult?) -> [Ingredient] {
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

    private func convertRecipes(from aiResult: AIAnalysisResult?, manualItems: [String]) -> [Recipe] {
        guard let aiResult = aiResult, aiResult.hasFood else {
            if !manualItems.isEmpty {
                return generateFallbackRecipes(ingredients: manualItems)
            }
            return []
        }

        return aiResult.suggestedRecipes.map { convertSuggestedRecipe($0) }
    }

    private func convertSuggestedRecipe(_ suggested: AIAnalysisResult.SuggestedRecipe) -> Recipe {
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

    private func mapCategory(_ categoryString: String?) -> IngredientCategory? {
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

    private func mapDifficulty(_ difficultyString: String?) -> DifficultyLevel? {
        guard let difficulty = difficultyString?.lowercased() else { return .easy }

        switch difficulty {
        case "easy", "beginner", "simple": return .easy
        case "medium", "intermediate", "moderate": return .medium
        case "hard", "difficult", "advanced": return .hard
        case "expert", "professional", "master": return .expert
        default: return .easy
        }
    }

    private func generateFallbackRecipes(ingredients: [String]) -> [Recipe] {
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
