//
//  SettingsView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingProfileEdit = false
    @State private var showingAppSettings = false
    @State private var showingPrivacyPolicy = false
    @State private var showingClearDataAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Profile")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsRowButton(
                                    icon: "person.fill",
                                    title: "Edit Profile",
                                    subtitle: viewModel.userName
                                ) {
                                    showingProfileEdit = true
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // App Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("App Settings")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsRowButton(
                                    icon: "slider.horizontal.3",
                                    title: "Preferences",
                                    subtitle: "Notifications, haptics, and more"
                                ) {
                                    showingAppSettings = true
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 56)

                                SettingsRowButton(
                                    icon: "shield.fill",
                                    title: "Privacy Policy",
                                    subtitle: "How we protect your data"
                                ) {
                                    showingPrivacyPolicy = true
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // Data Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Data")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsRowButton(
                                    icon: "trash.fill",
                                    title: "Clear All Data",
                                    subtitle: "Delete all analyses and settings",
                                    destructive: true
                                ) {
                                    showingClearDataAlert = true
                                }
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // App Info
                        VStack(spacing: 8) {
                            Text("ChefAI")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))

                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))

                            Text("Made with AI-powered recipe suggestions")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.3))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingProfileEdit, onDismiss: {
                // Reload profile data when sheet closes in case it was updated
                viewModel.loadUserProfile()
            }) {
                ProfileEditView(viewModel: viewModel)
            }
            .onAppear {
                // Reload profile data when settings view appears
                viewModel.loadUserProfile()
            }
            .sheet(isPresented: $showingAppSettings) {
                AppSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text("This will delete all your analyses, liked recipes, and reset your settings. This action cannot be undone.")
            }
        }
    }
}

struct SettingsRowButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var destructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(destructive ? .red : .white)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(destructive ? .red : .white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(Color.white.opacity(0.05))
        }
    }
}

#Preview {
    SettingsView()
}
