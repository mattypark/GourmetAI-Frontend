//
//  ProfileMenuView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct ProfileMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingEditProfile = false
    @State private var showingOnboarding = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAppSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader

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
            .sheet(isPresented: $showingOnboarding) {
                OnboardingContainerView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingAppSettings) {
                AppSettingsView(viewModel: viewModel)
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

            // Onboarding Questions
            MenuButton(
                icon: "questionmark.circle",
                title: "Retake Onboarding",
                subtitle: "Update your cooking profile"
            ) {
                showingOnboarding = true
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
