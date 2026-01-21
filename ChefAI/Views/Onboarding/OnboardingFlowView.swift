//
//  OnboardingFlowView.swift
//  ChefAI
//
//  Master view that coordinates the entire onboarding flow:
//  Splash -> Welcome -> Onboarding Questions -> Superwall Paywall
//

import SwiftUI
// TODO: Add SuperwallKit package in Xcode before uncommenting
// import SuperwallKit

enum OnboardingStep {
    case splash
    case welcome
    case questions
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
                        // Show auth sheet when Get Started is tapped
                        showingAuthSheet = true
                    },
                    onSignIn: {
                        // Show auth sheet when Sign In is tapped
                        showingAuthSheet = true
                    }
                )
                .transition(.opacity)

            case .questions:
                OnboardingQuestionsView(
                    viewModel: viewModel,
                    onComplete: {
                        // Show Superwall paywall when onboarding completes
                        showSuperwallPaywall()
                    },
                    onBackToWelcome: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .welcome
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthenticationView(onSuccess: {
                // After successful auth, proceed to onboarding questions
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .questions
                }
            })
        }
    }

    // MARK: - Superwall Integration

    private func showSuperwallPaywall() {
        // TODO: Uncomment after adding SuperwallKit package
        // Register the paywall event with Superwall
        // "onboarding_complete" is the event name you'll configure in Superwall dashboard
        // Superwall.shared.register(event: "onboarding_complete") {
        //     // This handler is called when user subscribes or paywall is dismissed
        //     handlePaywallResult()
        // }

        // Temporary: Skip paywall and complete onboarding directly
        handlePaywallResult()
    }

    private func handlePaywallResult() {
        viewModel.completeOnboarding()
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

    // Check if we're on pages with special layout (name=0, gender=1, birthday=2, height=3, weight=4)
    private var isSpecialLayoutPage: Bool {
        viewModel.currentQuestionIndex == 0 || viewModel.currentQuestionIndex == 1 || viewModel.currentQuestionIndex == 2 || viewModel.currentQuestionIndex == 3 || viewModel.currentQuestionIndex == 4
    }

    private var isNamePage: Bool {
        viewModel.currentQuestionIndex == 0
    }

    private var isGenderPage: Bool {
        viewModel.currentQuestionIndex == 1
    }

    private var isBirthdayPage: Bool {
        viewModel.currentQuestionIndex == 2
    }

    private var isHeightPage: Bool {
        viewModel.currentQuestionIndex == 3
    }

    private var isWeightPage: Bool {
        viewModel.currentQuestionIndex == 4
    }

    // Pages that show back + next buttons (name, gender, birthday, height, weight)
    private var showsBackNextButtons: Bool {
        viewModel.currentQuestionIndex == 0 || viewModel.currentQuestionIndex == 1 || viewModel.currentQuestionIndex == 2 || viewModel.currentQuestionIndex == 3 || viewModel.currentQuestionIndex == 4
    }

    var body: some View {
        ZStack {
            // White background
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header - no back button (back is always at bottom)
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

                // Progress bar - shown on all pages
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        // Progress bar - uses visible question count for proper progress
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

                // Question content - shows current question based on visible indices
                OnboardingQuestionView(
                    question: viewModel.currentQuestion,
                    viewModel: viewModel
                )
                .id(viewModel.currentQuestionIndex)  // Force view refresh when question changes
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPage)

                // Bottom buttons - different style for special layout pages
                if showsBackNextButtons {
                    // Special pages: back arrow + "Next →" button
                    HStack(spacing: 12) {
                        // Back button (circle) - goes to welcome on first page
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

                        // Next button
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
                        // Back button (circle)
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

                        // Continue button
                        Button(action: {
                            if viewModel.isLastQuestion {
                                onComplete()
                            } else {
                                viewModel.proceedFromCurrentQuestion()
                            }
                        }) {
                            Text(buttonTitle)
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

    private var buttonTitle: String {
        if viewModel.isLastQuestion {
            return "Continue"
        } else {
            return "Continue"
        }
    }
}

#Preview {
    OnboardingFlowView()
}
