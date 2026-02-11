//
//  RecipeCardView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Section
                ZStack(alignment: .topTrailing) {
                    // Recipe Image or Placeholder
                    if let imageURL = recipe.imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                imagePlaceholder
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.gray.opacity(0.1))
                            @unknown default:
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }
                }
                .frame(height: 180)
                .clipped()

                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    // Recipe Name
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Meta Info
                    HStack(spacing: 16) {
                        // Time
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(recipe.totalTimeDisplay)
                                .font(.caption)
                        }
                        .foregroundColor(.gray)

                        // Difficulty
                        if let difficulty = recipe.difficulty {
                            HStack(spacing: 4) {
                                Image(systemName: difficulty.icon)
                                    .font(.caption)
                                Text(difficulty.rawValue)
                                    .font(.caption)
                            }
                            .foregroundColor(difficultyColor(difficulty))
                        }
                    }

                    // Tags
                    if !recipe.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(12)
            }
            .frame(width: 240)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray.opacity(0.4))

                if let cuisine = recipe.cuisineType {
                    Text(cuisine)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }
}

// MARK: - Large Recipe Card

struct LargeRecipeCardView: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Background Image
                if let imageURL = recipe.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            gradientPlaceholder
                        }
                    }
                } else {
                    gradientPlaceholder
                }

                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content Overlay
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()

                    // Recipe Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let description = recipe.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }

                        HStack(spacing: 20) {
                            Label(recipe.totalTimeDisplay, systemImage: "clock")
                            if let servings = recipe.servings {
                                Label("\(servings) servings", systemImage: "person.2")
                            }
                            if let difficulty = recipe.difficulty {
                                Label(difficulty.rawValue, systemImage: difficulty.icon)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            }
            .frame(height: 280)
            .cornerRadius(24)
            .clipped()
        }
        .buttonStyle(.plain)
    }

    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()

        VStack(spacing: 20) {
            RecipeCardView(
                recipe: Recipe(
                    name: "Garlic Butter Chicken",
                    description: "A delicious pan-seared chicken with garlic butter sauce",
                    tags: ["Quick Meals", "High Protein", "Keto"],
                    prepTime: 10,
                    cookTime: 20,
                    servings: 4,
                    difficulty: .easy,
                    cuisineType: "American"
                ),
                onTap: {}
            )

            LargeRecipeCardView(
                recipe: Recipe(
                    name: "Lemon Herb Salmon",
                    description: "Fresh salmon with a bright lemon herb topping",
                    tags: ["Healthy", "Seafood"],
                    prepTime: 5,
                    cookTime: 15,
                    servings: 2,
                    difficulty: .medium,
                    cuisineType: "Mediterranean"
                ),
                onTap: {}
            )
            .padding(.horizontal)
        }
    }
}
