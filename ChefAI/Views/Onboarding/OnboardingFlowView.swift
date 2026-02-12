//
//  OnboardingFlowView.swift
//  ChefAI
//
//  Master view that coordinates the entire onboarding flow:
//  Splash -> Welcome -> Onboarding Questions -> Completion -> Home
//

import SwiftUI
import Auth

enum OnboardingStep {
    case splash
    case welcome
    case questions
    case completion
}

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var supabase = SupabaseManager.shared
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @State private var currentStep: OnboardingStep = .splash
    @State private var showSplash = true
    @State private var showingAuthSheet = false

    var body: some View {
        ZStack {
            // White background for smooth transitions
            Color.white.ignoresSafeArea()

            switch currentStep {
            case .splash:
                SplashScreenView(isActive: $showSplash)
                    .transition(.opacity)
                    .onChange(of: showSplash) { _, newValue in
                        if !newValue {
                            withAnimation(.easeIn(duration: 0.4)) {
                                currentStep = .welcome
                            }
                        }
                    }

            case .welcome:
                WelcomeScreenView(
                    onGetStarted: {
                        showingAuthSheet = true
                    },
                    onSignIn: {
                        showingAuthSheet = true
                    }
                )
                .transition(.opacity)

            case .questions:
                OnboardingQuestionsView(
                    viewModel: viewModel,
                    onComplete: {
                        // Save onboarding data, then show completion screen
                        viewModel.completeOnboarding()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .completion
                        }
                    },
                    onBackToWelcome: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .welcome
                        }
                    }
                )
                .transition(.opacity)

            case .completion:
                OnboardingCompletionView(
                    userName: viewModel.userName,
                    onStartCooking: {
                        finishOnboarding()
                    }
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthenticationView(onSuccess: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .questions
                }
            })
        }
    }

    // MARK: - Finish Onboarding

    private func finishOnboarding() {
        // Save per-user onboarding flag so re-login skips onboarding
        if let userId = supabase.currentUser?.id.uuidString {
            StorageService.shared.setOnboardingComplete(true, for: userId)
        }
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Questions View (inner content)

struct OnboardingQuestionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onComplete: () -> Void
    var onBackToWelcome: () -> Void

    // Check if we're on pages with special layout (name=0, gender=1, birthday=2, height=3, weight=4, desired weight=5)
    private var isSpecialLayoutPage: Bool {
        let idx = viewModel.currentQuestionIndex
        return idx >= 0 && idx <= 5
    }

    // Pages that show back + next buttons (special layout pages)
    private var showsBackNextButtons: Bool {
        isSpecialLayoutPage
    }

    var body: some View {
        ZStack {
            // White background
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    // Empty spacer to maintain layout
                    Spacer()
                        .frame(width: 44, height: 44)

                    Spacer()

                    // Skip button (hidden on last page and special layout pages)
                    Button {
                        withAnimation {
                            viewModel.skip()
                        }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .opacity((viewModel.isLastQuestion || isSpecialLayoutPage) ? 0 : 1)
                    .disabled(viewModel.isLastQuestion || isSpecialLayoutPage)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black)
                            .frame(
                                width: geometry.size.width * CGFloat(viewModel.currentPage + 1) / CGFloat(viewModel.totalVisibleQuestions),
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)

                // Question content
                OnboardingQuestionView(
                    question: viewModel.currentQuestion,
                    viewModel: viewModel
                )
                .id(viewModel.currentQuestionIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)

                // Bottom buttons
                if showsBackNextButtons {
                    // Special pages: back arrow + "Next" button
                    HStack(spacing: 12) {
                        Button {
                            if viewModel.currentPage == 0 {
                                onBackToWelcome()
                            } else {
                                withAnimation {
                                    viewModel.previousPage()
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(Color(white: 0.93))
                                .clipShape(Circle())
                        }

                        Button(action: {
                            viewModel.proceedFromCurrentQuestion()
                        }) {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.canProceed ? Color.black : Color.gray.opacity(0.3))
                            .cornerRadius(28)
                        }
                        .disabled(!viewModel.canProceed)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    // Other pages: back arrow + Continue button
                    HStack(spacing: 12) {
                        Button {
                            if viewModel.currentPage == 0 {
                                onBackToWelcome()
                            } else {
                                withAnimation {
                                    viewModel.previousPage()
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(Color(white: 0.93))
                                .clipShape(Circle())
                        }

                        Button(action: {
                            if viewModel.isLastQuestion {
                                onComplete()
                            } else {
                                viewModel.proceedFromCurrentQuestion()
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(viewModel.canProceed ? Color.black : Color.gray.opacity(0.3))
                                .cornerRadius(28)
                        }
                        .disabled(!viewModel.canProceed)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        // Response screen overlay
        .fullScreenCover(isPresented: $viewModel.showingResponse) {
            if let response = viewModel.currentResponse {
                OnboardingResponseView(
                    response: response,
                    onContinue: {
                        viewModel.dismissResponse()
                    }
                )
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
}
