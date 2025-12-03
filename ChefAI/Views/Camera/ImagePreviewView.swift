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
                                    // DON'T dismiss here anymore
                                    // Let the view navigate to results instead
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

                // Full-screen loading overlay with progress
                if viewModel.isAnalyzing {
                    ZStack {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()

                        VStack(spacing: 24) {
                            // Circular progress indicator
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .trim(from: 0, to: viewModel.analysisProgress)
                                    .stroke(Color.white, lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.3), value: viewModel.analysisProgress)

                                Text("\(Int(viewModel.analysisProgress * 100))%")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(spacing: 8) {
                                Text(progressMessage(for: viewModel.analysisProgress))
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)

                                if viewModel.analysisProgress < 0.2 {
                                    Text("Preparing image...")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                } else if viewModel.analysisProgress < 0.7 {
                                    Text("Analyzing ingredients...")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                } else if viewModel.analysisProgress < 0.95 {
                                    Text("Generating recipes...")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                } else {
                                    Text("Almost done...")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                        }
                    }
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
                    .disabled(viewModel.isAnalyzing)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingAnalysisResults) {
                AnalysisResultView(viewModel: viewModel)
            }
        }
    }

    private func progressMessage(for progress: Double) -> String {
        if progress < 0.2 {
            return "Starting analysis..."
        } else if progress < 0.5 {
            return "Uploading image..."
        } else if progress < 0.8 {
            return "Identifying ingredients..."
        } else if progress < 0.95 {
            return "Creating recipes..."
        } else {
            return "Finishing up..."
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = CameraViewModel()

    ImagePreviewView(viewModel: viewModel)
}
