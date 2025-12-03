//
//  SettingsViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // User Profile - Basic Info
    @Published var userName: String = "Chef"
    @Published var userEmail: String = ""
    @Published var userBio: String = ""
    @Published var profileImage: UIImage?

    // User Profile - Preferences (from onboarding)
    @Published var mainGoal: CookingGoal?
    @Published var dietaryRestrictions: Set<DietaryRestriction> = []
    @Published var cookingSkillLevel: SkillLevel?
    @Published var cookingStyle: CookingStyle?
    @Published var cuisinePreferences: Set<CuisineType> = []

    // App Settings
    @Published var notificationsEnabled: Bool = true
    @Published var saveRecipeImages: Bool = true
    @Published var darkModeEnabled: Bool = true
    @Published var hapticFeedbackEnabled: Bool = true

    private let storageService = StorageService.shared

    // Storage Keys
    private enum Keys {
        static let userName = "settings.userName"
        static let userEmail = "settings.userEmail"
        static let userBio = "settings.userBio"
        static let notificationsEnabled = "settings.notificationsEnabled"
        static let saveRecipeImages = "settings.saveRecipeImages"
        static let darkModeEnabled = "settings.darkModeEnabled"
        static let hapticFeedbackEnabled = "settings.hapticFeedbackEnabled"
    }

    init() {
        loadSettings()
        loadUserProfile()
    }

    func loadSettings() {
        userName = UserDefaults.standard.string(forKey: Keys.userName) ?? "Chef"
        userEmail = UserDefaults.standard.string(forKey: Keys.userEmail) ?? ""
        userBio = UserDefaults.standard.string(forKey: Keys.userBio) ?? ""
        notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        saveRecipeImages = UserDefaults.standard.bool(forKey: Keys.saveRecipeImages)
        darkModeEnabled = UserDefaults.standard.bool(forKey: Keys.darkModeEnabled)
        hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: Keys.hapticFeedbackEnabled)
    }

    func loadUserProfile() {
        let profile = storageService.loadUserProfile()
        mainGoal = profile.mainGoal
        dietaryRestrictions = Set(profile.dietaryRestrictions)
        cookingSkillLevel = profile.cookingSkillLevel
        cookingStyle = profile.cookingStyle
        cuisinePreferences = Set(profile.cuisinePreferences)

        // Load profile image
        if let imageData = storageService.loadProfileImage() {
            profileImage = UIImage(data: imageData)
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(userName, forKey: Keys.userName)
        UserDefaults.standard.set(userEmail, forKey: Keys.userEmail)
        UserDefaults.standard.set(userBio, forKey: Keys.userBio)
        UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        UserDefaults.standard.set(saveRecipeImages, forKey: Keys.saveRecipeImages)
        UserDefaults.standard.set(darkModeEnabled, forKey: Keys.darkModeEnabled)
        UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled)

        // Save user profile preferences
        saveUserProfile()
    }

    func saveUserProfile() {
        var profile = storageService.loadUserProfile()
        profile.mainGoal = mainGoal
        profile.dietaryRestrictions = Array(dietaryRestrictions)
        profile.cookingSkillLevel = cookingSkillLevel
        profile.cookingStyle = cookingStyle
        profile.cuisinePreferences = Array(cuisinePreferences)
        profile.updatedAt = Date()
        storageService.saveUserProfile(profile)

        // Save profile image if changed
        if let image = profileImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            storageService.saveProfileImage(imageData)
        }
    }

    func updateProfileImage(_ image: UIImage?) {
        profileImage = image
        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            storageService.saveProfileImage(imageData)
        } else {
            storageService.deleteProfileImage()
        }
    }

    func resetSettings() {
        userName = "Chef"
        userEmail = ""
        userBio = ""
        notificationsEnabled = true
        saveRecipeImages = true
        darkModeEnabled = true
        hapticFeedbackEnabled = true
        saveSettings()
    }

    func clearAllData() {
        // Clear analyses
        storageService.saveAnalyses([])

        // Reset settings
        resetSettings()
    }
}
