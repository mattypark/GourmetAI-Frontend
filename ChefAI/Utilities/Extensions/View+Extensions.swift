//
//  View+Extensions.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

extension View {
    /// Applies consistent card styling with black/white theme
    func cardStyle() -> some View {
        self
            .background(Color.theme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.theme.cardBorder, lineWidth: 1)
            )
    }

    /// Dismisses the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
