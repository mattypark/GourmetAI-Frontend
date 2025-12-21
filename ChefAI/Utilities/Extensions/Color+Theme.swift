//
//  Color+Theme.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    // Pure white/black theme
    let background = Color.white
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
