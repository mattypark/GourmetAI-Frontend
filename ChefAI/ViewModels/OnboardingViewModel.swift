//
//  OnboardingViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var userProfile: UserProfile = UserProfile()
    @Published var selectedGoal: CookingGoal?
    @Published var selectedRestrictions: Set<DietaryRestriction> = []
    @Published var selectedSkillLevel: SkillLevel?
    @Published var selectedCookingStyle: CookingStyle?
    @Published var selectedCuisinePreferences: Set<CuisineType> = []

    private let storageService: StorageService

    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: 0,
            title: "What is your main goal with the foods you like?",
            subtitle: "This helps us suggest recipes that match your needs",
            type: .singleChoice(CookingGoal.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 1,
            title: "Any dietary restrictions?",
            subtitle: "Select all that apply",
            type: .multipleChoice(DietaryRestriction.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 2,
            title: "What's your cooking skill level?",
            subtitle: "This helps us match recipe difficulty",
            type: .singleChoice(SkillLevel.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 3,
            title: "How would you like to cook your food?",
            subtitle: "Choose your preferred cooking style",
            type: .singleChoice(CookingStyle.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 4,
            title: "What type of food do you typically like?",
            subtitle: "Select all cuisines you enjoy",
            type: .multipleChoice(CuisineType.allCases.map { $0.rawValue })
        )
    ]

    init(storageService: StorageService = .shared) {
        self.storageService = storageService
        let profile = storageService.loadUserProfile()
        self.userProfile = profile
        self.selectedGoal = profile.mainGoal
        self.selectedRestrictions = Set(profile.dietaryRestrictions)
        self.selectedSkillLevel = profile.cookingSkillLevel
        self.selectedCookingStyle = profile.cookingStyle
        self.selectedCuisinePreferences = Set(profile.cuisinePreferences)
    }

    var canProceed: Bool {
        switch currentPage {
        case 0: return selectedGoal != nil
        case 1: return true // Optional - dietary restrictions
        case 2: return selectedSkillLevel != nil
        case 3: return true // Optional - cooking style
        case 4: return true // Optional - cuisine preferences
        default: return false
        }
    }

    var isLastQuestion: Bool {
        currentPage == questions.count - 1
    }

    func nextPage() {
        guard currentPage < questions.count - 1 else { return }
        currentPage += 1
    }

    func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }

    func skip() {
        currentPage = questions.count - 1
    }

    func completeOnboarding() {
        userProfile.mainGoal = selectedGoal
        userProfile.dietaryRestrictions = Array(selectedRestrictions)
        userProfile.cookingSkillLevel = selectedSkillLevel
        userProfile.cookingStyle = selectedCookingStyle
        userProfile.cuisinePreferences = Array(selectedCuisinePreferences)
        userProfile.updatedAt = Date()

        storageService.saveUserProfile(userProfile)
        storageService.setOnboardingComplete(true)
    }
}
