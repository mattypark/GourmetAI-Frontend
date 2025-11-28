//
//  LikedRecipeCardView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct LikedRecipeCardView: View {
    let recipe: Recipe
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe placeholder image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.theme.surface)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12)

                // Heart button
                Button(action: onLike) {
                    Image(systemName: recipe.isLiked ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(recipe.isLiked ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.prefix(2).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                if let totalTime = recipe.totalTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(totalTime) min")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(MockData.mockRecipes) { recipe in
                LikedRecipeCardView(recipe: recipe) {}
            }
        }
        .padding()
    }
}
