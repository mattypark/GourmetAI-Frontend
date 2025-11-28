//
//  ImagePreviewView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct ImagePreviewView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Image preview
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                                .shadow(color: .white.opacity(0.1), radius: 8)
                        }

                        // Manual item input
                        ManualItemInputView(viewModel: viewModel)

                        // Confirm button
                        PrimaryButton(
                            title: "Analyze",
                            action: {
                                Task {
                                    await viewModel.analyzeImage()
                                    dismiss()
                                }
                            },
                            isLoading: viewModel.isAnalyzing
                        )
                        .disabled(viewModel.isAnalyzing)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .cardStyle()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Preview")
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

    ImagePreviewView(viewModel: viewModel)
}
