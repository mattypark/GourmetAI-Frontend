//
//  PlaceholderTabView.swift
//  ChefAI
//
//  Placeholder for tabs that aren't built yet
//

import SwiftUI

struct PlaceholderTabView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text("Coming soon")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background.ignoresSafeArea())
    }
}

#Preview {
    PlaceholderTabView(title: "Explore", icon: "safari")
}
