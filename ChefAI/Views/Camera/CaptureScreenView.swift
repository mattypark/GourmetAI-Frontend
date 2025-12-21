//
//  CaptureScreenView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI
import PhotosUI

struct CaptureScreenView: View {
    @StateObject private var viewModel = CaptureViewModel()
    @StateObject private var cameraViewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Light background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                headerView

                // Camera preview area
                cameraPreviewArea
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()

                // Shutter button only - no mode selection
                shutterButton
                    .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingPreview) {
            if let image = viewModel.capturedImage {
                CapturePreviewView(
                    image: image,
                    cameraViewModel: cameraViewModel,
                    onDismiss: {
                        cameraViewModel.resetAfterAnalysis()
                        viewModel.reset()
                    },
                    onComplete: {
                        dismiss()
                    }
                )
            }
        }
        .onChange(of: viewModel.showingPreview) { _, isShowing in
            if isShowing {
                // Reset ViewModel state before showing preview
                cameraViewModel.resetAfterAnalysis()
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
            }

            Spacer()

            Text("ChefAI")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Camera Preview Area

    private var cameraPreviewArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                if viewModel.isCameraReady {
                    CameraPreviewLayer(session: viewModel.captureSession)
                        .cornerRadius(24)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                        )
                }

                // Frame overlay
                FrameOverlayView(
                    frameSize: min(geometry.size.width, geometry.size.height) * 0.7,
                    cornerLength: 50,
                    lineWidth: 4,
                    cornerRadius: 16,
                    color: .white.opacity(0.9)
                )

                // Error message
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                            .padding()
                    }
                }
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        let isProcessing = viewModel.isProcessing
        return Button {
            viewModel.capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 4)
                    .frame(width: 72, height: 72)

                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
        }
        .disabled(isProcessing)
    }
}

// MARK: - Capture Preview View

struct CapturePreviewView: View {
    let image: UIImage
    @ObservedObject var cameraViewModel: CameraViewModel
    let onDismiss: () -> Void
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Image preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .shadow(color: .white.opacity(0.1), radius: 8)

                        // Manual item input
                        ManualItemInputView(viewModel: cameraViewModel)

                        // Analyze button
                        PrimaryButton(
                            title: "Analyze",
                            action: {
                                cameraViewModel.selectedImage = image
                                Task {
                                    await cameraViewModel.analyzeImage()
                                }
                            },
                            isLoading: cameraViewModel.isAnalyzing
                        )
                        .disabled(cameraViewModel.isAnalyzing)

                        if let errorMessage = cameraViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding()
                }

                // Full-screen loading overlay with dynamic status
                if cameraViewModel.isAnalyzing || cameraViewModel.analysisStatus.isFinished {
                    ZStack {
                        Color.white
                            .ignoresSafeArea()

                        VStack {
                            Spacer()

                            AnalysisLoadingView(
                                image: image,
                                status: cameraViewModel.analysisStatus
                            )

                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: cameraViewModel.isAnalyzing)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .fullScreenCover(isPresented: $cameraViewModel.showingAnalysisResults) {
                AnalysisResultView(viewModel: cameraViewModel)
                    .onDisappear {
                        if cameraViewModel.analysisResult != nil {
                            onComplete()
                        }
                    }
            }
        }
    }
}

#Preview {
    CaptureScreenView()
}
