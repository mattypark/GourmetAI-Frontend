//
//  AppSettingsView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct AppSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Notifications Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    title: "Enable Notifications",
                                    subtitle: "Get notified about new recipes",
                                    isOn: $viewModel.notificationsEnabled
                                )
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // Storage Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Storage")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "photo.fill",
                                    title: "Save Recipe Images",
                                    subtitle: "Automatically save photos of recipes",
                                    isOn: $viewModel.saveRecipeImages
                                )
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }

                        // Accessibility Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Accessibility")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "waveform",
                                    title: "Haptic Feedback",
                                    subtitle: "Feel vibrations on interactions",
                                    isOn: $viewModel.hapticFeedbackEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 56)

                                SettingsToggleRow(
                                    icon: "moon.fill",
                                    title: "Dark Mode",
                                    subtitle: "Always use dark theme",
                                    isOn: $viewModel.darkModeEnabled
                                )
                            }
                            .cardStyle()
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.white)
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
}

#Preview {
    @Previewable @StateObject var viewModel = SettingsViewModel()
    AppSettingsView(viewModel: viewModel)
}
