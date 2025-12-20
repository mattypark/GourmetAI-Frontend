//
//  OnboardingQuestionView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title and subtitle (except for summary page)
            if question.id != 8 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
                    .frame(height: 24)
            }

            // Question content based on type
            switch question.id {
            case 0:
                // Question 1: Main Goal (Single choice - only 3 primary options)
                ScrollView {
                    MultipleChoiceSelector(
                        items: MainGoal.primaryOptions,
                        selected: $viewModel.selectedMainGoal,
                        iconProvider: { $0.icon }
                    )
                }

            case 1:
                // Question 2: Dietary Restrictions (Multi-select)
                ScrollView {
                    TagPicker(
                        items: ExtendedDietaryRestriction.allCases,
                        selectedItems: $viewModel.selectedRestrictions,
                        iconProvider: { $0.icon }
                    )
                }

            case 2:
                // Question 3: Skill Level (Single choice)
                ScrollView {
                    MultipleChoiceSelector(
                        items: SkillLevel.allCases,
                        selected: $viewModel.selectedSkillLevel,
                        iconProvider: { $0.icon }
                    )
                }

            case 3:
                // Question 4: Meal Preferences (Multi-select)
                ScrollView {
                    TagPicker(
                        items: MealPreference.allCases,
                        selectedItems: $viewModel.selectedMealPreferences,
                        iconProvider: { $0.icon }
                    )
                }

            case 4:
                // Question 5: Time Availability (Single choice)
                ScrollView {
                    MultipleChoiceSelector(
                        items: TimeAvailability.allCases,
                        selected: $viewModel.selectedTimeAvailability,
                        iconProvider: { $0.icon }
                    )
                }

            case 5:
                // Question 6: Cooking Equipment (Multi-select)
                ScrollView {
                    TagPicker(
                        items: CookingEquipment.allCases,
                        selectedItems: $viewModel.selectedEquipment,
                        iconProvider: { $0.icon }
                    )
                }

            case 6:
                // Question 7: Cooking Struggles (Multi-select)
                ScrollView {
                    TagPicker(
                        items: CookingStruggle.allCases,
                        selectedItems: $viewModel.selectedStruggles,
                        iconProvider: { $0.icon }
                    )
                }

            case 7:
                // Question 8: Adventure Level (Single choice)
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(AdventureLevel.allCases, id: \.self) { level in
                            AdventureLevelCard(
                                level: level,
                                isSelected: viewModel.selectedAdventureLevel == level,
                                onTap: {
                                    viewModel.selectedAdventureLevel = level
                                }
                            )
                        }
                    }
                }

            case 8:
                // Question 9: Summary
                OnboardingSummaryView(viewModel: viewModel)

            default:
                EmptyView()
            }

            if question.id != 8 {
                Spacer()
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Adventure Level Card

struct AdventureLevelCard: View {
    let level: AdventureLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .black)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.black : Color.black.opacity(0.05))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @StateObject var viewModel = OnboardingViewModel()

    ZStack {
        Color.white.ignoresSafeArea()
        OnboardingQuestionView(
            question: viewModel.questions[0],
            viewModel: viewModel
        )
    }
}
