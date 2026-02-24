//
//  ImageCard.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct ImageCard: View {
    let image: UIImage?
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.theme.surface)
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ImageCard(
            image: nil,
            title: "Chicken Stir Fry",
            subtitle: "3 ingredients"
        )
        .frame(width: 200)
        .padding()
    }
}
