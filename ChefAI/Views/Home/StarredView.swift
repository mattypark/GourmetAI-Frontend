//
//  StarredView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct StarredView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Binding var refreshID: UUID

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if viewModel.likedRecipes.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "star")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("No starred recipes")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text("Recipes you like will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 16
                        ) {
                            ForEach(viewModel.likedRecipes) { recipe in
                                NavigationLink(value: recipe) {
                                    StarredRecipeCard(
                                        recipe: recipe,
                                        onUnlike: { viewModel.toggleRecipeLike(recipe) }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Starred")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, onToggleFavorite: {})
            }
            .id(refreshID)
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

// MARK: - Starred Recipe Card

struct StarredRecipeCard: View {
    let recipe: Recipe
    let onUnlike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe placeholder image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12)

                // Heart button
                Button(action: onUnlike) {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
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
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    @Previewable @State var refreshID = UUID()
    StarredView(refreshID: $refreshID)
}
