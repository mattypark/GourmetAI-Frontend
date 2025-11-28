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
    let background = Color.black
    let surface = Color.white.opacity(0.1)
    let primary = Color.white
    let secondary = Color.gray
    let accent = Color.white
    let error = Color.red

    // Card backgrounds
    let cardBackground = Color.white.opacity(0.05)
    let cardBorder = Color.white.opacity(0.2)
}
