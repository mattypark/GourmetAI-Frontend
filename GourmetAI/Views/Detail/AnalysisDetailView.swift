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

    @State private var manualItems: [String] = []
    @State private var currentManualItem = ""
    @State private var showingAddIngredients = false
    @State private var showingRecipeTypeSelection = false

    private var allIngredients: [Ingredient] {
        let manualIngredients = (analysis.manuallyAddedItems + manualItems).map { Ingredient(name: $0) }
        return analysis.extractedIngredients + manualIngredients
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Fridge Photo(s)
                    let thumbnails = analysis.thumbnailImages
                    if thumbnails.count == 1, let img = thumbnails.first {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8)
                    } else if thumbnails.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipped()
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.1), radius: 8)
                                }
                            }
                        }
                    }

                    // Analysis Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Date")
                            .font(.headline)
                            .foregroundColor(.black)

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
                        manualItems: analysis.manuallyAddedItems + manualItems
                    )

                    // Suggested Recipes
                    if !analysis.suggestedRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Suggested Recipes")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
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
                .padding(.bottom, 24)
            }

            // Bottom action buttons
            HStack(spacing: 12) {
                // Add Ingredients button
                Button {
                    showingAddIngredients = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Ingredients")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(Color.theme.background)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }

                // Create Recipes button
                Button {
                    showingRecipeTypeSelection = true
                } label: {
                    Text("Create Recipes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .background(Color.theme.background)
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle("Fridge Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showingAddIngredients) {
            AddIngredientsFromDetailSheet(
                manualItems: $manualItems,
                currentManualItem: $currentManualItem
            )
        }
        .fullScreenCover(isPresented: $showingRecipeTypeSelection) {
            RecipeTypeSelectionView(
                ingredients: allIngredients,
                analysisId: analysis.id,
                thumbnailData: analysis.imageData,
                onDismiss: {
                    showingRecipeTypeSelection = false
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Add Ingredients Sheet (for saved analyses)

struct AddIngredientsFromDetailSheet: View {
    @Binding var manualItems: [String]
    @Binding var currentManualItem: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    TextField("Enter ingredient name", text: $currentManualItem)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .onChange(of: currentManualItem) { _, newValue in
                            if newValue.count > 100 {
                                currentManualItem = String(newValue.prefix(100))
                            }
                        }
                        .onSubmit {
                            addItem()
                        }

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    .disabled(currentManualItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(currentManualItem.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)

                if !manualItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(manualItems.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.gray)

                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Button {
                                    manualItems.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Add Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.black)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addItem() {
        let trimmed = currentManualItem
            .trimmingCharacters(in: .whitespaces)
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace || $0.isPunctuation }
        guard !trimmed.isEmpty, manualItems.count < AppConstants.maxManualItems else { return }
        manualItems.append(trimmed)
        currentManualItem = ""
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
                        .foregroundColor(.black)

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
                                .background(Color.black.opacity(0.05))
                                .foregroundColor(.black)
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
