//
//  ImagePickerService.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import UIKit

class ImagePickerService {
    static let shared = ImagePickerService()

    private init() {}

    func compressImage(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        return imageData
    }
}
