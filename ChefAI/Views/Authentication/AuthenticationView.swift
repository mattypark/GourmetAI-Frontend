//
//  AuthenticationView.swift
//  ChefAI
//
//  Sign-in view with Apple and Google authentication options
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import CryptoKit

struct AuthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseManager.shared

    var onSuccess: (() -> Void)?

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.93))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("Sign in to Chef AI")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    Text("Save your ingredients and recipes across devices")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: configureAppleRequest,
                        onCompletion: handleAppleCompletion
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(28)

                    // Google Sign In
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: 12) {
                            // Google "G" logo
                            Image("GoogleLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)

                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Terms
                VStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption)
                        .foregroundColor(.black)

                        Text("and")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button("Privacy Policy") {
                            // Open privacy
                        }
                        .font(.caption)
                        .foregroundColor(.black)
                    }
                }
                .padding(.bottom, 40)
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

    // MARK: - Apple Sign In

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Failed to get Apple ID credentials"
                return
            }

            isLoading = true
            errorMessage = nil

            Task {
                do {
                    try await supabase.signInWithApple(idToken: idTokenString, nonce: nonce)
                    await MainActor.run {
                        isLoading = false
                        onSuccess?()
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Apple sign in failed: \(error.localizedDescription)"
                    }
                }
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple sign in failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            return
        }

        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        self.errorMessage = "Google sign in failed: \(error.localizedDescription)"
                    }
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to get Google credentials"
                }
                return
            }

            let accessToken = user.accessToken.tokenString

            Task {
                do {
                    try await supabase.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                    await MainActor.run {
                        isLoading = false
                        onSuccess?()
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Google sign in failed: \(error.localizedDescription)"
                    }
                }
            }
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
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}


#Preview {
    AuthenticationView()
}
