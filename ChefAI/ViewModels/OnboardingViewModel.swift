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

    // MARK: - New Personal Info Questions
    @Published var userName: String = ""
    @Published var selectedGender: Gender?
    @Published var userAge: Int = 25
    @Published var birthDate: Date = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()

    /// Computed age from birthDate
    var calculatedAge: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 25
    }
    @Published var userWeight: Double = 150.0
    @Published var userHeight: Double = 68.0  // inches
    @Published var weightUnit: WeightUnit = .lbs
    @Published var heightUnit: HeightUnit = .inches
    @Published var useMetricSystem: Bool = false  // Toggle for Imperial/Metric
    @Published var selectedPhysiqueGoal: PhysiqueGoal?

    // MARK: - Organic vs Processed Questions
    @Published var eatsOrganic: Bool? = nil  // true = organic, false = processed, nil = mix
    @Published var selectedProcessedImpacts: Set<ProcessedFoodImpact> = []
    @Published var hasTriedDietChange: Bool?
    @Published var selectedDietBarriers: Set<DietBarrier> = []
    @Published var selectedOrganicGoals: Set<OrganicGoal> = []
    @Published var selectedAspirationalGoals: Set<AspirationalGoal> = []

    // MARK: - Cooking Habits
    @Published var cookingDaysPerWeek: Int = 3
    @Published var selectedCookingFrequency: CookingFrequency?
    @Published var selectedCookingTimes: Set<CookingTimeOfDay> = []

    // MARK: - Motivation & Acquisition
    @Published var selectedMotivations: Set<CookingMotivation> = []
    @Published var selectedAcquisitionSource: AcquisitionSource?

    // MARK: - Existing Questions
    @Published var selectedMainGoal: MainGoal?
    @Published var selectedRestrictions: Set<ExtendedDietaryRestriction> = []
    @Published var selectedSkillLevel: SkillLevel?
    @Published var selectedMealPreferences: Set<MealPreference> = []
    @Published var selectedTimeAvailability: TimeAvailability?
    @Published var selectedEquipment: Set<CookingEquipment> = []
    @Published var selectedStruggles: Set<CookingStruggle> = []
    @Published var selectedAdventureLevel: AdventureLevel?

    // MARK: - Response Screens State
    @Published var showingResponse: Bool = false
    @Published var currentResponse: OnboardingResponse?

    private let storageService: StorageService

    // MARK: - Questions Definition
    // Question IDs:
    // 0: Name
    // 1: Gender
    // 2: Age
    // 3: Weight & Height
    // 4: Physique Goal (OPTIONAL)
    // 5: Organic vs Processed
    // 6: Processed Food Impact (conditional - if processed)
    // 7: Have you tried changing diet? (conditional - if processed)
    // 8: Diet Barriers (conditional - if tried changing)
    // 9: Organic Goals (conditional - if organic)
    // 10: Aspirational Goals
    // 11: Main Goal
    // 12: Cooking Motivation
    // 13: Days Per Week Cooking
    // 14: Cooking Frequency & Skill (combined with skill level)
    // 15: Time of Day Cooking
    // 16: Dietary Restrictions
    // 17: Meal Preferences
    // 18: Time Availability
    // 19: Cooking Equipment
    // 20: Cooking Struggles
    // 21: Adventure Level
    // 22: How did you hear about us?
    // 23: Summary

    let questions: [OnboardingQuestion] = [
        // Part 1: Personal Info
        OnboardingQuestion(
            id: 0,
            title: "What's your name?",
            subtitle: "Let's personalize your experience",
            type: .textInput(placeholder: "Enter your name")
        ),
        OnboardingQuestion(
            id: 1,
            title: "What gender are you?",
            subtitle: "This helps us personalize nutrition recommendations",
            type: .singleChoice(Gender.allCases.map { $0.rawValue }),
            isOptional: true
        ),
        OnboardingQuestion(
            id: 2,
            title: "When were you born?",
            subtitle: "This will be used to calibrate your custom plan.",
            type: .agePicker
        ),
        OnboardingQuestion(
            id: 3,
            title: "Height & weight",
            subtitle: "This will be used to calibrate your custom plan.",
            type: .weightHeightPicker
        ),
        OnboardingQuestion(
            id: 4,
            title: "What's your goal with your physique?",
            subtitle: "This is optional - skip if you prefer",
            type: .singleChoice(PhysiqueGoal.allCases.map { $0.rawValue }),
            isOptional: true
        ),
        OnboardingQuestion(
            id: 5,
            title: "Do you eat organic or processed food?",
            subtitle: "Be honest, no shame! This helps us understand where you're starting from",
            type: .organicOrProcessed
        ),

        // Part 2: Conditional - Processed Food Path
        OnboardingQuestion(
            id: 6,
            title: "How has eating processed food affected your life?",
            subtitle: "Select all that apply",
            type: .multipleChoice(ProcessedFoodImpact.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 7,
            title: "Have you tried changing your diet before?",
            subtitle: "Understanding your journey helps us support you better",
            type: .singleChoice(["Yes", "No"])
        ),
        OnboardingQuestion(
            id: 8,
            title: "What stopped you from sticking with it?",
            subtitle: "Select all that apply - we'll help address these",
            type: .multipleChoice(DietBarrier.allCases.map { $0.rawValue })
        ),

        // Part 2: Conditional - Organic Food Path
        OnboardingQuestion(
            id: 9,
            title: "What are your long-term goals with cooking organically?",
            subtitle: "Select all that apply",
            type: .multipleChoice(OrganicGoal.allCases.map { $0.rawValue })
        ),

        // Part 3: Shared Flow
        OnboardingQuestion(
            id: 10,
            title: "How should eating healthier affect your life?",
            subtitle: "Select all that you hope to achieve",
            type: .multipleChoice(AspirationalGoal.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 11,
            title: "What's your main goal?",
            subtitle: "This helps us suggest recipes that support your lifestyle",
            type: .singleChoice(MainGoal.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 12,
            title: "Why do you want to cook?",
            subtitle: "Select all that motivate you",
            type: .multipleChoice(CookingMotivation.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 13,
            title: "How many days a week do you cook?",
            subtitle: "Drag to select",
            type: .daysPerWeek
        ),
        OnboardingQuestion(
            id: 14,
            title: "How experienced are you in the kitchen?",
            subtitle: "We'll match recipe difficulty to your skill level",
            type: .singleChoice(SkillLevel.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 15,
            title: "What time of day do you usually cook?",
            subtitle: "Select all that apply",
            type: .multipleChoice(CookingTimeOfDay.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 16,
            title: "Any dietary restrictions or allergies?",
            subtitle: "Select all that apply",
            type: .multipleChoice(ExtendedDietaryRestriction.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 17,
            title: "What types of meals do you like?",
            subtitle: "Select all that appeal to you",
            type: .multipleChoice(MealPreference.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 18,
            title: "How much time do you want to spend cooking?",
            subtitle: "We'll filter recipes to fit your schedule",
            type: .singleChoice(TimeAvailability.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 19,
            title: "What cooking equipment do you have?",
            subtitle: "Select all the tools available in your kitchen",
            type: .multipleChoice(CookingEquipment.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 20,
            title: "What do you struggle with most?",
            subtitle: "We'll help address these challenges",
            type: .multipleChoice(CookingStruggle.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 21,
            title: "How adventurous are you with food?",
            subtitle: "This affects how creative our suggestions get",
            type: .singleChoice(AdventureLevel.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 22,
            title: "How did you hear about us?",
            subtitle: "Help us understand how you found Chef AI",
            type: .singleChoice(AcquisitionSource.allCases.map { $0.rawValue })
        ),
        OnboardingQuestion(
            id: 23,
            title: "You're all set!",
            subtitle: "Here's a summary of your preferences",
            type: .custom
        )
    ]

    // MARK: - Visible Questions (handles conditional logic)

    var visibleQuestionIndices: [Int] {
        var indices: [Int] = []

        // Questions 0-5 always visible (Name, Gender, Age, Weight/Height, Physique Goal, Organic/Processed)
        indices.append(contentsOf: [0, 1, 2, 3, 4, 5])

        // Conditional questions based on organic vs processed choice
        if eatsOrganic == false {
            // Processed food path: 6, 7, and conditionally 8
            indices.append(6)  // Processed food impact
            indices.append(7)  // Have you tried changing diet?
            if hasTriedDietChange == true {
                indices.append(8)  // Diet barriers
            }
        } else if eatsOrganic == true {
            // Organic food path: 9
            indices.append(9)  // Organic goals
        }
        // If eatsOrganic == nil (mix), skip both conditional paths

        // Questions 10-23 always visible
        indices.append(contentsOf: [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23])

        return indices
    }

    var currentQuestionIndex: Int {
        visibleQuestionIndices[currentPage]
    }

    var currentQuestion: OnboardingQuestion {
        questions[currentQuestionIndex]
    }

    var totalVisibleQuestions: Int {
        visibleQuestionIndices.count
    }

    init(storageService: StorageService? = nil) {
        self.storageService = storageService ?? StorageService.shared
        let profile = self.storageService.loadUserProfile()
        self.userProfile = profile

        // Load existing selections if any
        loadExistingSelections(from: profile)
    }

    private func loadExistingSelections(from profile: UserProfile) {
        // Personal info
        self.userName = profile.userName ?? ""
        self.selectedGender = profile.userGender
        self.userAge = profile.userAge ?? 25
        self.userWeight = profile.userWeight ?? 150.0
        self.userHeight = profile.userHeight ?? 68.0
        self.weightUnit = profile.weightUnit ?? .lbs
        self.heightUnit = profile.heightUnit ?? .inches
        self.selectedPhysiqueGoal = profile.physiqueGoal

        // Organic/processed
        self.eatsOrganic = profile.eatsOrganic
        self.selectedProcessedImpacts = Set(profile.processedFoodImpact ?? [])
        self.hasTriedDietChange = profile.hasTriedDietChange
        self.selectedDietBarriers = Set(profile.dietChangeBarriers ?? [])
        self.selectedOrganicGoals = Set(profile.organicCookingGoals ?? [])
        self.selectedAspirationalGoals = Set(profile.aspirationalGoals ?? [])

        // Cooking habits
        self.cookingDaysPerWeek = profile.cookingDaysPerWeek ?? 3
        self.selectedCookingFrequency = profile.cookingFrequency
        self.selectedCookingTimes = Set(profile.cookingTimesOfDay ?? [])

        // Motivation
        self.selectedMotivations = Set(profile.motivationToCook ?? [])
        self.selectedAcquisitionSource = profile.acquisitionSource

        // Existing
        self.selectedMainGoal = profile.mainGoal
        self.selectedRestrictions = Set(profile.dietaryRestrictions)
        self.selectedSkillLevel = profile.cookingSkillLevel
        self.selectedMealPreferences = Set(profile.mealPreferences)
        self.selectedTimeAvailability = profile.timeAvailability
        self.selectedEquipment = Set(profile.cookingEquipment)
        self.selectedStruggles = Set(profile.cookingStruggles)
        self.selectedAdventureLevel = profile.adventureLevel
    }

    // MARK: - Validation

    var canProceed: Bool {
        let questionId = currentQuestionIndex

        switch questionId {
        case 0: return !userName.trimmingCharacters(in: .whitespaces).isEmpty  // Name required
        case 1: return true  // Gender optional
        case 2: return true  // Age has defaults
        case 3: return true  // Weight/Height has defaults
        case 4: return true  // Physique goal optional
        case 5: return eatsOrganic != nil  // Must choose organic/processed/mix
        case 6: return true  // Processed impact optional
        case 7: return hasTriedDietChange != nil  // Must answer yes/no
        case 8: return true  // Barriers optional
        case 9: return true  // Organic goals optional
        case 10: return true  // Aspirational goals optional
        case 11: return selectedMainGoal != nil  // Required
        case 12: return true  // Motivation optional
        case 13: return true  // Days per week has default
        case 14: return selectedSkillLevel != nil  // Required
        case 15: return true  // Time of day optional
        case 16: return true  // Dietary restrictions optional
        case 17: return true  // Meal preferences optional
        case 18: return selectedTimeAvailability != nil  // Required
        case 19: return true  // Equipment optional
        case 20: return true  // Struggles optional
        case 21: return selectedAdventureLevel != nil  // Required
        case 22: return true  // Acquisition source optional
        case 23: return true  // Summary - always can proceed
        default: return false
        }
    }

    var isLastQuestion: Bool {
        currentPage == totalVisibleQuestions - 1
    }

    var isSummaryPage: Bool {
        currentQuestionIndex == 23
    }

    var progressPercentage: Double {
        Double(currentPage + 1) / Double(totalVisibleQuestions)
    }

    // MARK: - Navigation

    func nextPage() {
        guard currentPage < totalVisibleQuestions - 1 else { return }
        currentPage += 1
    }

    func previousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
    }

    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalVisibleQuestions else { return }
        currentPage = page
    }

    func skip() {
        // Skip to summary page
        currentPage = totalVisibleQuestions - 1
    }

    // MARK: - Response Screens

    /// Check if the current question should trigger a response screen
    func shouldShowResponseAfterCurrentQuestion() -> Bool {
        return OnboardingResponse.shouldShowResponse(afterQuestionId: currentQuestionIndex)
    }

    /// Get the response to show after the current question (if any)
    func getResponseForCurrentQuestion() -> OnboardingResponse? {
        return OnboardingResponse.getResponse(forQuestionId: currentQuestionIndex)
    }

    /// Called when user taps continue - checks if response should be shown
    func proceedFromCurrentQuestion() {
        if shouldShowResponseAfterCurrentQuestion() {
            currentResponse = getResponseForCurrentQuestion()
            showingResponse = true
        } else {
            nextPage()
        }
    }

    /// Called when user dismisses a response screen
    func dismissResponse() {
        showingResponse = false
        currentResponse = nil
        nextPage()
    }

    // MARK: - Save Profile

    func completeOnboarding() {
        // Update user profile with all selections

        // Personal info
        userProfile.userName = userName.isEmpty ? nil : userName
        userProfile.userGender = selectedGender
        userProfile.userAge = calculatedAge
        userProfile.userWeight = userWeight
        userProfile.userHeight = userHeight
        userProfile.weightUnit = weightUnit
        userProfile.heightUnit = heightUnit
        userProfile.physiqueGoal = selectedPhysiqueGoal

        // Organic/processed
        userProfile.eatsOrganic = eatsOrganic
        userProfile.processedFoodImpact = Array(selectedProcessedImpacts)
        userProfile.hasTriedDietChange = hasTriedDietChange
        userProfile.dietChangeBarriers = Array(selectedDietBarriers)
        userProfile.organicCookingGoals = Array(selectedOrganicGoals)
        userProfile.aspirationalGoals = Array(selectedAspirationalGoals)

        // Cooking habits
        userProfile.cookingDaysPerWeek = cookingDaysPerWeek
        userProfile.cookingFrequency = selectedCookingFrequency
        userProfile.cookingTimesOfDay = Array(selectedCookingTimes)

        // Motivation
        userProfile.motivationToCook = Array(selectedMotivations)
        userProfile.acquisitionSource = selectedAcquisitionSource

        // Existing preferences
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

        if !userName.isEmpty {
            items.append(("Name", userName, 0))
        }

        if let gender = selectedGender {
            items.append(("Gender", gender.rawValue, 1))
        }

        items.append(("Age", "\(calculatedAge) years", 2))
        items.append(("Weight", String(format: "%.0f %@", userWeight, weightUnit.rawValue), 3))
        items.append(("Height", formatHeight(), 3))

        if let physique = selectedPhysiqueGoal, physique != .preferNotToSay {
            items.append(("Physique Goal", physique.rawValue, 4))
        }

        if let organic = eatsOrganic {
            items.append(("Diet Type", organic ? "Mostly organic" : "Mostly processed", 5))
        }

        if let goal = selectedMainGoal {
            // Find the page index for main goal
            if let pageIndex = visibleQuestionIndices.firstIndex(of: 11) {
                items.append(("Main Goal", goal.rawValue, pageIndex))
            }
        }

        if let skill = selectedSkillLevel {
            if let pageIndex = visibleQuestionIndices.firstIndex(of: 14) {
                items.append(("Skill Level", skill.rawValue, pageIndex))
            }
        }

        if let time = selectedTimeAvailability {
            if let pageIndex = visibleQuestionIndices.firstIndex(of: 18) {
                items.append(("Cook Time", time.rawValue, pageIndex))
            }
        }

        if let adventure = selectedAdventureLevel {
            if let pageIndex = visibleQuestionIndices.firstIndex(of: 20) {
                items.append(("Adventure", adventure.rawValue, pageIndex))
            }
        }

        if !selectedRestrictions.isEmpty {
            let restrictions = selectedRestrictions
                .filter { $0 != .none }
                .map { $0.rawValue }
                .joined(separator: ", ")
            if !restrictions.isEmpty {
                if let pageIndex = visibleQuestionIndices.firstIndex(of: 15) {
                    items.append(("Dietary", restrictions, pageIndex))
                }
            }
        }

        return items
    }

    private func formatHeight() -> String {
        if heightUnit == .inches {
            let feet = Int(userHeight) / 12
            let inches = Int(userHeight) % 12
            return "\(feet)'\(inches)\""
        } else {
            return String(format: "%.0f cm", userHeight)
        }
    }
}
