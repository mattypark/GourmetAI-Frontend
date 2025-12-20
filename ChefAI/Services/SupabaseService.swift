//
//  SupabaseService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import Foundation
import Supabase

// MARK: - Supabase Database Models

struct DBUser: Codable {
    let id: UUID
    var createdAt: Date?
    var updatedAt: Date?
    var name: String?
    var email: String?
    var profileImageUrl: String?
    var mainGoal: String?
    var dietaryRestrictions: [String]?
    var cookingSkillLevel: String?
    var mealPreferences: [String]?
    var timeAvailability: String?
    var cookingEquipment: [String]?
    var cookingStruggles: [String]?
    var adventureLevel: String?
    var cuisinePreferences: [String]?
    var hasCompletedOnboarding: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name, email
        case profileImageUrl = "profile_image_url"
        case mainGoal = "main_goal"
        case dietaryRestrictions = "dietary_restrictions"
        case cookingSkillLevel = "cooking_skill_level"
        case mealPreferences = "meal_preferences"
        case timeAvailability = "time_availability"
        case cookingEquipment = "cooking_equipment"
        case cookingStruggles = "cooking_struggles"
        case adventureLevel = "adventure_level"
        case cuisinePreferences = "cuisine_preferences"
        case hasCompletedOnboarding = "has_completed_onboarding"
    }
}

struct DBAnalysis: Codable {
    let id: UUID
    var userId: UUID?
    var createdAt: Date?
    var imageUrl: String?
    var manuallyAddedItems: [String]?
    var ingredientCount: Int?
    var recipeCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case imageUrl = "image_url"
        case manuallyAddedItems = "manually_added_items"
        case ingredientCount = "ingredient_count"
        case recipeCount = "recipe_count"
    }
}

struct DBIngredient: Codable {
    let id: UUID
    var analysisId: UUID?
    var userId: UUID?
    var createdAt: Date?
    var name: String
    var brandName: String?
    var quantity: String?
    var unit: String?
    var category: String?
    var confidence: Double?
    var barcode: String?
    var expirationDate: Date?
    var dateAdded: Date?
    var nutritionInfo: Data?
    var inPantry: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case analysisId = "analysis_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case name
        case brandName = "brand_name"
        case quantity, unit, category, confidence, barcode
        case expirationDate = "expiration_date"
        case dateAdded = "date_added"
        case nutritionInfo = "nutrition_info"
        case inPantry = "in_pantry"
    }
}

struct DBRecipe: Codable {
    let id: UUID
    var userId: UUID?
    var analysisId: UUID?
    var createdAt: Date?
    var name: String
    var description: String?
    var cuisineType: String?
    var prepTime: Int?
    var cookTime: Int?
    var servings: Int?
    var difficulty: String?
    var instructions: [String]?
    var detailedSteps: Data?
    var tags: [String]?
    var tips: [String]?
    var nutritionPerServing: Data?
    var source: Data?
    var isLiked: Bool?
    var timesCooked: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case analysisId = "analysis_id"
        case createdAt = "created_at"
        case name, description
        case cuisineType = "cuisine_type"
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case servings, difficulty, instructions
        case detailedSteps = "detailed_steps"
        case tags, tips
        case nutritionPerServing = "nutrition_per_serving"
        case source
        case isLiked = "is_liked"
        case timesCooked = "times_cooked"
    }
}

struct DBRecipeIngredient: Codable {
    let id: UUID
    var recipeId: UUID?
    var name: String
    var amount: String?
    var unit: String?
    var isOptional: Bool?
    var substitutes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case name, amount, unit
        case isOptional = "is_optional"
        case substitutes
    }
}

struct DBPantryItem: Codable {
    let id: UUID
    var userId: UUID?
    var ingredientId: UUID?
    var createdAt: Date?
    var updatedAt: Date?
    var name: String
    var brandName: String?
    var quantity: String?
    var unit: String?
    var category: String?
    var expirationDate: Date?
    var isAvailable: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ingredientId = "ingredient_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name
        case brandName = "brand_name"
        case quantity, unit, category
        case expirationDate = "expiration_date"
        case isAvailable = "is_available"
    }
}

// MARK: - Supabase Service

@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    // Current user ID (anonymous for now - can add auth later)
    private(set) var currentUserId: UUID?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Anonymous User Setup

    func ensureAnonymousUser() async throws -> UUID {
        // If we already have a user ID stored, use it
        if let storedId = UserDefaults.standard.string(forKey: "supabase_user_id"),
           let uuid = UUID(uuidString: storedId) {
            currentUserId = uuid
            return uuid
        }

        // Create new anonymous user
        let newId = UUID()
        let newUser = DBUser(
            id: newId,
            createdAt: Date(),
            updatedAt: Date(),
            hasCompletedOnboarding: false
        )

        try await client.from("users")
            .insert(newUser)
            .execute()

        // Store the user ID locally
        UserDefaults.standard.set(newId.uuidString, forKey: "supabase_user_id")
        currentUserId = newId

        print("🔐 Created anonymous Supabase user: \(newId)")
        return newId
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) async throws {
        guard let userId = currentUserId else {
            _ = try await ensureAnonymousUser()
            try await saveUserProfile(profile)
            return
        }

        let dbUser = DBUser(
            id: userId,
            createdAt: nil, // Don't overwrite
            updatedAt: Date(),
            mainGoal: profile.mainGoal?.rawValue,
            dietaryRestrictions: profile.dietaryRestrictions.map { $0.rawValue },
            cookingSkillLevel: profile.cookingSkillLevel?.rawValue,
            mealPreferences: profile.mealPreferences.map { $0.rawValue },
            timeAvailability: profile.timeAvailability?.rawValue,
            cookingEquipment: profile.cookingEquipment.map { $0.rawValue },
            cookingStruggles: profile.cookingStruggles.map { $0.rawValue },
            adventureLevel: profile.adventureLevel?.rawValue,
            cuisinePreferences: profile.cuisinePreferences.map { $0.rawValue },
            hasCompletedOnboarding: profile.isOnboardingComplete
        )

        try await client.from("users")
            .upsert(dbUser)
            .execute()

        print("💾 Saved user profile to Supabase")
    }

    func loadUserProfile() async throws -> UserProfile? {
        guard let userId = currentUserId else { return nil }

        let response: [DBUser] = try await client.from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        guard let dbUser = response.first else { return nil }

        var profile = UserProfile()
        profile.id = dbUser.id

        if let goal = dbUser.mainGoal {
            profile.mainGoal = MainGoal(rawValue: goal)
        }
        if let restrictions = dbUser.dietaryRestrictions {
            profile.dietaryRestrictions = restrictions.compactMap { ExtendedDietaryRestriction(rawValue: $0) }
        }
        if let skill = dbUser.cookingSkillLevel {
            profile.cookingSkillLevel = SkillLevel(rawValue: skill)
        }
        if let meals = dbUser.mealPreferences {
            profile.mealPreferences = meals.compactMap { MealPreference(rawValue: $0) }
        }
        if let time = dbUser.timeAvailability {
            profile.timeAvailability = TimeAvailability(rawValue: time)
        }
        if let equipment = dbUser.cookingEquipment {
            profile.cookingEquipment = equipment.compactMap { CookingEquipment(rawValue: $0) }
        }
        if let struggles = dbUser.cookingStruggles {
            profile.cookingStruggles = struggles.compactMap { CookingStruggle(rawValue: $0) }
        }
        if let adventure = dbUser.adventureLevel {
            profile.adventureLevel = AdventureLevel(rawValue: adventure)
        }
        if let cuisines = dbUser.cuisinePreferences {
            profile.cuisinePreferences = cuisines.compactMap { CuisineType(rawValue: $0) }
        }

        return profile
    }

    // MARK: - Analyses

    func saveAnalysis(_ analysis: AnalysisResult) async throws {
        guard let userId = currentUserId else {
            _ = try await ensureAnonymousUser()
            try await saveAnalysis(analysis)
            return
        }

        // Upload image to storage if present
        var imageUrl: String?
        if let imageData = analysis.imageData {
            imageUrl = try await uploadImage(imageData, analysisId: analysis.id)
        }

        // Save analysis record
        let dbAnalysis = DBAnalysis(
            id: analysis.id,
            userId: userId,
            createdAt: analysis.date,
            imageUrl: imageUrl,
            manuallyAddedItems: analysis.manuallyAddedItems,
            ingredientCount: analysis.extractedIngredients.count,
            recipeCount: analysis.suggestedRecipes.count
        )

        try await client.from("analyses")
            .upsert(dbAnalysis)
            .execute()

        // Save ingredients
        for ingredient in analysis.extractedIngredients {
            let dbIngredient = DBIngredient(
                id: ingredient.id,
                analysisId: analysis.id,
                userId: userId,
                createdAt: Date(),
                name: ingredient.name,
                brandName: ingredient.brandName,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                category: ingredient.category?.rawValue,
                confidence: ingredient.confidence,
                barcode: ingredient.barcode,
                expirationDate: ingredient.expirationDate,
                dateAdded: ingredient.dateAdded,
                nutritionInfo: nil,
                inPantry: false
            )

            try await client.from("ingredients")
                .upsert(dbIngredient)
                .execute()
        }

        // Save recipes
        for recipe in analysis.suggestedRecipes {
            try await saveRecipe(recipe, analysisId: analysis.id)
        }

        print("💾 Saved analysis to Supabase: \(analysis.id)")
    }

    func loadAnalyses() async throws -> [AnalysisResult] {
        guard let userId = currentUserId else { return [] }

        let analyses: [DBAnalysis] = try await client.from("analyses")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        var results: [AnalysisResult] = []

        for dbAnalysis in analyses {
            // Load ingredients for this analysis
            let ingredients: [DBIngredient] = try await client.from("ingredients")
                .select()
                .eq("analysis_id", value: dbAnalysis.id.uuidString)
                .execute()
                .value

            // Load recipes for this analysis
            let recipes: [DBRecipe] = try await client.from("recipes")
                .select()
                .eq("analysis_id", value: dbAnalysis.id.uuidString)
                .execute()
                .value

            // Download image if URL exists
            var imageData: Data?
            if let imageUrl = dbAnalysis.imageUrl {
                imageData = try? await downloadImage(imageUrl)
            }

            let result = AnalysisResult(
                id: dbAnalysis.id,
                extractedIngredients: ingredients.map { convertToIngredient($0) },
                suggestedRecipes: try await loadFullRecipes(recipes),
                date: dbAnalysis.createdAt ?? Date(),
                imageData: imageData,
                manuallyAddedItems: dbAnalysis.manuallyAddedItems ?? []
            )

            results.append(result)
        }

        return results
    }

    // MARK: - Recipes

    func saveRecipe(_ recipe: Recipe, analysisId: UUID? = nil) async throws {
        guard let userId = currentUserId else {
            _ = try await ensureAnonymousUser()
            try await saveRecipe(recipe, analysisId: analysisId)
            return
        }

        let encoder = JSONEncoder()
        let detailedStepsData = try? encoder.encode(recipe.detailedSteps)
        let nutritionData = try? encoder.encode(recipe.nutritionPerServing)
        let sourceData = try? encoder.encode(recipe.source)

        let dbRecipe = DBRecipe(
            id: recipe.id,
            userId: userId,
            analysisId: analysisId,
            createdAt: recipe.dateGenerated,
            name: recipe.name,
            description: recipe.description,
            cuisineType: recipe.cuisineType,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            servings: recipe.servings,
            difficulty: recipe.difficulty?.rawValue,
            instructions: recipe.instructions,
            detailedSteps: detailedStepsData,
            tags: recipe.tags,
            tips: recipe.tips,
            nutritionPerServing: nutritionData,
            source: sourceData,
            isLiked: recipe.isLiked,
            timesCooked: 0
        )

        try await client.from("recipes")
            .upsert(dbRecipe)
            .execute()

        // Save recipe ingredients
        for ingredient in recipe.ingredients {
            let dbIngredient = DBRecipeIngredient(
                id: ingredient.id,
                recipeId: recipe.id,
                name: ingredient.name,
                amount: ingredient.amount,
                unit: ingredient.unit,
                isOptional: ingredient.isOptional,
                substitutes: ingredient.substitutes
            )

            try await client.from("recipe_ingredients")
                .upsert(dbIngredient)
                .execute()
        }
    }

    func loadLikedRecipes() async throws -> [Recipe] {
        guard let userId = currentUserId else { return [] }

        let recipes: [DBRecipe] = try await client.from("recipes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_liked", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value

        return try await loadFullRecipes(recipes)
    }

    func updateRecipeLikeStatus(_ recipe: Recipe) async throws {
        try await client.from("recipes")
            .update(["is_liked": recipe.isLiked])
            .eq("id", value: recipe.id.uuidString)
            .execute()
    }

    // MARK: - Image Storage

    private func uploadImage(_ data: Data, analysisId: UUID) async throws -> String {
        let path = "analyses/\(analysisId.uuidString).jpg"

        _ = try await client.storage
            .from("analysis-images")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))

        return path
    }

    private func downloadImage(_ path: String) async throws -> Data {
        return try await client.storage
            .from("analysis-images")
            .download(path: path)
    }

    // MARK: - Helpers

    private func convertToIngredient(_ db: DBIngredient) -> Ingredient {
        Ingredient(
            id: db.id,
            name: db.name,
            brandName: db.brandName,
            quantity: db.quantity,
            unit: db.unit,
            category: db.category.flatMap { IngredientCategory(rawValue: $0) },
            confidence: db.confidence,
            nutritionInfo: nil,
            barcode: db.barcode,
            expirationDate: db.expirationDate,
            dateAdded: db.dateAdded ?? Date()
        )
    }

    private func loadFullRecipes(_ dbRecipes: [DBRecipe]) async throws -> [Recipe] {
        var recipes: [Recipe] = []
        let decoder = JSONDecoder()

        for dbRecipe in dbRecipes {
            // Load recipe ingredients
            let dbIngredients: [DBRecipeIngredient] = try await client.from("recipe_ingredients")
                .select()
                .eq("recipe_id", value: dbRecipe.id.uuidString)
                .execute()
                .value

            let ingredients = dbIngredients.map { db in
                RecipeIngredient(
                    id: db.id,
                    name: db.name,
                    amount: db.amount ?? "",
                    unit: db.unit,
                    isOptional: db.isOptional ?? false,
                    substitutes: db.substitutes ?? []
                )
            }

            var detailedSteps: [RecipeStep] = []
            if let data = dbRecipe.detailedSteps {
                detailedSteps = (try? decoder.decode([RecipeStep].self, from: data)) ?? []
            }

            var nutritionInfo: NutritionInfo?
            if let data = dbRecipe.nutritionPerServing {
                nutritionInfo = try? decoder.decode(NutritionInfo.self, from: data)
            }

            var source: RecipeSource?
            if let data = dbRecipe.source {
                source = try? decoder.decode(RecipeSource.self, from: data)
            }

            let recipe = Recipe(
                id: dbRecipe.id,
                name: dbRecipe.name,
                description: dbRecipe.description,
                instructions: dbRecipe.instructions ?? [],
                detailedSteps: detailedSteps,
                ingredients: ingredients,
                isLiked: dbRecipe.isLiked ?? false,
                tags: dbRecipe.tags ?? [],
                prepTime: dbRecipe.prepTime,
                cookTime: dbRecipe.cookTime,
                servings: dbRecipe.servings,
                difficulty: dbRecipe.difficulty.flatMap { DifficultyLevel(rawValue: $0) },
                cuisineType: dbRecipe.cuisineType,
                nutritionPerServing: nutritionInfo,
                tips: dbRecipe.tips ?? [],
                source: source,
                dateGenerated: dbRecipe.createdAt ?? Date()
            )

            recipes.append(recipe)
        }

        return recipes
    }

    // MARK: - Clear Data

    func clearAllData() async throws {
        guard let userId = currentUserId else { return }

        // First get all recipe IDs for this user
        let userRecipes: [DBRecipe] = try await client.from("recipes")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        // Delete recipe ingredients for each recipe
        for recipe in userRecipes {
            try await client.from("recipe_ingredients")
                .delete()
                .eq("recipe_id", value: recipe.id.uuidString)
                .execute()
        }

        try await client.from("pantry_items")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await client.from("recipes")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await client.from("ingredients")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        try await client.from("analyses")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Reset user to initial state
        try await client.from("users")
            .update(["has_completed_onboarding": false])
            .eq("id", value: userId.uuidString)
            .execute()

        print("🗑️ Cleared all Supabase data for user")
    }
}
