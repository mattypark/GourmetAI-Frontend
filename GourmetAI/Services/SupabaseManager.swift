//
//  SupabaseManager.swift
//  ChefAI
//
//  Created for ChefAI production deployment.
//

import Foundation
import Combine
import Supabase
import Auth

/// Manages all Supabase interactions for authentication and data persistence
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: .init(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        Task {
            await checkSession()
        }
    }

    // MARK: - Authentication

    /// Check if user has an existing session
    func checkSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        currentUser = response.user
        isAuthenticated = true
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
    }

    /// Sign in with Apple ID token
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        currentUser = session.user
        isAuthenticated = true
        print("Apple sign in successful for user: \(session.user.id)")
    }

    /// Sign in with Google tokens
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
        currentUser = session.user
        isAuthenticated = true
        print("Google sign in successful for user: \(session.user.id)")
    }

    /// Handle OAuth callback URL (for web-based OAuth flows)
    func handleOAuthCallback(url: URL) async {
        do {
            let session = try await client.auth.session(from: url)
            currentUser = session.user
            isAuthenticated = true
            print("OAuth callback handled for user: \(session.user.id)")
        } catch {
            print("OAuth callback error: \(error.localizedDescription)")
        }
    }

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Profile

    /// Save or update user profile
    func saveProfile(_ profile: UserProfileData) async throws {
        guard let userId = currentUser?.id else { return }

        var profileToSave = profile
        profileToSave.id = userId.uuidString
        profileToSave.updatedAt = Date()

        try await client
            .from("profiles")
            .upsert(profileToSave)
            .execute()
    }

    /// Get user profile
    func getProfile() async throws -> UserProfileData? {
        guard let userId = currentUser?.id else { return nil }

        let response: [UserProfileData] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        return response.first
    }

    /// Check if a profile exists in Supabase for the current user (used to detect returning users)
    func hasExistingProfile() async -> Bool {
        guard let userId = currentUser?.id else { return false }
        do {
            let response: [UserProfileData] = try await client
                .from("profiles")
                .select("id")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            return !response.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Saved Recipes

    /// Save a recipe
    func saveRecipe(_ recipe: SavedRecipeData) async throws {
        guard let userId = currentUser?.id else { return }

        var recipeData = recipe
        recipeData.userId = userId.uuidString

        try await client
            .from("saved_recipes")
            .insert(recipeData)
            .execute()
    }

    /// Get all saved recipes for current user
    func getSavedRecipes() async throws -> [SavedRecipeData] {
        guard let userId = currentUser?.id else { return [] }

        let response: [SavedRecipeData] = try await client
            .from("saved_recipes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    /// Delete a saved recipe
    func deleteRecipe(id: String) async throws {
        try await client
            .from("saved_recipes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Ingredient History

    /// Save ingredient scan to history
    func saveIngredientHistory(ingredients: [IngredientItem], imageUrl: String? = nil) async throws {
        guard let userId = currentUser?.id else { return }

        let historyEntry = IngredientHistoryInsert(
            userId: userId.uuidString,
            ingredients: ingredients,
            imageUrl: imageUrl
        )

        try await client
            .from("ingredient_history")
            .insert(historyEntry)
            .execute()
    }

    /// Get ingredient history
    func getIngredientHistory() async throws -> [IngredientHistoryData] {
        guard let userId = currentUser?.id else { return [] }

        let response: [IngredientHistoryData] = try await client
            .from("ingredient_history")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value

        return response
    }
}

// MARK: - Data Models for Supabase

struct UserProfileData: Codable {
    var id: String?
    var cookingSkillLevel: String?
    var dietaryRestrictions: [String]?
    var timeAvailability: Int?
    var mainGoal: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case cookingSkillLevel = "cooking_skill_level"
        case dietaryRestrictions = "dietary_restrictions"
        case timeAvailability = "time_availability"
        case mainGoal = "main_goal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct IngredientItem: Codable {
    var name: String
    var quantity: String?
    var unit: String?
}

struct IngredientHistoryInsert: Codable {
    var userId: String
    var ingredients: [IngredientItem]
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case ingredients
        case imageUrl = "image_url"
    }
}

struct SavedRecipeData: Codable {
    var id: String?
    var userId: String?
    var recipeData: [String: Any]?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recipeData = "recipe_data"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)

        // Decode JSONB as dictionary
        if let jsonData = try? container.decode(Data.self, forKey: .recipeData) {
            recipeData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)

        if let data = recipeData {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try container.encode(jsonData, forKey: .recipeData)
        }
    }
}

struct IngredientHistoryData: Codable {
    var id: String?
    var userId: String?
    var ingredients: [[String: Any]]?
    var imageUrl: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ingredients
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)

        if let jsonData = try? container.decode(Data.self, forKey: .ingredients) {
            ingredients = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)

        if let data = ingredients {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try container.encode(jsonData, forKey: .ingredients)
        }
    }
}
