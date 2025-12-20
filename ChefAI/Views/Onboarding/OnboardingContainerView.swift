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
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button and progress
                HStack {
                    // Back button (hidden on first page)
                    Button {
                        withAnimation {
                            viewModel.previousPage()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                    }
                    .opacity(viewModel.currentPage > 0 ? 1 : 0)
                    .disabled(viewModel.currentPage == 0)

                    Spacer()

                    // Page indicator text
                    Text("\(viewModel.currentPage + 1) of \(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    // Skip button (hidden on last page)
                    Button {
                        withAnimation {
                            viewModel.skip()
                        }
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .opacity(viewModel.isLastQuestion ? 0 : 1)
                    .disabled(viewModel.isLastQuestion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Progress indicator
                OnboardingProgressIndicator(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.questions.count
                )
                .padding(.top, 8)
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
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)

                // Bottom buttons
                VStack(spacing: 12) {
                    // Main action button
                    PrimaryButton(
                        title: buttonTitle,
                        action: {
                            if viewModel.isLastQuestion {
                                viewModel.completeOnboarding()
                                withAnimation {
                                    hasCompletedOnboarding = true
                                }
                            } else {
                                withAnimation {
                                    viewModel.nextPage()
                                }
                            }
                        }
                    )
                    .disabled(!viewModel.canProceed)
                    .opacity(viewModel.canProceed ? 1.0 : 0.5)

                    // Optional info text
                    if !viewModel.isLastQuestion && isOptionalQuestion {
                        Text("Optional - you can skip this")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private var buttonTitle: String {
        if viewModel.isLastQuestion {
            return "Finish Setup & Start Cooking"
        } else if viewModel.currentPage == viewModel.questions.count - 2 {
            return "Review Summary"
        } else {
            return "Continue"
        }
    }

    private var isOptionalQuestion: Bool {
        [1, 3, 5, 6].contains(viewModel.currentPage)
    }
}

#Preview {
    OnboardingContainerView()
}
