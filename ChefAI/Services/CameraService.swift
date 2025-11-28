//
//  CameraService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import AVFoundation
import UIKit

class CameraService {
    static let shared = CameraService()

    private init() {}

    func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func checkPhotoLibraryPermission() async -> Bool {
        // Note: iOS 14+ uses PHPickerViewController which doesn't require permissions
        // This is a placeholder for additional photo library operations if needed
        return true
    }
}
