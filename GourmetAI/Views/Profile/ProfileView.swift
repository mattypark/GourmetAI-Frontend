//
//  ProfileView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader

                        // Preferences Sections
                        preferencesSection

                        // Edit Profile Button
                        editProfileButton
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditView(viewModel: viewModel)
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

            // User Bio
            if !viewModel.userBio.isEmpty {
                Text(viewModel.userBio)
                    .font(.body)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        VStack(spacing: 16) {
            // Main Goal
            if let goal = viewModel.mainGoal {
                ProfilePreferenceRow(
                    icon: "target",
                    title: "Main Goal",
                    value: goal.rawValue
                )
            }

            // Dietary Restrictions
            if !viewModel.dietaryRestrictions.isEmpty {
                ProfilePreferenceRow(
                    icon: "leaf.fill",
                    title: "Dietary Restrictions",
                    tags: viewModel.dietaryRestrictions.map { $0.rawValue }
                )
            }

            // Skill Level
            if let skill = viewModel.cookingSkillLevel {
                ProfilePreferenceRow(
                    icon: "chart.bar.fill",
                    title: "Skill Level",
                    value: skill.rawValue
                )
            }

            // Meal Preferences
            if !viewModel.mealPreferences.isEmpty {
                ProfilePreferenceRow(
                    icon: "fork.knife.circle.fill",
                    title: "Meal Preferences",
                    tags: viewModel.mealPreferences.map { $0.rawValue }
                )
            }

            // Time Availability
            if let time = viewModel.timeAvailability {
                ProfilePreferenceRow(
                    icon: "clock.fill",
                    title: "Cooking Time",
                    value: time.rawValue
                )
            }

            // Equipment
            if !viewModel.cookingEquipment.isEmpty {
                ProfilePreferenceRow(
                    icon: "wrench.and.screwdriver.fill",
                    title: "Equipment",
                    tags: viewModel.cookingEquipment.map { $0.rawValue }
                )
            }

            // Cooking Struggles
            if !viewModel.cookingStruggles.isEmpty {
                ProfilePreferenceRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Cooking Struggles",
                    tags: viewModel.cookingStruggles.map { $0.rawValue }
                )
            }

            // Adventure Level
            if let adventure = viewModel.adventureLevel {
                ProfilePreferenceRow(
                    icon: "sparkles",
                    title: "Adventure Level",
                    value: adventure.rawValue
                )
            }

            // Favorite Cuisines
            if !viewModel.cuisinePreferences.isEmpty {
                ProfilePreferenceRow(
                    icon: "globe",
                    title: "Favorite Cuisines",
                    tags: viewModel.cuisinePreferences.map { $0.rawValue }
                )
            }
        }
    }

    // MARK: - Edit Profile Button

    private var editProfileButton: some View {
        Button {
            showingEditProfile = true
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Edit Profile")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black)
            .cornerRadius(12)
        }
    }
}

// MARK: - Profile Preference Row

struct ProfilePreferenceRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var tags: [String]? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }

            // Content
            if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.leading, 28)
            }

            if let tags = tags {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(16)
                    }
                }
                .padding(.leading, 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileView()
}
