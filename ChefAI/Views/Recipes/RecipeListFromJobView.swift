//
//  RecipeListFromJobView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-20.
//

import SwiftUI

struct RecipeListFromJobView: View {
    @Environment(\.dismiss) private var dismiss
    let job: RecipeJob
    @State private var selectedRecipe: Recipe?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if job.recipes.isEmpty {
                    emptyStateView
                } else {
                    recipeContent
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .fullScreenCover(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }

    // MARK: - Recipe Content

    private var recipeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(job.recipes.count) Recipes Found")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("Based on \(job.ingredients.count) ingredients")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if job.sourceCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text("From \(job.sourceCount) web sources")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Recipe Cards - Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(job.recipes) { recipe in
                            RecipeCardView(recipe: recipe) {
                                selectedRecipe = recipe
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

                    ForEach(job.recipes) { recipe in
                        RecipeRowView(recipe: recipe) {
                            selectedRecipe = recipe
                        }
                    }
                }
                .padding(.top, 8)

                // Sources Section
                if !job.sources.isEmpty {
                    sourcesSection
                }
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Sources Section

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Sources")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(job.sources.prefix(5)) { source in
                    Link(destination: URL(string: source.url) ?? URL(string: "https://google.com")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.name)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .lineLimit(1)

                                Text(source.domain)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 16)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Recipes Available")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                if let error = job.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Something went wrong while generating recipes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
}

// MARK: - Recipe Row View (if not already defined elsewhere)

struct RecipeRowViewFromJob: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Recipe Image Placeholder
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
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Image(systemName: "photo")
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

                    // Source info
                    if let source = recipe.source {
                        Text("From: \(source.name)")
                            .font(.caption2)
                            .foregroundColor(.blue)
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
    RecipeListFromJobView(
        job: {
            var job = RecipeJob(
                analysisId: UUID(),
                ingredients: ["chicken", "garlic", "olive oil", "lemon"],
                thumbnailData: nil
            )
            job.status = .finished
            job.sourceCount = 7
            job.sources = [
                RecipeSourceInfo(name: "Easy Garlic Chicken", url: "https://allrecipes.com/garlic-chicken", domain: "allrecipes.com"),
                RecipeSourceInfo(name: "Lemon Herb Chicken", url: "https://foodnetwork.com/lemon-chicken", domain: "foodnetwork.com")
            ]
            job.recipes = [
                Recipe(
                    name: "Garlic Butter Chicken",
                    description: "A delicious pan-seared chicken with garlic butter sauce",
                    tags: ["Quick Meals", "High Protein"],
                    prepTime: 10,
                    cookTime: 20,
                    servings: 4,
                    difficulty: .easy,
                    cuisineType: "American"
                ),
                Recipe(
                    name: "Lemon Herb Roasted Chicken",
                    description: "Fresh and zesty roasted chicken",
                    tags: ["Healthy", "Family Dinner"],
                    prepTime: 15,
                    cookTime: 45,
                    servings: 6,
                    difficulty: .medium,
                    cuisineType: "Mediterranean"
                )
            ]
            return job
        }()
    )
}
