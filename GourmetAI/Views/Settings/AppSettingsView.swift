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
                Color.theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Notifications Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "bell.fill",
                                    title: "Enable Notifications",
                                    subtitle: "Get notified about new recipes",
                                    isOn: $viewModel.notificationsEnabled
                                )
                            }
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }

                        // Storage Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Storage")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "photo.fill",
                                    title: "Save Recipe Images",
                                    subtitle: "Automatically save photos of recipes",
                                    isOn: $viewModel.saveRecipeImages
                                )
                            }
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }

                        // Accessibility Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Accessibility")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    icon: "waveform",
                                    title: "Haptic Feedback",
                                    subtitle: "Feel vibrations on interactions",
                                    isOn: $viewModel.hapticFeedbackEnabled
                                )

                                Divider()
                                    .background(Color.black.opacity(0.1))
                                    .padding(.leading, 56)

                                SettingsToggleRow(
                                    icon: "moon.fill",
                                    title: "Dark Mode",
                                    subtitle: "Always use dark theme",
                                    isOn: $viewModel.darkModeEnabled
                                )
                            }
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.black)
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
                .foregroundColor(.black)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.black)
        }
        .padding()
    }
}

#Preview {
    @Previewable @StateObject var viewModel = SettingsViewModel()
    AppSettingsView(viewModel: viewModel)
}
