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
    @State private var selectedPhotoItem: PhotosPickerItem?

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

                // Mode selection buttons
                modeSelectionBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // Shutter button
                shutterButton
                    .padding(.bottom, 40)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.handleGalleryImage(image)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingPreview) {
            if let image = viewModel.capturedImage {
                CapturePreviewView(
                    image: image,
                    captureMode: viewModel.captureMode,
                    barcode: viewModel.scannedBarcode,
                    cameraViewModel: cameraViewModel,
                    onDismiss: {
                        viewModel.reset()
                    },
                    onComplete: {
                        dismiss()
                    }
                )
            } else if viewModel.captureMode == .barcode, let barcode = viewModel.scannedBarcode {
                BarcodeResultView(
                    barcode: barcode,
                    cameraViewModel: cameraViewModel,
                    onDismiss: {
                        viewModel.reset()
                    },
                    onComplete: {
                        dismiss()
                    }
                )
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

                // Barcode indicator
                if viewModel.captureMode == .barcode, let barcode = viewModel.scannedBarcode {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(barcode)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.bottom, 20)
                    }
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

    // MARK: - Mode Selection Bar

    private var modeSelectionBar: some View {
        HStack(spacing: 12) {
            ForEach(CaptureMode.allCases) { mode in
                if mode == .gallery {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ModeButton(
                            mode: mode,
                            isSelected: viewModel.captureMode == mode
                        )
                    }
                } else {
                    Button {
                        viewModel.setMode(mode)
                    } label: {
                        ModeButton(
                            mode: mode,
                            isSelected: viewModel.captureMode == mode
                        )
                    }
                }
            }
        }
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button {
            if viewModel.captureMode != .gallery {
                viewModel.capturePhoto()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                Circle()
                    .stroke(Color(UIColor.systemGray4), lineWidth: 4)
                    .frame(width: 72, height: 72)

                if viewModel.isProcessing {
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
        }
        .disabled(viewModel.isProcessing || viewModel.captureMode == .gallery)
        .opacity(viewModel.captureMode == .gallery ? 0.5 : 1)
    }
}

// MARK: - Mode Button

struct ModeButton: View {
    let mode: CaptureMode
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .primary)

            Text(mode.shortName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 72, height: 72)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color(UIColor.separator), lineWidth: 1)
        )
    }
}

// MARK: - Capture Preview View

struct CapturePreviewView: View {
    let image: UIImage
    let captureMode: CaptureMode
    let barcode: String?
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

                        // Mode indicator
                        HStack {
                            Image(systemName: captureMode.icon)
                            Text(captureMode.rawValue)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)

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

// MARK: - Barcode Result View

struct BarcodeResultView: View {
    let barcode: String
    @ObservedObject var cameraViewModel: CameraViewModel
    let onDismiss: () -> Void
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLookingUp = false
    @State private var productName: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Barcode icon
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.5))

                    // Barcode value
                    VStack(spacing: 8) {
                        Text("Scanned Barcode")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))

                        Text(barcode)
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }

                    if let name = productName {
                        VStack(spacing: 8) {
                            Text("Product Found")
                                .font(.headline)
                                .foregroundColor(.green)

                            Text(name)
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }

                    // Manual item input
                    ManualItemInputView(viewModel: cameraViewModel)

                    // Action buttons
                    VStack(spacing: 16) {
                        PrimaryButton(
                            title: "Add to Ingredients",
                            action: {
                                // Add barcode as manual item for now
                                cameraViewModel.currentManualItem = productName ?? "Barcode: \(barcode)"
                                cameraViewModel.addManualItem()
                                onComplete()
                            },
                            isLoading: false
                        )

                        Button("Scan Another") {
                            onDismiss()
                            dismiss()
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
            }
            .navigationTitle("Barcode Result")
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
            .task {
                await lookupBarcode()
            }
        }
    }

    private func lookupBarcode() async {
        isLookingUp = true
        defer { isLookingUp = false }

        // Try Open Food Facts API
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let product = json["product"] as? [String: Any],
               let name = product["product_name"] as? String {
                productName = name
            }
        } catch {
            print("Barcode lookup failed: \(error)")
        }
    }
}

#Preview {
    CaptureScreenView()
}
