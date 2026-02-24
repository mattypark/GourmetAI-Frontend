//
//  Color+Theme.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

extension Color {
    static let theme = ColorTheme()

    /// Initialize Color from hex string (e.g., "4B3CFA" or "#4B3CFA")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ColorTheme {
    // App background — soft warm mint (#FBFFF1)
    let background = Color(hex: "FBFFF1")
    let surface = Color.black.opacity(0.02)
    let primary = Color.black
    let secondary = Color.gray
    let accent = Color.black
    let error = Color.red

    // Card backgrounds
    let cardBackground = Color.black.opacity(0.02)
    let cardBorder = Color.black.opacity(0.08)

    // Text colors
    let textPrimary = Color.black
    let textSecondary = Color.gray
    let textMuted = Color.black.opacity(0.5)
}
