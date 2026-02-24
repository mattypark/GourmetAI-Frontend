//
//  FavoritesView.swift
//  ChefAI
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var favoriteService = FavoriteService.shared
    @ObservedObject private var recipeJobService = RecipeJobService.shared
    @State private var selectedRecipe: Recipe?

    private var favoriteRecipes: [Recipe] {
        favoriteService.favoriteRecipes()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                if favoriteRecipes.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(favoriteRecipes) { recipe in
                                FavoriteRecipeRow(recipe: recipe) {
                                    selectedRecipe = recipe
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(item: $selectedRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))

            Text("No favorites yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.gray)

            Text("Tap the heart icon on any recipe to add it here")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)

            Spacer()
        }
    }
}

// MARK: - Favorite Recipe Row

struct FavoriteRecipeRow: View {
    let recipe: Recipe
    let onTap: () -> Void
    @ObservedObject private var favoriteService = FavoriteService.shared

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Recipe Image
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))

                    if let imageURL = recipe.imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Image(systemName: "fork.knife")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Recipe Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        Label(recipe.totalTimeDisplay, systemImage: "clock")
                        if let difficulty = recipe.difficulty {
                            Label(difficulty.rawValue, systemImage: difficulty.icon)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }

                Spacer()

                // Favorite button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        favoriteService.toggleFavorite(recipe.id)
                    }
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.black.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#Preview {
    FavoritesView()
}
