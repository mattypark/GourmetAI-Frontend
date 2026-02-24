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
    @ObservedObject private var subscriptionService = SubscriptionService.shared

    // Auth state
    @State private var isSigningIn = false
    @State private var signInError: String?
    @State private var currentNonce: String?

    // Alert state
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingClearCacheAlert = false

    // Navigation state
    @State private var showingNutritionGoals = false
    @State private var showingHealthInfo = false
    @State private var showingWeightTracking = false
    @State private var showingSavedMeals = false
    @State private var showingFeedback = false
    @State private var showingAbout = false
    @State private var showingPaywall = false

    // Profile editing
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingImagePicker = false
    @State private var showingImageSourcePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    // Toggles
    @State private var dailyRemindersEnabled = true
    @State private var reminderFrequency = "Twice a day"
    @State private var automaticTimeZone = true
    @State private var dictationLanguage = "Auto-detect"

    // HealthKit
    @ObservedObject private var healthKitService = HealthKitService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    topHalf
                    bottomHalf
                }
                .padding(.horizontal, 16)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "FBFFF1"), Color(hex: "A8C49E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.6))
                            .frame(width: 30, height: 30)
                            .background(Color.black.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await supabase.signOut()
                        SubscriptionService.shared.clearSubscription()
                        HealthKitService.shared.clearHealthKitSettings()
                        UserDefaults.standard.set(false, forKey: StorageKeys.hasCompletedOnboarding)
                    }
                }
            } message: {
                Text("You will be signed out and returned to the welcome screen.")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // TODO: Implement account deletion
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .alert("Clear Local Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text("This will delete all locally cached data including analyses and settings. This action cannot be undone.")
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallFlowView(
                    onSubscribed: { showingPaywall = false },
                    onTrialActivated: { showingPaywall = false },
                    onDismissed: { showingPaywall = false }
                )
            }
            .sheet(isPresented: $showingNutritionGoals) {
                NutritionGoalsView()
            }
        }
    }

    // MARK: - Layout Halves

    private var topHalf: some View {
        VStack(spacing: 0) {
            nameEmailSection
                .padding(.top, 8)
            goalsAndTargetsSection
                .padding(.top, 28)
            healthProfileSection
                .padding(.top, 28)
            weightTrackingSection
                .padding(.top, 28)
            savedMealsSection
                .padding(.top, 28)
            dailyRemindersSection
                .padding(.top, 28)
        }
    }

    private var bottomHalf: some View {
        VStack(spacing: 0) {
            appleHealthSection
                .padding(.top, 28)
            deviceSettingsSection
                .padding(.top, 28)
            subscriptionSection
                .padding(.top, 28)
            infoSection
                .padding(.top, 28)
            dangerZoneSection
                .padding(.top, 28)
            Text("1.0.0")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.top, 24)
                .padding(.bottom, 40)
        }
    }

    // MARK: - Profile Section

    private var nameEmailSection: some View {
        VStack(spacing: 16) {
            // Profile picture
            Button {
                showingImageSourcePicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .frame(width: 90, height: 90)
                    .background(Color(hex: "F5F5F5"))
                    .clipShape(Circle())

                    // Camera badge
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.black)
                        .clipShape(Circle())
                        .offset(x: 2, y: 2)
                }
            }

            // Editable name
            if isEditingName {
                HStack(spacing: 8) {
                    TextField("Your name", text: $editedName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(10)
                        .frame(maxWidth: 200)
                        .onSubmit {
                            saveName()
                        }

                    Button {
                        saveName()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                }
            } else {
                Button {
                    editedName = viewModel.userName
                    isEditingName = true
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.userName.isEmpty ? "Add name" : viewModel.userName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
            }

            // Email (read-only)
            Text(supabase.currentUser?.email ?? "")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.theme.background)
        .cornerRadius(12)
        .confirmationDialog("Change Profile Photo", isPresented: $showingImageSourcePicker) {
            Button("Take Photo") {
                imagePickerSource = .camera
                showingImagePicker = true
            }
            Button("Choose from Library") {
                imagePickerSource = .photoLibrary
                showingImagePicker = true
            }
            if viewModel.profileImage != nil {
                Button("Remove Photo", role: .destructive) {
                    viewModel.updateProfileImage(nil)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showingImagePicker) {
            ProfileImagePicker(
                sourceType: imagePickerSource,
                onImagePicked: { image in
                    viewModel.updateProfileImage(image)
                }
            )
        }
    }

    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            viewModel.userName = trimmed
            viewModel.saveSettings()
        }
        isEditingName = false
    }

    // MARK: - Goals & Targets

    private var goalsAndTargetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Goals & Targets")

            VStack(spacing: 0) {
                // Daily Targets card
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Targets")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        HStack(spacing: 6) {
                            macroTag(icon: "flame.fill", text: "\(nutritionFormattedCalories) cal", color: .orange)
                            Text("·").foregroundColor(.gray)
                            macroTag(icon: nil, text: "P \(nutritionProteinGrams)g", color: .red)
                            Text("·").foregroundColor(.gray)
                            macroTag(icon: nil, text: "C \(nutritionCarbsGrams)g", color: .blue)
                            Text("·").foregroundColor(.gray)
                            macroTag(icon: nil, text: "F \(nutritionFatGrams)g", color: .yellow)
                        }
                        .font(.system(size: 12))
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .padding(.leading, 16)

                settingsRow(title: "Manage Nutrition Goals") {
                    showingNutritionGoals = true
                }
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Health Profile

    private var healthProfileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Health Profile")

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "staroflife.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health Info")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        Text("Not set")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .onTapGesture { showingHealthInfo = true }

                Divider()
                    .padding(.leading, 16)

                settingsRow(title: "Manage Health Info") {
                    showingHealthInfo = true
                }
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Weight Tracking

    private var weightTrackingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Weight Tracking")

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Track your weight")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        Text("Log weight to see trends")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .onTapGesture { showingWeightTracking = true }
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Saved Meals

    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Saved Meals")

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manage Saved Meals")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        Text("0 saved meals")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .onTapGesture { showingSavedMeals = true }
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Daily Tracking Reminders

    private var dailyRemindersSection: some View {
        VStack(spacing: 0) {
            settingsToggleRow(
                icon: "bell.fill",
                iconColor: .blue,
                title: "Daily Tracking Reminders",
                isOn: $dailyRemindersEnabled
            )

            Divider()
                .padding(.leading, 16)

            HStack {
                Text("Frequency")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Spacer()
                Menu {
                    Button("Once a day") { reminderFrequency = "Once a day" }
                    Button("Twice a day") { reminderFrequency = "Twice a day" }
                    Button("Three times a day") { reminderFrequency = "Three times a day" }
                } label: {
                    HStack(spacing: 4) {
                        Text(reminderFrequency)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.theme.background)
        .cornerRadius(12)
    }

    // MARK: - Apple Health

    private var appleHealthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Apple Health")

            if healthKitService.isAvailable {
                VStack(spacing: 0) {
                    settingsToggleRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Apple Health",
                        isOn: Binding(
                            get: { healthKitService.isEnabled },
                            set: { newValue in
                                if newValue {
                                    Task { await healthKitService.requestAuthorization() }
                                } else {
                                    healthKitService.isEnabled = false
                                }
                            }
                        )
                    )

                    if healthKitService.isEnabled {
                        dividerRow()
                        settingsToggleRow(
                            icon: "arrow.up.circle.fill",
                            iconColor: .orange,
                            title: "Send Calories to Health",
                            isOn: $healthKitService.sendCalories
                        )

                        dividerRow()
                        settingsToggleRow(
                            icon: "arrow.up.circle.fill",
                            iconColor: .blue,
                            title: "Send Macros to Health",
                            isOn: $healthKitService.sendMacros
                        )

                        dividerRow()
                        settingsToggleRow(
                            icon: "flame.circle.fill",
                            iconColor: .orange,
                            title: "Read Burned Calories",
                            isOn: $healthKitService.readBurnedCaloriesEnabled
                        )

                        dividerRow()
                        settingsToggleRow(
                            icon: "bed.double.fill",
                            iconColor: .purple,
                            title: "Read Resting Energy",
                            subtitle: "Base calories your body burns",
                            isOn: $healthKitService.readRestingEnergyEnabled
                        )

                        dividerRow()
                        settingsToggleRow(
                            icon: "figure.walk",
                            iconColor: .green,
                            title: "Read Steps",
                            isOn: $healthKitService.readStepsEnabled
                        )

                        dividerRow()
                        settingsToggleRow(
                            icon: "figure.run",
                            iconColor: .green,
                            title: "Read Workouts",
                            isOn: $healthKitService.readWorkoutsEnabled
                        )
                    }

                    dividerRow()

                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Text("Not seeing data? Check Health app permissions.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .background(Color.theme.background)
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .frame(width: 28)
                        Text("Apple Health is not available on this device")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .background(Color.theme.background)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Device Settings

    private var deviceSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Device Settings")

            VStack(spacing: 0) {
                settingsToggleRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: "Automatic Time Zone",
                    isOn: $automaticTimeZone
                )

                dividerRow()

                HStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 28)

                    Text("Dictation Language")
                        .font(.system(size: 16))
                        .foregroundColor(.black)

                    Button {
                        // Info popover
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Menu {
                        Button("Auto-detect") { dictationLanguage = "Auto-detect" }
                        Button("English") { dictationLanguage = "English" }
                        Button("Spanish") { dictationLanguage = "Spanish" }
                    } label: {
                        HStack(spacing: 4) {
                            Text(dictationLanguage)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Subscription")

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "crown")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscriptionService.hasAccess ? "Premium Active" : "No Subscription Active")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        if !subscriptionService.hasAccess {
                            Text("Activate to unlock all features")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    if !subscriptionService.hasAccess {
                        Button {
                            showingPaywall = true
                        } label: {
                            Text("Upgrade")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.yellow.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Info Section (Feedback & About)

    private var infoSection: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                settingsRowWithIcon(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Give Feedback"
                ) {
                    showingFeedback = true
                }
            }
            .background(Color.theme.background)
            .cornerRadius(12)

            VStack(spacing: 0) {
                settingsRowWithIcon(
                    icon: "heart.fill",
                    iconColor: .purple,
                    title: "About the App"
                ) {
                    showingAbout = true
                }
            }
            .background(Color.theme.background)
            .cornerRadius(12)
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(spacing: 0) {
            dangerRow(icon: "envelope.fill", title: "Contact Support", color: .blue) {
                // Open email
                if let url = URL(string: "mailto:support@gourmetai.app") {
                    UIApplication.shared.open(url)
                }
            }

            dividerRow()

            dangerRow(icon: "trash.fill", title: "Clear Local Cache", color: .red) {
                showingClearCacheAlert = true
            }

            dividerRow()

            dangerRow(icon: "square.and.arrow.up", title: "Export Data", color: .blue) {
                // TODO: Export data
            }

            dividerRow()

            dangerRow(icon: "exclamationmark.octagon.fill", title: "Delete Account", color: .red) {
                showingDeleteAccountAlert = true
            }

            dividerRow()

            dangerRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red) {
                showingSignOutAlert = true
            }
        }
        .background(Color.theme.background)
        .cornerRadius(12)
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .padding(.leading, 4)
    }

    private func settingsRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsRowWithIcon(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsToggleRow(icon: String, iconColor: Color, title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.black)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func dangerRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nutrition Goal Computed Properties

    private var nutritionCalories: Int {
        if let stored = UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalCalories) as? Double {
            return Int(stored)
        }
        return StorageService.shared.loadUserProfile().recommendedCalories ?? 2000
    }

    private var nutritionFormattedCalories: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: nutritionCalories)) ?? "\(nutritionCalories)"
    }

    private var nutritionProteinGrams: Int {
        let pct = UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalProteinPercent) as? Double ?? 30
        return Int(Double(nutritionCalories) * pct / 100 / 4)
    }

    private var nutritionCarbsGrams: Int {
        let pct = UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalCarbsPercent) as? Double ?? 40
        return Int(Double(nutritionCalories) * pct / 100 / 4)
    }

    private var nutritionFatGrams: Int {
        let pct = UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalFatPercent) as? Double ?? 30
        return Int(Double(nutritionCalories) * pct / 100 / 9)
    }

    private func macroTag(icon: String?, text: String, color: Color) -> some View {
        HStack(spacing: 2) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
            } else {
                Text(String(text.prefix(1)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            Text(icon != nil ? text : String(text.dropFirst(2)))
                .foregroundColor(.black.opacity(0.7))
        }
    }

    private func dividerRow() -> some View {
        Divider()
            .padding(.leading, 56)
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
}

// MARK: - Profile Image Picker

struct ProfileImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let edited = info[.editedImage] as? UIImage {
                parent.onImagePicked(edited)
            } else if let original = info[.originalImage] as? UIImage {
                parent.onImagePicked(original)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ProfileMenuView()
}
