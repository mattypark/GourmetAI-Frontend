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
            // Title and subtitle
            VStack(alignment: .leading, spacing: 8) {
                Text(question.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = question.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
                .frame(height: 24)

            // Question content based on type
            switch question.id {
            case 0:
                // Question 1: Main Goal (Single choice)
                MultipleChoiceSelector(
                    items: CookingGoal.allCases,
                    selected: $viewModel.selectedGoal,
                    iconProvider: { $0.icon }
                )

            case 1:
                // Question 2: Dietary Restrictions (Multi-select)
                TagPicker(
                    items: DietaryRestriction.allCases,
                    selectedItems: $viewModel.selectedRestrictions,
                    iconProvider: { $0.icon }
                )

            case 2:
                // Question 3: Skill Level (Single choice)
                MultipleChoiceSelector(
                    items: SkillLevel.allCases,
                    selected: $viewModel.selectedSkillLevel
                )

            case 3:
                // Question 4: Cooking Style (Single choice)
                MultipleChoiceSelector(
                    items: CookingStyle.allCases,
                    selected: $viewModel.selectedCookingStyle,
                    iconProvider: { $0.icon }
                )

            case 4:
                // Question 5: Cuisine Preferences (Multi-select)
                TagPicker(
                    items: CuisineType.allCases,
                    selectedItems: $viewModel.selectedCuisinePreferences,
                    iconProvider: { $0.icon }
                )

            default:
                EmptyView()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    @Previewable @StateObject var viewModel = OnboardingViewModel()

    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingQuestionView(
            question: viewModel.questions[0],
            viewModel: viewModel
        )
    }
}
