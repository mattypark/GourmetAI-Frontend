//
//  RecipeDetailView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI
import PhotosUI

struct RecipeDetailView: View {
    @StateObject private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recipe Image (placeholder or saved)
                recipeImageSection

                // Recipe Info
                recipeInfoSection

                // Ingredients
                ingredientsSection

                // Instructions
                instructionsSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(viewModel.recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.toggleLike() }) {
                    Image(systemName: viewModel.recipe.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.recipe.isLiked ? .red : .white)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSaveImagePicker) {
            ImagePicker(
                sourceType: .photoLibrary,
                selectedImage: .constant(nil),
                onImageSelected: { image in
                    if let imageData = image.jpegData(compressionQuality: 0.7) {
                        viewModel.saveRecipeImage(imageData)
                    }
                }
            )
        }
    }

    // MARK: - Image Section

    private var recipeImageSection: some View {
        VStack(spacing: 16) {
            if let imageData = viewModel.recipe.savedImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .shadow(color: .white.opacity(0.1), radius: 8)
            } else {
                // Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 200)

                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)

                        Text("No Image")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Button("Add Recipe Photo") {
                            viewModel.showingSaveImagePicker = true
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Info Section

    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time & Servings
            HStack(spacing: 24) {
                if let prepTime = viewModel.recipe.prepTime {
                    InfoBadge(icon: "clock", text: "\(prepTime) min prep")
                }

                if let cookTime = viewModel.recipe.cookTime {
                    InfoBadge(icon: "flame", text: "\(cookTime) min cook")
                }

                if let servings = viewModel.recipe.servings {
                    InfoBadge(icon: "person.2", text: "\(servings) servings")
                }
            }

            // Difficulty
            if let difficulty = viewModel.recipe.difficulty {
                HStack {
                    Image(systemName: difficulty.icon)
                        .foregroundColor(.white)
                    Text(difficulty.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

            // Tags
            if !viewModel.recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.recipe.tags, id: \.self) { tag in
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

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            ForEach(viewModel.recipe.ingredients, id: \.name) { ingredient in
                HStack {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(ingredient.displayText)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            ForEach(Array(viewModel.recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(14)

                    Text(instruction)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.vertical, 8)

                if index < viewModel.recipe.instructions.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Info Badge

struct InfoBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.gray)
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(
            recipe: Recipe(
                name: "Chicken Stir Fry",
                instructions: [
                    "Cut chicken into bite-sized pieces",
                    "Heat oil in a wok",
                    "Cook chicken until golden",
                    "Add vegetables and stir fry",
                    "Season and serve"
                ],
                ingredients: [
                    RecipeIngredient(name: "Chicken Breast", amount: "1", unit: "lb"),
                    RecipeIngredient(name: "Soy Sauce", amount: "2", unit: "tbsp")
                ],
                tags: ["Quick Meals", "High-Protein"],
                prepTime: 10,
                cookTime: 15,
                servings: 4,
                difficulty: .easy
            )
        )
    }
}
