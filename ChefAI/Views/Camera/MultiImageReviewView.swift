//
//  MultiImageReviewView.swift
//  ChefAI
//
//  Created by Claude on 2025-02-12.
//

import SwiftUI
import PhotosUI

struct MultiImageReviewView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingImageSourcePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingGalleryPicker = false

    private let lightGrayBackground = Color(red: 230/255, green: 230/255, blue: 230/255)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            lightGrayBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Photo count
                Text("\(cameraViewModel.selectedImages.count)/\(AppConstants.maxCapturedImages) photos")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                // Scrollable image grid
                ScrollView {
                    imageGrid
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                }

                Spacer()

                // Error message
                if let error = cameraViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                // Analyze button
                analyzeButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }

            // Full-screen loading overlay when analyzing
            if cameraViewModel.isAnalyzing || cameraViewModel.analysisStatus.isFinished {
                AnalysisLoadingView(
                    images: cameraViewModel.selectedImages,
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
                        onDismiss()
                    }
                }
        }
        // Camera sub-flow for adding more photos
        .fullScreenCover(isPresented: $showingCamera) {
            CaptureScreenForMultiImage(
                onImageCaptured: { image in
                    cameraViewModel.addImage(image)
                    showingCamera = false
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
        // Gallery sub-flow for adding more photos
        .photosPicker(
            isPresented: $showingGalleryPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: cameraViewModel.remainingImageSlots,
            matching: .images
        )
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        cameraViewModel.addImage(image)
                    }
                }
                selectedPhotoItems = []
            }
        }
    }

    // MARK: - Header

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

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Image Grid

    private var imageGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(cameraViewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                imageCell(image: image, index: index)
            }

            if cameraViewModel.canAddMoreImages {
                addImageCell
            }
        }
    }

    // MARK: - Image Cell

    private func imageCell(image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                Button {
                    withAnimation {
                        cameraViewModel.removeImage(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .shadow(radius: 2)
                }
                .padding(8)
            }
    }

    // MARK: - Add Image Cell

    private var addImageCell: some View {
        Button {
            showingImageSourcePicker = true
        } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(height: 160)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.black)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .confirmationDialog("Add Photo", isPresented: $showingImageSourcePicker) {
            Button("Take Photo") { showingCamera = true }
            Button("Choose from Library") { showingGalleryPicker = true }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Analyze Button

    private var analyzeButton: some View {
        Button {
            Task {
                await cameraViewModel.analyzeImage()
            }
        } label: {
            Text("Analyze")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(cameraViewModel.selectedImages.isEmpty ? Color.gray : Color.black)
                .cornerRadius(28)
        }
        .disabled(cameraViewModel.selectedImages.isEmpty || cameraViewModel.isAnalyzing)
    }
}

// MARK: - Simplified Camera Capture for Multi-Image Flow

struct CaptureScreenForMultiImage: View {
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void

    @StateObject private var viewModel = CaptureViewModel()
    @Environment(\.dismiss) private var dismiss

    private let lightGrayBackground = Color(red: 230/255, green: 230/255, blue: 230/255)

    var body: some View {
        ZStack {
            lightGrayBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
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

                    Text("Take Photo")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    Color.clear
                        .frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Camera preview
                if viewModel.isCameraReady {
                    CameraPreviewLayer(session: viewModel.captureSession)
                        .cornerRadius(24)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .overlay(ProgressView().scaleEffect(1.5))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                Spacer()

                // Shutter button
                Button {
                    viewModel.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 64, height: 64)

                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        }
                    }
                }
                .disabled(viewModel.isProcessing)
                .padding(.bottom, 40)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }
            }
        }
        .onChange(of: viewModel.capturedImage) { _, newImage in
            if let image = newImage {
                onImageCaptured(image)
            }
        }
        .onAppear { viewModel.startSession() }
        .onDisappear { viewModel.stopSession() }
    }
}

#Preview {
    MultiImageReviewView(
        cameraViewModel: CameraViewModel(),
        onDismiss: {}
    )
}
