//
//  OnboardingFlowView.swift
//  ChefAI
//
//  Master view that coordinates the entire onboarding flow:
//  Splash -> Welcome -> Onboarding Questions -> Completion -> Home
//

import SwiftUI
import Auth
import AuthenticationServices
import GoogleSignIn
import CryptoKit

enum OnboardingStep {
    case splash
    case welcome
    case questions
    case completion
    case paywall
}

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var supabase = SupabaseManager.shared
    @AppStorage(StorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @State private var currentStep: OnboardingStep = .welcome
    @State private var showSplash = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var appleSignInPresentationProvider: AppleSignInPresentationProvider?

    var body: some View {
        ZStack {
            // Background for smooth transitions
            Color.theme.background.ignoresSafeArea()

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
                LiquidGlassSplashView(
                    onGoogleSignIn: {
                        signInWithGoogle()
                    },
                    onAppleSignIn: {
                        startAppleSignIn()
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .paywall
                        }
                    }
                )
                .transition(.opacity)

            case .paywall:
                PaywallFlowView(
                    onSubscribed: {
                        finishOnboarding()
                    },
                    onTrialActivated: {
                        finishOnboarding()
                    },
                    onDismissed: {
                        finishOnboarding()
                    }
                )
                .transition(.opacity)
            }

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }

    // MARK: - Auth Success

    private func handleAuthSuccess() {
        guard let userId = supabase.currentUser?.id.uuidString else {
            withAnimation(.easeInOut(duration: 0.3)) { currentStep = .questions }
            return
        }

        // Always persist the userId so fast-path checks work on this device
        UserDefaults.standard.set(userId, forKey: StorageKeys.currentUserId)

        // Fast path: local UserDefaults flag is present (same device, same install)
        if StorageService.shared.hasCompletedOnboarding(for: userId) {
            finishOnboarding()
            return
        }

        // Slow path: local flag is missing (reinstall / new device) — check Supabase
        isLoading = true
        Task {
            let hasProfile = await supabase.hasExistingProfile()
            await MainActor.run {
                isLoading = false
                if hasProfile {
                    // Returning user on a fresh install — restore flag and skip onboarding
                    StorageService.shared.setOnboardingComplete(true, for: userId)
                    finishOnboarding()
                } else {
                    // Genuinely new user — proceed to onboarding questions
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .questions
                    }
                }
            }
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

    // MARK: - Google Sign In44

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        isLoading = true

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        self.errorMessage = error.localizedDescription
                    }
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            let accessToken = user.accessToken.tokenString

            Task {
                do {
                    try await supabase.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                    await MainActor.run {
                        isLoading = false
                        handleAuthSuccess()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    // MARK: - Apple Sign In

    private func startAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { result in
            handleAppleResult(result)
        }
        // Store delegate to keep it alive
        appleSignInDelegate = delegate
        controller.delegate = delegate
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let provider = AppleSignInPresentationProvider(window: windowScene.windows.first)
            controller.presentationContextProvider = provider
            appleSignInPresentationProvider = provider
        }
        controller.performRequests()
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                return
            }

            isLoading = true

            Task {
                do {
                    try await supabase.signInWithApple(idToken: idTokenString, nonce: nonce)
                    await MainActor.run {
                        isLoading = false
                        handleAuthSuccess()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                    }
                }
            }

        case .failure:
            break
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign In Helpers

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let completion: (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

class AppleSignInPresentationProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    let window: UIWindow?

    init(window: UIWindow?) {
        self.window = window
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window ?? ASPresentationAnchor()
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
            Color.theme.background.ignoresSafeArea()

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
