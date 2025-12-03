//
//  CaptureMode.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case scanIngredients = "Scan Ingredients"
    case barcode = "Barcode"
    case foodLabel = "Food Label"
    case gallery = "Gallery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scanIngredients:
            return "camera.viewfinder"
        case .barcode:
            return "barcode.viewfinder"
        case .foodLabel:
            return "doc.text.viewfinder"
        case .gallery:
            return "photo.on.rectangle"
        }
    }

    var shortName: String {
        switch self {
        case .scanIngredients:
            return "Scan\nIngredients"
        case .barcode:
            return "Barcode"
        case .foodLabel:
            return "Food\nLabel"
        case .gallery:
            return "Gallery"
        }
    }
}
