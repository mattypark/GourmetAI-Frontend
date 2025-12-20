//
//  StorageService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import SwiftUI

class StorageService {
    static let shared = StorageService()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Use Supabase as primary storage
    private var useSupabase = true

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        // Initialize Supabase user on startup
        Task {
            do {
                _ = try await SupabaseService.shared.ensureAnonymousUser()
                print("✅ Supabase connected")
            } catch {
                print("⚠️ Supabase unavailable, using local storage: \(error.localizedDescription)")
                await MainActor.run {
                    self.useSupabase = false
                }
            }
        }
    }

    // MARK: - File URLs

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var userProfileURL: URL {
        documentsDirectory.appendingPathComponent("userProfile.json")
    }

    private var analysesURL: URL {
        documentsDirectory.appendingPathComponent("analyses.json")
    }

    private var likedRecipesURL: URL {
        documentsDirectory.appendingPathComponent("likedRecipes.json")
    }

    private var profileImageURL: URL {
        documentsDirectory.appendingPathComponent("profileImage.jpg")
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) {
        // Save locally first
        save(profile, to: userProfileURL)

        // Then sync to Supabase
        if useSupabase {
            Task {
                do {
                    try await SupabaseService.shared.saveUserProfile(profile)
                } catch {
                    print("⚠️ Failed to save profile to Supabase: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadUserProfile() -> UserProfile {
        // Return local data immediately
        load(from: userProfileURL) ?? UserProfile()
    }

    func loadUserProfileAsync() async -> UserProfile {
        // Try Supabase first
        if useSupabase {
            do {
                if let profile = try await SupabaseService.shared.loadUserProfile() {
                    // Update local cache
                    save(profile, to: userProfileURL)
                    return profile
                }
            } catch {
                print("⚠️ Failed to load profile from Supabase: \(error.localizedDescription)")
            }
        }

        // Fall back to local
        return load(from: userProfileURL) ?? UserProfile()
    }

    // MARK: - Analyses

    func saveAnalyses(_ analyses: [AnalysisResult]) {
        // Enforce 50 max limit - keep only most recent
        let limitedAnalyses = Array(analyses.prefix(AppConstants.maxStoredAnalyses))
        save(limitedAnalyses, to: analysesURL)

        // Sync to Supabase (save each analysis)
        if useSupabase {
            Task {
                for analysis in limitedAnalyses {
                    do {
                        try await SupabaseService.shared.saveAnalysis(analysis)
                    } catch {
                        print("⚠️ Failed to save analysis to Supabase: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func saveAnalysis(_ analysis: AnalysisResult) {
        // Load existing, add new, save all
        var analyses = loadAnalyses()
        if let index = analyses.firstIndex(where: { $0.id == analysis.id }) {
            analyses[index] = analysis
        } else {
            analyses.insert(analysis, at: 0)
        }
        let limitedAnalyses = Array(analyses.prefix(AppConstants.maxStoredAnalyses))
        save(limitedAnalyses, to: analysesURL)

        // Sync single analysis to Supabase
        if useSupabase {
            Task {
                do {
                    try await SupabaseService.shared.saveAnalysis(analysis)
                } catch {
                    print("⚠️ Failed to save analysis to Supabase: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadAnalyses() -> [AnalysisResult] {
        load(from: analysesURL) ?? []
    }

    func loadAnalysesAsync() async -> [AnalysisResult] {
        // Try Supabase first
        if useSupabase {
            do {
                let analyses = try await SupabaseService.shared.loadAnalyses()
                if !analyses.isEmpty {
                    // Update local cache
                    let limitedAnalyses = Array(analyses.prefix(AppConstants.maxStoredAnalyses))
                    save(limitedAnalyses, to: analysesURL)
                    return analyses
                }
            } catch {
                print("⚠️ Failed to load analyses from Supabase: \(error.localizedDescription)")
            }
        }

        // Fall back to local
        return load(from: analysesURL) ?? []
    }

    // MARK: - Liked Recipes

    func saveLikedRecipes(_ recipes: [Recipe]) {
        save(recipes, to: likedRecipesURL)

        // Sync to Supabase
        if useSupabase {
            Task {
                for recipe in recipes where recipe.isLiked {
                    do {
                        try await SupabaseService.shared.saveRecipe(recipe)
                    } catch {
                        print("⚠️ Failed to save recipe to Supabase: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func saveRecipe(_ recipe: Recipe) {
        // Update in liked recipes list
        var recipes = loadLikedRecipes()
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else if recipe.isLiked {
            recipes.append(recipe)
        }
        save(recipes, to: likedRecipesURL)

        // Sync to Supabase
        if useSupabase {
            Task {
                do {
                    try await SupabaseService.shared.saveRecipe(recipe)
                    try await SupabaseService.shared.updateRecipeLikeStatus(recipe)
                } catch {
                    print("⚠️ Failed to save recipe to Supabase: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadLikedRecipes() -> [Recipe] {
        load(from: likedRecipesURL) ?? []
    }

    func loadLikedRecipesAsync() async -> [Recipe] {
        // Try Supabase first
        if useSupabase {
            do {
                let recipes = try await SupabaseService.shared.loadLikedRecipes()
                if !recipes.isEmpty {
                    // Update local cache
                    save(recipes, to: likedRecipesURL)
                    return recipes
                }
            } catch {
                print("⚠️ Failed to load recipes from Supabase: \(error.localizedDescription)")
            }
        }

        // Fall back to local
        return load(from: likedRecipesURL) ?? []
    }

    // MARK: - Profile Image

    func saveProfileImage(_ imageData: Data) {
        do {
            try imageData.write(to: profileImageURL, options: .atomic)
        } catch {
            print("Error saving profile image: \(error)")
        }
    }

    func loadProfileImage() -> Data? {
        guard fileManager.fileExists(atPath: profileImageURL.path) else { return nil }
        return try? Data(contentsOf: profileImageURL)
    }

    func deleteProfileImage() {
        try? fileManager.removeItem(at: profileImageURL)
    }

    // MARK: - Onboarding

    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboardingStorage = false

    func setOnboardingComplete(_ complete: Bool) {
        hasCompletedOnboardingStorage = complete
    }

    func hasCompletedOnboarding() -> Bool {
        hasCompletedOnboardingStorage
    }

    // MARK: - Clear Data

    func clearAllData() {
        try? fileManager.removeItem(at: userProfileURL)
        try? fileManager.removeItem(at: analysesURL)
        try? fileManager.removeItem(at: likedRecipesURL)
        try? fileManager.removeItem(at: profileImageURL)
        hasCompletedOnboardingStorage = false

        // Clear Supabase data
        if useSupabase {
            Task {
                do {
                    try await SupabaseService.shared.clearAllData()
                } catch {
                    print("⚠️ Failed to clear Supabase data: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Generic Save/Load

    private func save<T: Encodable>(_ object: T, to url: URL) {
        do {
            // Ensure directory exists
            let directory = url.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            let data = try encoder.encode(object)
            try data.write(to: url, options: .atomic)
            print("💾 Saved to \(url.lastPathComponent)")
        } catch {
            print("❌ Error saving to \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else {
            print("📦 No saved data found at \(url.lastPathComponent)")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, context) {
            print("⚠️ Missing key '\(key.stringValue)' in \(url.lastPathComponent): \(context.debugDescription)")
            // Delete corrupted file to allow fresh start
            try? fileManager.removeItem(at: url)
            print("🗑️ Deleted corrupted file: \(url.lastPathComponent)")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            print("⚠️ Type mismatch for \(type) in \(url.lastPathComponent): \(context.debugDescription)")
            try? fileManager.removeItem(at: url)
            print("🗑️ Deleted corrupted file: \(url.lastPathComponent)")
            return nil
        } catch let DecodingError.dataCorrupted(context) {
            print("⚠️ Data corrupted in \(url.lastPathComponent): \(context.debugDescription)")
            try? fileManager.removeItem(at: url)
            print("🗑️ Deleted corrupted file: \(url.lastPathComponent)")
            return nil
        } catch {
            print("❌ Error loading \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
}
