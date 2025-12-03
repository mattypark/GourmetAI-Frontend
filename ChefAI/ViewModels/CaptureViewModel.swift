//
//  CaptureViewModel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
class CaptureViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var captureMode: CaptureMode = .scanIngredients
    @Published var capturedImage: UIImage?
    @Published var isShowingGallery = false
    @Published var isProcessing = false
    @Published var isCameraReady = false
    @Published var scannedBarcode: String?
    @Published var showingPreview = false
    @Published var errorMessage: String?

    // MARK: - Camera Properties

    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var metadataOutput = AVCaptureMetadataOutput()
    private var currentDevice: AVCaptureDevice?

    // MARK: - Initialization

    override init() {
        super.init()
        Task {
            await setupCamera()
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() async {
        // Check camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await configureSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                await configureSession()
            } else {
                errorMessage = "Camera access denied"
            }
        case .denied, .restricted:
            errorMessage = "Camera access denied. Please enable in Settings."
        @unknown default:
            errorMessage = "Unknown camera authorization status"
        }
    }

    private func configureSession() async {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Add video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            errorMessage = "No camera available"
            captureSession.commitConfiguration()
            return
        }

        currentDevice = camera

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            captureSession.commitConfiguration()
            return
        }

        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        // Add metadata output for barcode scanning
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr, .code128, .code39, .pdf417]
        }

        captureSession.commitConfiguration()

        // Start session on background thread
        Task.detached { [weak self] in
            self?.captureSession.startRunning()
            await MainActor.run {
                self?.isCameraReady = true
            }
        }
    }

    // MARK: - Public Methods

    func startSession() {
        guard !captureSession.isRunning else { return }
        Task.detached { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        Task.detached { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func capturePhoto() {
        guard isCameraReady else { return }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto

        isProcessing = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func setMode(_ mode: CaptureMode) {
        captureMode = mode

        // Reset barcode when switching modes
        if mode != .barcode {
            scannedBarcode = nil
        }

        // Open gallery if gallery mode selected
        if mode == .gallery {
            isShowingGallery = true
        }
    }

    func handleGalleryImage(_ image: UIImage) {
        capturedImage = image
        showingPreview = true
    }

    func reset() {
        capturedImage = nil
        scannedBarcode = nil
        showingPreview = false
        isProcessing = false
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CaptureViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            isProcessing = false

            if let error = error {
                errorMessage = "Photo capture failed: \(error.localizedDescription)"
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                errorMessage = "Failed to process photo"
                return
            }

            capturedImage = image
            showingPreview = true
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CaptureViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        Task { @MainActor in
            // Only process barcodes in barcode mode
            guard captureMode == .barcode else { return }

            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = metadataObject.stringValue else {
                return
            }

            // Avoid duplicate scans
            guard scannedBarcode != stringValue else { return }

            scannedBarcode = stringValue

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Auto-process after short delay
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            showingPreview = true
        }
    }
}
