//
//  AnalysisDetailView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct AnalysisDetailView: View {
    let analysis: AnalysisResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Fridge Photo
                if let imageData = analysis.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(color: .white.opacity(0.1), radius: 8)
                }

                // Analysis Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Date")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(analysis.date.formatted())
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(analysis.ingredientSummary)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .cardStyle()

                // Ingredients Section
                IngredientListView(
                    ingredients: analysis.extractedIngredients,
                    manualItems: analysis.manuallyAddedItems
                )

                // Suggested Recipes
                if !analysis.suggestedRecipes.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Suggested Recipes")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(analysis.suggestedRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCardPreview(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Fridge Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }
}

// MARK: - Recipe Card Preview

struct RecipeCardPreview: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        if let prepTime = recipe.prepTime, let cookTime = recipe.cookTime {
                            Label("\(prepTime + cookTime) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        if let servings = recipe.servings {
                            Label("\(servings) servings", systemImage: "person.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        if let difficulty = recipe.difficulty {
                            Label(difficulty.rawValue, systemImage: difficulty.icon)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }

            // Tags
            if !recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipe.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        AnalysisDetailView(
            analysis: AnalysisResult(
                extractedIngredients: [
                    Ingredient(name: "Eggs", category: .dairy, confidence: 0.95),
                    Ingredient(name: "Milk", category: .dairy, confidence: 0.92)
                ],
                suggestedRecipes: [
                    Recipe(
                        name: "Veggie Omelet",
                        instructions: ["Beat eggs", "Cook"],
                        ingredients: [],
                        tags: ["Breakfast", "Quick"],
                        prepTime: 5,
                        cookTime: 8,
                        servings: 1,
                        difficulty: .easy
                    )
                ],
                manuallyAddedItems: ["Butter"]
            )
        )
    }
}
