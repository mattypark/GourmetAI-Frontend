//
//  OnboardingContainerView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressIndicator(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.questions.count
                )
                .padding(.top, 60)
                .padding(.horizontal, 24)

                // Question content
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.questions.enumerated()), id: \.element.id) { index, question in
                        OnboardingQuestionView(
                            question: question,
                            viewModel: viewModel
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom buttons
                HStack {
                    if !viewModel.isLastQuestion {
                        SkipButton {
                            withAnimation {
                                viewModel.skip()
                            }
                        }
                    }

                    Spacer()

                    PrimaryButton(
                        title: viewModel.isLastQuestion ? "Get Started" : "Next",
                        action: {
                            if viewModel.isLastQuestion {
                                viewModel.completeOnboarding()
                                hasCompletedOnboarding = true
                            } else {
                                withAnimation {
                                    viewModel.nextPage()
                                }
                            }
                        }
                    )
                    .disabled(!viewModel.canProceed)
                    .opacity(viewModel.canProceed ? 1.0 : 0.5)
                    .frame(width: 200)
                }
                .padding(24)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
