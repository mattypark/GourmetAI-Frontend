//
//  OnboardingFlowView.swift
//  ChefAI
//
//  Master view that coordinates the entire onboarding flow:
//  Splash -> Welcome -> Onboarding Questions -> Paywall
//

import SwiftUI
import SuperwallKit

enum OnboardingStep {
    case splash
    case welcome
    case questions
    case paywall
}

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @State private var currentStep: OnboardingStep = .splash
    @State private var showSplash = true

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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .questions
                        }
                    },
                    onSignIn: {
                        // Handle sign in - for now just proceed
                        print("Sign in tapped")
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

            case .paywall:
                // Fallback local paywall (shown if Superwall is unavailable)
                PaywallView(
                    onGetStarted: {
                        // Start free trial and complete onboarding
                        SubscriptionService.shared.startFreeTrial()
                        viewModel.completeOnboarding()
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    },
                    onSignIn: {
                        // Handle sign in
                        print("Sign in tapped")
                    },
                    onRestore: {
                        // Handle restore purchases
                        SubscriptionService.shared.restorePurchases()
                    }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Superwall Integration

    private func showSuperwallPaywall() {
        // Register the paywall event with Superwall
        // "onboarding_complete" is the event name you'll configure in Superwall dashboard
        Superwall.shared.register(event: "onboarding_complete") {
            // This handler is called when user subscribes or paywall is dismissed
            handlePaywallResult()
        }
    }

    private func handlePaywallResult() {
        // Check if user has subscribed via Superwall
        // For now, start free trial and complete onboarding
        SubscriptionService.shared.startFreeTrial()
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

    var body: some View {
        ZStack {
            // White background
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button and progress
                HStack {
                    // Back button - goes to welcome on first page, previous page otherwise
                    Button {
                        if viewModel.currentPage == 0 {
                            onBackToWelcome()
                        } else {
                            withAnimation {
                                viewModel.previousPage()
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    // Skip button (hidden on last page)
                    Button {
                        withAnimation {
                            viewModel.skip()
                        }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .opacity(viewModel.isLastQuestion ? 0 : 1)
                    .disabled(viewModel.isLastQuestion)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Progress bar
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

                // Bottom button
                VStack(spacing: 12) {
                    Button(action: {
                        if viewModel.isLastQuestion {
                            onComplete()
                        } else {
                            // Use proceedFromCurrentQuestion to check for response screens
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
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
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
