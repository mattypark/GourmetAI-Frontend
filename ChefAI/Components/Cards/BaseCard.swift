//
//  BaseCard.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct BaseCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .cardStyle()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Card description goes here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}
