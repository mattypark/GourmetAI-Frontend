//
//  PrivacyPolicyView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        privacySection(
                            title: "Data Collection",
                            content: "ChefAI collects only the data you provide, including photos of your fridge and manually entered ingredients. We do not share your personal information with third parties."
                        )

                        privacySection(
                            title: "Image Storage",
                            content: "Photos you take are stored locally on your device. They are sent to OpenAI's API for analysis but are not permanently stored on external servers."
                        )

                        privacySection(
                            title: "AI Processing",
                            content: "We use OpenAI's GPT-4 Vision API to analyze your fridge photos and generate recipe suggestions. Please refer to OpenAI's privacy policy for information about their data handling practices."
                        )

                        privacySection(
                            title: "Local Data",
                            content: "All your analyses, liked recipes, and settings are stored locally on your device. You can clear all data at any time from the Settings menu."
                        )

                        privacySection(
                            title: "Third-Party Services",
                            content: "This app uses OpenAI's API for image analysis. No other third-party analytics or tracking services are used."
                        )

                        privacySection(
                            title: "Your Rights",
                            content: "You have full control over your data. You can delete all your information at any time by using the \"Clear All Data\" option in Settings."
                        )

                        Text("Last updated: January 29, 2025")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Privacy Policy")
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
        }
    }

    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)

            Text(content)
                .font(.body)
                .foregroundColor(.black.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
