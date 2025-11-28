//
//  HomeView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.analyses.isEmpty && viewModel.likedRecipes.isEmpty {
                    // Empty state
                    EmptyStateView(
                        icon: "camera.fill",
                        title: "No analyses yet",
                        message: "Tap the + button to analyze your fridge"
                    )
                } else {
                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            // Recent Analyses
                            if !viewModel.analyses.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recent Analyses")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.analyses) { analysis in
                                                NavigationLink(value: analysis) {
                                                    AnalysisCardView(analysis: analysis)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            // Liked Recipes
                            if !viewModel.likedRecipes.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Liked Recipes")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)

                                    LazyVGrid(
                                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                                        spacing: 16
                                    ) {
                                        ForEach(viewModel.likedRecipes) { recipe in
                                            NavigationLink(value: recipe) {
                                                LikedRecipeCardView(
                                                    recipe: recipe,
                                                    onLike: { viewModel.toggleRecipeLike(recipe) }
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Saved Recipe Images
                            if !viewModel.savedRecipeImages.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Saved Images")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)

                                    SavedRecipeImagesView(recipes: viewModel.savedRecipeImages)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("ChefAI")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: AnalysisResult.self) { analysis in
                AnalysisDetailView(analysis: analysis)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}

#Preview {
    HomeView()
}
