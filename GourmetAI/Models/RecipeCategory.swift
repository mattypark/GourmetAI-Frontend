//
//  RecipeCategory.swift
//  ChefAI
//

import Foundation
import SwiftUI

struct RecipeCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    var iconName: String?
    var recipeIds: [UUID]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        iconName: String? = nil,
        recipeIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.recipeIds = recipeIds
        self.createdAt = createdAt
    }

    var color: Color {
        Color(hex: colorHex)
    }

    /// Darkened version of the category color for readable text on pastel backgrounds
    var textColor: Color {
        let scanner = Scanner(string: colorHex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        let factor = 0.45
        return Color(red: r * factor, green: g * factor, blue: b * factor)
    }

    static let presetIcons: [String] = [
        "fork.knife", "carrot.fill", "cup.and.saucer.fill", "birthday.cake.fill",
        "leaf.fill", "flame.fill", "bolt.fill", "heart.fill",
        "star.fill", "timer", "bag.fill", "fish.fill"
    ]

    static let presetColors: [(name: String, hex: String)] = [
        ("Soft Yellow", "FFF3C4"),
        ("Light Blue", "C4DEFF"),
        ("Light Green", "C4F0C4"),
        ("Light Pink", "FCCFD0"),
        ("Lavender", "D9C4FF"),
        ("Peach", "FFD9C4"),
        ("Mint", "C4FFED"),
        ("Light Orange", "FFE0B2"),
        ("Soft Coral", "FFB4A9"),
        ("Sky Blue", "B3E5FC"),
        ("Light Gray", "E0E0E0"),
        ("Warm Beige", "F5E6CC")
    ]
}
