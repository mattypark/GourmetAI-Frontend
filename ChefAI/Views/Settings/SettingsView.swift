//
//  SettingsView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import Auth

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showingAppSettings = false
    @State private var showingPrivacyPolicy = false
    @State private var showingClearDataAlert = false
    @State private var showingAuthSheet = false
    @State private var showingSignOutAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                if supabase.isAuthenticated {
                                    // Show user info and sign out
                                    HStack(spacing: 16) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.black)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Signed In")
                                                .font(.body)
                                                .foregroundColor(.black)

                                            Text(supabase.currentUser?.email ?? "No email")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()
                                    }
                                    .padding()

                                    Divider()
                                        .background(Color.black.opacity(0.1))
                                        .padding(.leading, 56)

                                    SettingsRowButton(
                                        icon: "rectangle.portrait.and.arrow.right",
                                        title: "Sign Out",
                                        subtitle: "Sign out of your account",
                                        destructive: true
                                    ) {
                                        showingSignOutAlert = true
                                    }
                                } else {
                                    // Show sign in button
                                    SettingsRowButton(
                                        icon: "person.crop.circle.badge.plus",
                                        title: "Sign In",
                                        subtitle: "Sign in to save your data across devices"
                                    ) {
                                        showingAuthSheet = true
                                    }
                                }
                            }
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }

                        // App Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("App Settings")
                                .font(.headline)
                                .foregroundColor(.gray)
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
                                    .background(Color.black.opacity(0.1))
                                    .padding(.leading, 56)

                                SettingsRowButton(
                                    icon: "shield.fill",
                                    title: "Privacy Policy",
                                    subtitle: "How we protect your data"
                                ) {
                                    showingPrivacyPolicy = true
                                }
                            }
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }

                        // Data Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Data")
                                .font(.headline)
                                .foregroundColor(.gray)
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
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }

                        // App Info
                        VStack(spacing: 8) {
                            Text("ChefAI")
                                .font(.headline)
                                .foregroundColor(.gray)

                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))

                            Text("Made with AI-powered recipe suggestions")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
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
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await supabase.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingAuthSheet) {
                AuthenticationView()
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
                    .foregroundColor(destructive ? .red : .black)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(destructive ? .red : .black)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding()
        }
    }
}

#Preview {
    SettingsView()
}
