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

    // Light gray background color (explicit, not system-adaptive)
    private let lightGrayBackground = Color(red: 230/255, green: 230/255, blue: 230/255)

    var body: some View {
        ZStack {
            // Light gray background (explicit color, ignores dark mode)
            lightGrayBackground
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
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Chef AI")
                .font(.headline)
                .foregroundColor(.black)

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
                        .fill(Color.white)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                        )
                }

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
                // Outer white ring
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)

                // Inner black circle
                Circle()
                    .fill(Color.black)
                    .frame(width: 64, height: 64)

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
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

    // Light gray background color (explicit, not system-adaptive)
    private let lightGrayBackground = Color(red: 230/255, green: 230/255, blue: 230/255)

    var body: some View {
        ZStack {
            // Light gray background (explicit color, ignores dark mode)
            lightGrayBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                headerView

                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()

                // Analyze button
                Button {
                    cameraViewModel.selectedImages = [image]
                    Task {
                        await cameraViewModel.analyzeImage()
                    }
                } label: {
                    Text("Analyze")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                }
                .disabled(cameraViewModel.isAnalyzing)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)

                if let errorMessage = cameraViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }
            }

            // Full-screen loading overlay
            if cameraViewModel.isAnalyzing || cameraViewModel.analysisStatus.isFinished {
                AnalysisLoadingView(
                    image: image,
                    cameraViewModel: cameraViewModel,
                    onBack: {
                        cameraViewModel.resetAfterAnalysis()
                        onDismiss()
                        dismiss()
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: cameraViewModel.isAnalyzing)
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

    private var headerView: some View {
        HStack {
            Button {
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Chef AI")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    CaptureScreenView()
}
