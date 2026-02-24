//
//  MainTabView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import PhotosUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var previousTab: AppTab? = nil
    @State private var isTransitioning = false
    @State private var showingCamera = false
    @State private var showingGalleryPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingMultiImageReview = false
    @StateObject private var cameraViewModel = CameraViewModel()

    // Transition state
    @State private var incomingOffset: CGFloat = 60
    @State private var incomingOpacity: Double = 0
    @State private var outgoingOpacity: Double = 1

    var body: some View {
        VStack(spacing: 0) {
            // Tab content area with ghost + slide-up transitions
            ZStack {
                Color.theme.background.ignoresSafeArea()

                // Ghost of outgoing page (fades to 0.08 then disappears)
                if isTransitioning, let prev = previousTab {
                    tabContent(for: prev)
                        .opacity(outgoingOpacity)
                        .allowsHitTesting(false)
                }

                // Active / incoming page (slides up + fades in)
                tabContent(for: selectedTab)
                    .opacity(isTransitioning ? incomingOpacity : 1)
                    .offset(y: isTransitioning ? incomingOffset : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // Custom tab bar island with integrated + button
            CustomTabBar(

                selectedTab: Binding(
                    get: { selectedTab },
                    set: { newTab in
                        guard newTab != selectedTab else { return }
                        switchTab(to: newTab)
                    }
                ),
                onCameraSelected: {
                    cameraViewModel.resetAfterAnalysis()
                    showingCamera = true
                },
                onGallerySelected: {
                    cameraViewModel.resetAfterAnalysis()
                    showingGalleryPicker = true
                }
            )
        }
        .background(Color.theme.background.ignoresSafeArea())
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
        // Paywall prompt when user tries gated features without subscription
        .fullScreenCover(isPresented: $cameraViewModel.showPaywallPrompt) {
            PaywallFlowView(
                onSubscribed: {
                    cameraViewModel.showPaywallPrompt = false
                },
                onTrialActivated: {
                    cameraViewModel.showPaywallPrompt = false
                },
                onDismissed: {
                    cameraViewModel.showPaywallPrompt = false
                }
            )
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .calendar:
            CalendarView()
        case .explore:
            PlaceholderTabView(title: "Explore", icon: "safari")
        case .favorites:
            FavoritesView()
        }
    }

    // MARK: - Tab Transition

    private func switchTab(to newTab: AppTab) {
        guard !isTransitioning else { return }

        // Set up ghost of current page
        previousTab = selectedTab
        isTransitioning = true
        outgoingOpacity = 1
        incomingOffset = 60
        incomingOpacity = 0

        // Switch the actual tab
        selectedTab = newTab

        // Animate: ghost fades to near-invisible, incoming slides up + fades in
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            outgoingOpacity = 0.08
            incomingOffset = 0
            incomingOpacity = 1
        }

        // Clean up ghost after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isTransitioning = false
            previousTab = nil
            outgoingOpacity = 1
            incomingOffset = 0
            incomingOpacity = 1
        }
    }
}

// MARK: - Stagger Entry Modifier

struct StaggeredEntry: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.3)
                    .delay(Double(index) * 0.05)
                ) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}

extension View {
    func staggerEntry(index: Int) -> some View {
        modifier(StaggeredEntry(index: index))
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
                Color.theme.background.ignoresSafeArea()

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
