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
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingImagePreview = false
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
                            showingCamera = true
                        },
                        onGallerySelected: {
                            showingGalleryPicker = true
                        }
                    )
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        // Camera flow - opens simplified CaptureScreenView
        .fullScreenCover(isPresented: $showingCamera) {
            CaptureScreenView()
        }
        // Gallery flow - direct PhotosPicker
        .photosPicker(isPresented: $showingGalleryPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Reset ViewModel state before showing preview
                    cameraViewModel.resetAfterAnalysis()
                    selectedImage = image
                    showingImagePreview = true
                }
            }
        }
        // Show preview after gallery selection
        .fullScreenCover(isPresented: $showingImagePreview, onDismiss: {
            selectedImage = nil
            selectedPhotoItem = nil
        }) {
            if let image = selectedImage {
                GalleryPreviewView(
                    image: image,
                    cameraViewModel: cameraViewModel,
                    onComplete: {
                        showingImagePreview = false
                    }
                )
            }
        }
    }
}

// MARK: - Gallery Preview View

struct GalleryPreviewView: View {
    let image: UIImage
    @ObservedObject var cameraViewModel: CameraViewModel
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

                // Full-screen loading overlay
                if cameraViewModel.isAnalyzing || cameraViewModel.analysisStatus.isFinished {
                    AnalysisLoadingView(
                        image: image,
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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
    MainTabView()
}
