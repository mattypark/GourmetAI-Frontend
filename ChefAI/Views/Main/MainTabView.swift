//
//  MainTabView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import PhotosUI

struct MainTabView: View {
    @State private var showingCamera = false
    @State private var showingGalleryPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingMultiImageReview = false
    @StateObject private var cameraViewModel = CameraViewModel()

    var body: some View {
        ZStack {
            // Single Home view - no tab bar needed
            HomeView()

            // Floating Action Button Overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingPlusButton(
                        onCameraSelected: {
                            cameraViewModel.resetAfterAnalysis()
                            showingCamera = true
                        },
                        onGallerySelected: {
                            cameraViewModel.resetAfterAnalysis()
                            showingGalleryPicker = true
                        }
                    )
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        // Camera flow: capture first photo, then show multi-image review
        .fullScreenCover(isPresented: $showingCamera) {
            CaptureScreenForMultiImage(
                onImageCaptured: { image in
                    cameraViewModel.addImage(image)
                    showingCamera = false
                    showingMultiImageReview = true
                },
                onDismiss: {
                    showingCamera = false
                }
            )
        }
        // Gallery flow: multi-select photos, then show multi-image review
        .photosPicker(
            isPresented: $showingGalleryPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: AppConstants.maxCapturedImages,
            matching: .images
        )
        .onChange(of: selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        cameraViewModel.addImage(image)
                    }
                }
                selectedPhotoItems = []
                if !cameraViewModel.selectedImages.isEmpty {
                    showingMultiImageReview = true
                }
            }
        }
        // Multi-image review screen
        .fullScreenCover(isPresented: $showingMultiImageReview, onDismiss: {
            cameraViewModel.resetAfterAnalysis()
        }) {
            MultiImageReviewView(
                cameraViewModel: cameraViewModel,
                onDismiss: {
                    showingMultiImageReview = false
                }
            )
        }
    }
}

// MARK: - Gallery Preview View (Legacy — kept for compatibility)

struct GalleryPreviewView: View {
    let image: UIImage
    @ObservedObject var cameraViewModel: CameraViewModel
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Image preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8)

                        // Manual item input
                        ManualItemInputView(viewModel: cameraViewModel)

                        // Analyze button
                        PrimaryButton(
                            title: "Analyze",
                            action: {
                                cameraViewModel.selectedImages = [image]
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

                // Full-screen loading overlay
                if cameraViewModel.isAnalyzing || cameraViewModel.analysisStatus.isFinished {
                    AnalysisLoadingView(
                        image: image,
                        cameraViewModel: cameraViewModel,
                        onBack: {
                            cameraViewModel.resetAfterAnalysis()
                            dismiss()
                        }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: cameraViewModel.isAnalyzing)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
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
    MainTabView()
}
