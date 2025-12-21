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

    // Selections for each question
    @Published var selectedMainGoal: MainGoal?
    @Published var selectedRestrictions: Set<ExtendedDietaryRestriction> = []
    @Published var selectedSkillLevel: SkillLevel?
    @Published var selectedMealPreferences: Set<MealPreference> = []
    @Published var selectedTimeAvailability: TimeAvailability?
    @Published var selectedEquipment: Set<CookingEquipment> = []
    @Published var selectedStruggles: Set<CookingStruggle> = []
    @Published var selectedAdventureLevel: AdventureLevel?

    private let storageService: StorageService

    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: 0,
            title: "What's your main goal?",
            subtitle: "This helps us suggest recipes that support your lifestyle",
            type: .singleChoice(MainGoal.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 1,
            title: "Any dietary restrictions or allergies?",
            subtitle: "Select all that apply",
            type: .multipleChoice(ExtendedDietaryRestriction.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 2,
            title: "How experienced are you in the kitchen?",
            subtitle: "We'll match recipe difficulty to your skill level",
            type: .singleChoice(SkillLevel.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 3,
            title: "What types of meals do you like?",
            subtitle: "Select all that appeal to you",
            type: .multipleChoice(MealPreference.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 4,
            title: "How much time do you want to spend cooking?",
            subtitle: "We'll filter recipes to fit your schedule",
            type: .singleChoice(TimeAvailability.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 5,
            title: "What cooking equipment do you have?",
            subtitle: "Select all the tools available in your kitchen",
            type: .multipleChoice(CookingEquipment.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 6,
            title: "What do you struggle with most?",
            subtitle: "We'll help address these challenges",
            type: .multipleChoice(CookingStruggle.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 7,
            title: "How adventurous are you with food?",
            subtitle: "This affects how creative our suggestions get",
            type: .singleChoice(AdventureLevel.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 8,
            title: "You're all set!",
            subtitle: "Here's a summary of your preferences",
            type: .custom
        )
    ]

    init(storageService: StorageService? = nil) {
        self.storageService = storageService ?? StorageService.shared
        let profile = self.storageService.loadUserProfile()
        self.userProfile = profile

        // Load existing selections if any
        self.selectedMainGoal = profile.mainGoal
        self.selectedRestrictions = Set(profile.dietaryRestrictions)
        self.selectedSkillLevel = profile.cookingSkillLevel
        self.selectedMealPreferences = Set(profile.mealPreferences)
        self.selectedTimeAvailability = profile.timeAvailability
        self.selectedEquipment = Set(profile.cookingEquipment)
        self.selectedStruggles = Set(profile.cookingStruggles)
        self.selectedAdventureLevel = profile.adventureLevel
    }

    var canProceed: Bool {
        switch currentPage {
        case 0: return selectedMainGoal != nil              // Required
        case 1: return true                                  // Optional
        case 2: return selectedSkillLevel != nil            // Required
        case 3: return true                                  // Optional
        case 4: return selectedTimeAvailability != nil      // Required
        case 5: return true                                  // Optional
        case 6: return true                                  // Optional
        case 7: return selectedAdventureLevel != nil        // Required
        case 8: return true                                  // Summary - always can proceed
        default: return false
        }
    }

    var isLastQuestion: Bool {
        currentPage == questions.count - 1
    }

    var isSummaryPage: Bool {
        currentPage == 8
    }

    var progressPercentage: Double {
        Double(currentPage + 1) / Double(questions.count)
    }

    func nextPage() {
        guard currentPage < questions.count - 1 else { return }
        currentPage += 1
    }

    func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }

    func goToPage(_ page: Int) {
        guard page >= 0 && page < questions.count else { return }
        currentPage = page
    }

    func skip() {
        // Skip to summary page
        currentPage = questions.count - 1
    }

    func completeOnboarding() {
        // Update user profile with all selections
        userProfile.mainGoal = selectedMainGoal
        userProfile.dietaryRestrictions = Array(selectedRestrictions)
        userProfile.cookingSkillLevel = selectedSkillLevel
        userProfile.mealPreferences = Array(selectedMealPreferences)
        userProfile.timeAvailability = selectedTimeAvailability
        userProfile.cookingEquipment = Array(selectedEquipment)
        userProfile.cookingStruggles = Array(selectedStruggles)
        userProfile.adventureLevel = selectedAdventureLevel
        userProfile.updatedAt = Date()

        // Save to storage
        storageService.saveUserProfile(userProfile)
        storageService.setOnboardingComplete(true)
    }

    // MARK: - Summary Helpers

    var summaryItems: [(title: String, value: String, page: Int)] {
        var items: [(String, String, Int)] = []

        if let goal = selectedMainGoal {
            items.append(("Goal", goal.rawValue, 0))
        }

        if !selectedRestrictions.isEmpty {
            let restrictions = selectedRestrictions
                .filter { $0 != .none }
                .map { $0.rawValue }
                .joined(separator: ", ")
            if !restrictions.isEmpty {
                items.append(("Dietary", restrictions, 1))
            }
        }

        if let skill = selectedSkillLevel {
            items.append(("Skill Level", skill.rawValue, 2))
        }

        if !selectedMealPreferences.isEmpty {
            let prefs = selectedMealPreferences.map { $0.rawValue }.joined(separator: ", ")
            items.append(("Meal Types", prefs, 3))
        }

        if let time = selectedTimeAvailability {
            items.append(("Cook Time", time.rawValue, 4))
        }

        if !selectedEquipment.isEmpty {
            let equip = selectedEquipment.map { $0.rawValue }.joined(separator: ", ")
            items.append(("Equipment", equip, 5))
        }

        if !selectedStruggles.isEmpty {
            let struggles = selectedStruggles.map { $0.rawValue }.joined(separator: ", ")
            items.append(("Struggles", struggles, 6))
        }

        if let adventure = selectedAdventureLevel {
            items.append(("Adventure", adventure.rawValue, 7))
        }

        return items
    }
}
