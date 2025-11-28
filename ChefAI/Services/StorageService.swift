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

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
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

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) {
        save(profile, to: userProfileURL)
    }

    func loadUserProfile() -> UserProfile {
        load(from: userProfileURL) ?? UserProfile()
    }

    // MARK: - Analyses

    func saveAnalyses(_ analyses: [AnalysisResult]) {
        // Enforce 50 max limit - keep only most recent
        let limitedAnalyses = Array(analyses.prefix(AppConstants.maxStoredAnalyses))
        save(limitedAnalyses, to: analysesURL)
    }

    func loadAnalyses() -> [AnalysisResult] {
        load(from: analysesURL) ?? []
    }

    // MARK: - Liked Recipes

    func saveLikedRecipes(_ recipes: [Recipe]) {
        save(recipes, to: likedRecipesURL)
    }

    func loadLikedRecipes() -> [Recipe] {
        load(from: likedRecipesURL) ?? []
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
        hasCompletedOnboardingStorage = false
    }

    // MARK: - Generic Save/Load

    private func save<T: Encodable>(_ object: T, to url: URL) {
        do {
            let data = try encoder.encode(object)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Error saving to \(url): \(error)")
        }
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error loading from \(url): \(error)")
            return nil
        }
    }
}
