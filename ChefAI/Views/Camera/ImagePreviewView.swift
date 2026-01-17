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
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with X button and title
                HStack {
                    Button {
                        viewModel.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.isAnalyzing)

                    Spacer()

                    Text("Chef AI")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    Spacer()

                    // Invisible placeholder for symmetry
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Image preview
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Analyze button - black pill
                Button {
                    Task {
                        await viewModel.analyzeImage()
                    }
                } label: {
                    Text("Analyze")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                }
                .disabled(viewModel.isAnalyzing)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                // Error message if any
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }

            // Loading overlay
            if viewModel.isAnalyzing {
                AnalysisLoadingView(
                    image: viewModel.selectedImage,
                    onBack: {
                        viewModel.cancel()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingAnalysisResults, onDismiss: {
            viewModel.resetAfterAnalysis()
        }) {
            AnalysisResultView(viewModel: viewModel)
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = CameraViewModel()

    ImagePreviewView(viewModel: viewModel)
}
