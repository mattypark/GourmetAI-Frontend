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

    // MARK: - Section 1: Personal Info (Q0-Q6)
    @Published var userName: String = ""
    @Published var selectedGender: Gender?
    @Published var birthDate: Date = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
    @Published var userHeight: Double = 68.0  // inches
    @Published var userWeight: Double = 150.0
    @Published var desiredWeight: Double = 143.0
    @Published var weightUnit: WeightUnit = .lbs
    @Published var heightUnit: HeightUnit = .inches
    @Published var useMetricSystem: Bool = false
    @Published var selectedActivityLevel: ActivityLevel?

    // MARK: - Section 2: Cooking Habits (Q7-Q11)
    @Published var cookingDaysPerWeek: Int = 3
    @Published var selectedStruggles: Set<CookingStruggle> = []
    @Published var selectedTimeAvailability: TimeAvailability?
    @Published var selectedRestrictions: Set<ExtendedDietaryRestriction> = []
    @Published var selectedAdventureLevel: AdventureLevel?

    // MARK: - Section 3: Motivation & Mindset (Q12-Q14)
    @Published var hasTriedDietChange: Bool?
    @Published var selectedDietBarriers: Set<DietBarrier> = []
    @Published var selectedHealthGoals: Set<HealthImprovementGoal> = []

    // MARK: - Section 4: Commitment (Q15)
    @Published var selectedCommitmentPriority: CommitmentPriority?

    // MARK: - Response Screens State
    @Published var showingResponse: Bool = false
    @Published var currentResponse: OnboardingResponse?

    /// Computed age from birthDate
    var calculatedAge: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 25
    }

    private let storageService: StorageService

    // MARK: - Questions Definition
    // New flow: 16 questions (Q0-Q15)
    //
    // Section 1 - Personal Info:
    //   0: Name, 1: Gender, 2: Birthday, 3: Height, 4: Weight, 5: Desired Weight, 6: Activity Level
    //
    // Section 2 - Cooking Habits:
    //   7: Days per week, 8: Biggest struggle, 9: Time available, 10: Dietary restrictions, 11: Adventure level
    //
    // Section 3 - Motivation:
    //   12: Tried dieting before?, 13: What stopped you? (conditional), 14: How would healthier eating help?
    //
    // Section 4 - Commitment:
    //   15: What matters most?

    let questions: [OnboardingQuestion] = [
        // Section 1: Personal Info
        OnboardingQuestion(id: 0, title: "What's your name?", subtitle: "Let's personalize your experience", type: .textInput(placeholder: "Enter your name")),
        OnboardingQuestion(id: 1, title: "What gender are you?", subtitle: "This helps us personalize nutrition recommendations", type: .singleChoice(Gender.allCases.map { $0.rawValue }), isOptional: true),
        OnboardingQuestion(id: 2, title: "When were you born?", subtitle: "This will be used to calibrate your custom plan.", type: .agePicker),
        OnboardingQuestion(id: 3, title: "What's your height?", subtitle: nil, type: .heightPicker),
        OnboardingQuestion(id: 4, title: "What's your weight?", subtitle: nil, type: .weightPicker),
        OnboardingQuestion(id: 5, title: "What's your desired weight?", subtitle: "We'll help you get there", type: .weightPicker),
        OnboardingQuestion(id: 6, title: "What's your activity level?", subtitle: "Be honest! This affects your calorie needs", type: .activityLevel),

        // Section 2: Cooking Habits
        OnboardingQuestion(id: 7, title: "How often do you cook per week?", subtitle: "Drag to select", type: .daysPerWeek),
        OnboardingQuestion(id: 8, title: "What's your biggest struggle with eating healthy?", subtitle: "Select all that apply", type: .multipleChoice(CookingStruggle.allCases.map { $0.rawValue })),
        OnboardingQuestion(id: 9, title: "How much time can you spend cooking?", subtitle: "We'll filter recipes to fit your schedule", type: .singleChoice(TimeAvailability.allCases.map { $0.rawValue })),
        OnboardingQuestion(id: 10, title: "Dietary restrictions?", subtitle: "Select all that apply", type: .multipleChoice(ExtendedDietaryRestriction.allCases.map { $0.rawValue })),
        OnboardingQuestion(id: 11, title: "How adventurous are you with food?", subtitle: "This affects how creative our suggestions get", type: .singleChoice(AdventureLevel.allCases.map { $0.rawValue })),

        // Section 3: Motivation & Mindset
        OnboardingQuestion(id: 12, title: "Have you tried dieting before?", subtitle: "Understanding your journey helps us support you better", type: .singleChoice(["Yes", "No"])),
        OnboardingQuestion(id: 13, title: "What stopped you last time?", subtitle: "Select all that apply — we'll help address these", type: .multipleChoice(DietBarrier.allCases.map { $0.rawValue })),
        OnboardingQuestion(id: 14, title: "How would eating healthier improve your life?", subtitle: "Select all that you hope to achieve", type: .multipleChoice(HealthImprovementGoal.allCases.map { $0.rawValue })),

        // Section 4: Commitment
        OnboardingQuestion(id: 15, title: "What matters most to you right now?", subtitle: "This helps us personalize your experience", type: .singleChoice(CommitmentPriority.allCases.map { $0.rawValue }))
    ]

    // MARK: - Visible Questions (handles conditional logic)

    var visibleQuestionIndices: [Int] {
        var indices: [Int] = []

        // Q0-Q12 always visible
        indices.append(contentsOf: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])

        // Q13 only if Q12 = Yes
        if hasTriedDietChange == true {
            indices.append(13)
        }

        // Q14-Q15 always visible
        indices.append(contentsOf: [14, 15])

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
        loadExistingSelections(from: profile)
    }

    private func loadExistingSelections(from profile: UserProfile) {
        self.userName = profile.userName ?? ""
        self.selectedGender = profile.userGender
        self.userWeight = profile.userWeight ?? 150.0
        self.desiredWeight = profile.desiredWeight ?? 143.0
        self.userHeight = profile.userHeight ?? 68.0
        self.weightUnit = profile.weightUnit ?? .lbs
        self.heightUnit = profile.heightUnit ?? .inches
        self.selectedActivityLevel = profile.activityLevel
        self.cookingDaysPerWeek = profile.cookingDaysPerWeek ?? 3
        self.selectedStruggles = Set(profile.eatingStruggles ?? [])
        self.selectedTimeAvailability = profile.timeAvailability
        self.selectedRestrictions = Set(profile.dietaryRestrictions)
        self.selectedAdventureLevel = profile.adventureLevel
        self.hasTriedDietChange = profile.hasTriedDietChange
        self.selectedDietBarriers = Set(profile.dietChangeBarriers ?? [])
        self.selectedHealthGoals = Set(profile.healthImprovementGoals ?? [])
        self.selectedCommitmentPriority = profile.commitmentPriority
    }

    // MARK: - Validation

    var canProceed: Bool {
        let questionId = currentQuestionIndex

        switch questionId {
        case 0: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return true  // Gender optional
        case 2: return true  // Age has defaults
        case 3: return true  // Height has defaults
        case 4: return true  // Weight has defaults
        case 5: return true  // Desired weight has defaults
        case 6: return selectedActivityLevel != nil
        case 7: return true  // Days per week has default
        case 8: return true  // Struggles optional
        case 9: return selectedTimeAvailability != nil
        case 10: return true  // Dietary restrictions optional
        case 11: return selectedAdventureLevel != nil
        case 12: return hasTriedDietChange != nil
        case 13: return true  // Barriers optional
        case 14: return true  // Health goals optional
        case 15: return selectedCommitmentPriority != nil
        default: return false
        }
    }

    var isLastQuestion: Bool {
        currentPage == totalVisibleQuestions - 1
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

    func skip() {
        // Skip to last question
        currentPage = totalVisibleQuestions - 1
    }

    // MARK: - Response Screens

    func shouldShowResponseAfterCurrentQuestion() -> Bool {
        return OnboardingResponse.shouldShowResponse(afterQuestionId: currentQuestionIndex)
    }

    func getResponseForCurrentQuestion() -> OnboardingResponse? {
        return OnboardingResponse.getResponse(forQuestionId: currentQuestionIndex)
    }

    func proceedFromCurrentQuestion() {
        if shouldShowResponseAfterCurrentQuestion() {
            currentResponse = getResponseForCurrentQuestion()
            showingResponse = true
        } else {
            nextPage()
        }
    }

    func dismissResponse() {
        showingResponse = false
        currentResponse = nil
        nextPage()
    }

    // MARK: - Save Profile

    func completeOnboarding() {
        userProfile.userName = userName.isEmpty ? nil : userName
        userProfile.userGender = selectedGender
        userProfile.userAge = calculatedAge
        userProfile.userWeight = userWeight
        userProfile.desiredWeight = desiredWeight
        userProfile.userHeight = userHeight
        userProfile.weightUnit = weightUnit
        userProfile.heightUnit = heightUnit
        userProfile.activityLevel = selectedActivityLevel
        userProfile.cookingDaysPerWeek = cookingDaysPerWeek
        userProfile.eatingStruggles = Array(selectedStruggles)
        userProfile.timeAvailability = selectedTimeAvailability
        userProfile.dietaryRestrictions = Array(selectedRestrictions)
        userProfile.adventureLevel = selectedAdventureLevel
        userProfile.hasTriedDietChange = hasTriedDietChange
        userProfile.dietChangeBarriers = Array(selectedDietBarriers)
        userProfile.healthImprovementGoals = Array(selectedHealthGoals)
        userProfile.commitmentPriority = selectedCommitmentPriority
        userProfile.updatedAt = Date()

        // Also save to SettingsViewModel's userName for the home screen
        UserDefaults.standard.set(userName, forKey: "settings.userName")

        storageService.saveUserProfile(userProfile)
    }

    // MARK: - Helpers

    func formatHeight() -> String {
        if heightUnit == .inches {
            let feet = Int(userHeight) / 12
            let inches = Int(userHeight) % 12
            return "\(feet)'\(inches)\""
        } else {
            return String(format: "%.0f cm", userHeight)
        }
    }
}
