//
//  RecipeListView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeListViewModel()
    @Environment(\.dismiss) private var dismiss

    private let aiService = AIService.shared
    let ingredients: [Ingredient]
    let onComplete: () -> Void

    init(ingredients: [Ingredient], onComplete: @escaping () -> Void = {}) {
        self.ingredients = ingredients
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasRecipes {
                    recipeContent
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onComplete()
                        dismiss()
                    }
                    .foregroundColor(.black)
                }

                if viewModel.hasRecipes {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await viewModel.refreshRecipes()
                            }
                        } label: {
                            if viewModel.isRefreshing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.black)
                            }
                        }
                        .disabled(viewModel.isRefreshing)
                    }
                }
            }
            .task {
                if viewModel.recipes.isEmpty {
                    await viewModel.generateRecipes(from: ingredients)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingRecipeDetail) {
                if let recipe = viewModel.selectedRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.1), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(Color.black, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: viewModel.progress)

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
            }

            VStack(spacing: 8) {
                Text("Generating Recipes")
                    .font(.headline)
                    .foregroundColor(.black)

                Text("This may take up to 60 seconds...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // MARK: - Recipe Content

    private var recipeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.recipeCount) Recipes Found")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("Based on \(ingredients.count) ingredients")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top)

                // Recipe Cards - Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recipes) { recipe in
                            RecipeCardView(recipe: recipe) {
                                viewModel.selectRecipe(recipe)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 320)

                // Recipe List (Vertical)
                VStack(alignment: .leading, spacing: 16) {
                    Text("All Recipes")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal)

                    ForEach(viewModel.recipes) { recipe in
                        RecipeRowView(recipe: recipe) {
                            viewModel.selectRecipe(recipe)
                        }
                    }
                }
                .padding(.top, 8)

                // Recipe Sources Section
                if !aiService.getLastTavilyResults().isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.vertical, 8)

                        Text("Recipe Sources")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)

                        ForEach(Array(Set(aiService.getLastTavilyResults().map { $0.url })).sorted().prefix(5), id: \.self) { urlString in
                            if let url = URL(string: urlString), let host = url.host {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "link.circle.fill")
                                            .foregroundColor(.blue)
                                        Text(host.replacingOccurrences(of: "www.", with: ""))
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Image(systemName: "arrow.up.forward")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Recipes Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Add more ingredients to generate recipes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Button {
                Task {
                    await viewModel.generateRecipes(from: ingredients)
                }
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(25)
            }
        }
        .padding()
    }
}

// MARK: - Recipe Row View

struct RecipeRowView: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Recipe Image Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))

                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)

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

                    if !recipe.tags.isEmpty {
                        Text(recipe.tags.prefix(3).joined(separator: " • "))
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
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
    RecipeListView(ingredients: [
        Ingredient(name: "Chicken breast"),
        Ingredient(name: "Garlic"),
        Ingredient(name: "Olive oil"),
        Ingredient(name: "Lemon")
    ])
}
