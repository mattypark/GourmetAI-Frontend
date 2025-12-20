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
    let background = Color.white
    let surface = Color.black.opacity(0.05)
    let primary = Color.black
    let secondary = Color.gray
    let accent = Color.black
    let error = Color.red

    // Card backgrounds
    let cardBackground = Color.black.opacity(0.03)
    let cardBorder = Color.black.opacity(0.15)
}
