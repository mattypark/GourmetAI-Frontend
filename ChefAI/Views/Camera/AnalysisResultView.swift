//
//  AnalysisResultView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct AnalysisResultView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCompleting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let result = viewModel.analysisResult {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Fridge photo thumbnail
                            if let thumbnailImage = result.thumbnailImage {
                                Image(uiImage: thumbnailImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .shadow(color: .white.opacity(0.1), radius: 8)
                            }

                            // Analysis summary
                            Text("Found \(result.extractedIngredients.count) ingredient\(result.extractedIngredients.count == 1 ? "" : "s")")
                                .font(.headline)
                                .foregroundColor(.white)

                            // Detected ingredients list
                            if !result.extractedIngredients.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Detected Ingredients")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    ForEach(result.extractedIngredients) { ingredient in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)

                                            Text(ingredient.name)
                                                .foregroundColor(.white)

                                            Spacer()

                                            if let confidence = ingredient.confidence {
                                                Text("\(Int(confidence * 100))%")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                }
                            }

                            // Add missing ingredients section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Missing Anything?")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Text("Add any ingredients we missed")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))

                                // Manual ingredient input
                                ManualItemInputView(viewModel: viewModel)
                            }

                            // Complete button
                            PrimaryButton(
                                title: "Complete & Generate Recipes",
                                action: {
                                    Task { @MainActor in
                                        isCompleting = true
                                        await viewModel.completeAnalysis()
                                        // Dismiss after completion
                                        dismiss()
                                    }
                                },
                                isLoading: isCompleting
                            )
                            .disabled(isCompleting)
                            .padding(.top, 24)
                        }
                        .padding()
                    }
                } else {
                    // Fallback if no analysis result
                    Text("No analysis results available")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = CameraViewModel()
    AnalysisResultView(viewModel: viewModel)
}
