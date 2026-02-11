//
//  ProfileMenuView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI
import Auth
import AuthenticationServices
import GoogleSignIn
import CryptoKit

struct ProfileMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showingEditProfile = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAppSettings = false
    @State private var showingSignOutAlert = false
    @State private var isSigningIn = false
    @State private var signInError: String?
    @State private var currentNonce: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader

                        // Account Section (authenticated) or Sign-In Section (not authenticated)
                        if supabase.isAuthenticated {
                            accountSection
                        } else {
                            signInSection
                        }

                        // Menu Options
                        menuSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingAppSettings) {
                AppSettingsView(viewModel: viewModel)
            }
            .alert("Log Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    Task {
                        try? await supabase.signOut()
                        // Reset onboarding flag to return to welcome screen
                        UserDefaults.standard.set(false, forKey: StorageKeys.hasCompletedOnboarding)
                        // Clear local data
                        StorageService.shared.clearAllData()
                    }
                }
            } message: {
                Text("You will be signed out and returned to the welcome screen. All local data will be cleared.")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Profile Picture
            if let profileImage = viewModel.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }

            // User Name
            Text(viewModel.userName.isEmpty ? "Chef" : viewModel.userName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)

            // User Email
            if !viewModel.userEmail.isEmpty {
                Text(viewModel.userEmail)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 0) {
            // Signed in info
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.black)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed in with")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(supabase.currentUser?.email ?? "Unknown")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }

                Spacer()
            }
            .padding()

            Divider()
                .padding(.leading, 56)

            // Log Out button
            Button {
                showingSignOutAlert = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .frame(width: 32)

                    Text("Log Out")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding()
            }
        }
        .background(Color.black.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Sign In Section

    private var signInSection: some View {
        VStack(spacing: 12) {
            // Google Sign In Button
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
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
            }
            .disabled(isSigningIn)

            // Apple Sign In Button
            SignInWithAppleButton(
                onRequest: configureAppleRequest,
                onCompletion: handleAppleCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .cornerRadius(12)
            .disabled(isSigningIn)

            // Error message
            if let error = signInError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            // Loading indicator
            if isSigningIn {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            signInError = "Cannot find root view controller"
            return
        }

        isSigningIn = true
        signInError = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isSigningIn = false
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        self.signInError = "Google sign in failed: \(error.localizedDescription)"
                    }
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isSigningIn = false
                    self.signInError = "Failed to get Google credentials"
                }
                return
            }

            let accessToken = user.accessToken.tokenString

            Task {
                do {
                    try await supabase.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                    await MainActor.run {
                        isSigningIn = false
                    }
                } catch {
                    await MainActor.run {
                        isSigningIn = false
                        signInError = "Google sign in failed: \(error.localizedDescription)"
                    }
                }
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
                signInError = "Failed to get Apple ID credentials"
                return
            }

            isSigningIn = true
            signInError = nil

            Task {
                do {
                    try await supabase.signInWithApple(idToken: idTokenString, nonce: nonce)
                    await MainActor.run {
                        isSigningIn = false
                    }
                } catch {
                    await MainActor.run {
                        isSigningIn = false
                        signInError = "Apple sign in failed: \(error.localizedDescription)"
                    }
                }
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                signInError = "Apple sign in failed: \(error.localizedDescription)"
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

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: 12) {
            // Your Preferences
            MenuButton(
                icon: "slider.horizontal.3",
                title: "Your Preferences",
                subtitle: "Goals, dietary restrictions, skill level"
            ) {
                showingEditProfile = true
            }

            // Privacy Policy
            MenuButton(
                icon: "lock.shield",
                title: "Privacy Policy",
                subtitle: "How we handle your data"
            ) {
                showingPrivacyPolicy = true
            }

            // App Settings
            MenuButton(
                icon: "gearshape",
                title: "App Settings",
                subtitle: "Notifications, data management"
            ) {
                showingAppSettings = true
            }
        }
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.black)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.black.opacity(0.02))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    ProfileMenuView()
}
