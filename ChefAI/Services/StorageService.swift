//
//  StorageService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import SwiftUI

final class StorageService: @unchecked Sendable {
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

    private var profileImageURL: URL {
        documentsDirectory.appendingPathComponent("profileImage.jpg")
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
    }

    func loadAnalyses() -> [AnalysisResult] {
        load(from: analysesURL) ?? []
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
        try? fileManager.removeItem(at: profileImageURL)
        hasCompletedOnboardingStorage = false
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
