//
//  AnalysisResultView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct AnalysisResultView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isCompleting = false
    @State private var showingRecipeList = false
    @State private var selectedIngredients: Set<UUID> = []
    @State private var editingIngredient: Ingredient?
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if let result = viewModel.analysisResult {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Image thumbnail
                            if let thumbnailImage = result.thumbnailImage {
                                Image(uiImage: thumbnailImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 180)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.1), radius: 8)
                            }

                            // Summary Stats
                            summarySection(result)

                            // Detected Ingredients
                            if !result.extractedIngredients.isEmpty {
                                ingredientsSection(result.extractedIngredients)
                            }

                            // Manual Items
                            if !result.manuallyAddedItems.isEmpty {
                                manualItemsSection(result.manuallyAddedItems)
                            }

                            // Add Missing Ingredients
                            addMissingSection

                            // Action Buttons
                            actionButtons(result)
                        }
                        .padding()
                        .padding(.bottom, 32)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                        dismiss()
                    }
                    .foregroundColor(.black)
                }

                ToolbarItem(placement: .primaryAction) {
                    if let result = viewModel.analysisResult, !result.extractedIngredients.isEmpty {
                        Button {
                            selectAllIngredients(result.extractedIngredients)
                        } label: {
                            Text(allSelected(result.extractedIngredients) ? "Deselect All" : "Select All")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingRecipeList) {
                if let result = viewModel.analysisResult {
                    RecipeListView(
                        ingredients: selectedIngredientsArray(from: result),
                        onComplete: {
                            dismiss()
                        }
                    )
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let ingredient = editingIngredient {
                    IngredientEditSheet(
                        ingredient: ingredient,
                        onSave: { updated in
                            updateIngredient(updated)
                        }
                    )
                }
            }
            .onAppear {
                // Select all ingredients by default
                if let result = viewModel.analysisResult {
                    selectedIngredients = Set(result.extractedIngredients.map { $0.id })
                }
            }
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ result: AnalysisResult) -> some View {
        HStack(spacing: 24) {
            summaryItem(
                icon: "carrot.fill",
                value: "\(result.extractedIngredients.count)",
                label: "Ingredients"
            )

            summaryItem(
                icon: "hand.tap.fill",
                value: "\(result.manuallyAddedItems.count)",
                label: "Added"
            )

            summaryItem(
                icon: "checkmark.circle.fill",
                value: "\(selectedIngredients.count)",
                label: "Selected"
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    private func summaryItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.green)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ingredients Section

    private func ingredientsSection(_ ingredients: [Ingredient]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detected Ingredients")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(selectedIngredients.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(ingredients) { ingredient in
                    ingredientRow(ingredient)
                }
            }
        }
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack(spacing: 12) {
            // Selection Checkbox
            Button {
                toggleSelection(ingredient)
            } label: {
                Image(systemName: selectedIngredients.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectedIngredients.contains(ingredient.id) ? .green : .gray.opacity(0.5))
            }

            // Ingredient Info
            VStack(alignment: .leading, spacing: 4) {
                // Name with brand
                HStack {
                    Text(ingredient.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let brand = ingredient.brandName, !brand.isEmpty {
                        Text("(\(brand))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Category and quantity
                HStack(spacing: 12) {
                    if let category = ingredient.category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.caption2)
                            Text(category.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let qty = ingredient.quantityDisplay {
                        Text(qty)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Nutrition info if available
                if let nutrition = ingredient.nutritionInfo, nutrition.hasMacros {
                    Text(nutrition.macrosSummary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Confidence Badge
            if let confidence = ingredient.confidence {
                VStack {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(confidenceColor(confidence))
                }
            }

            // Edit Button
            Button {
                editingIngredient = ingredient
                showingEditSheet = true
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            selectedIngredients.contains(ingredient.id)
                ? Color.green.opacity(0.1)
                : Color.gray.opacity(0.08)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedIngredients.contains(ingredient.id)
                        ? Color.green.opacity(0.3)
                        : Color.gray.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.5 { return .yellow }
        return .red
    }

    // MARK: - Manual Items Section

    private func manualItemsSection(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manually Added")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(items, id: \.self) { item in
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text(item)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Add Missing Section

    private var addMissingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Missing Anything?")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Add ingredients we may have missed")
                .font(.caption)
                .foregroundColor(.secondary)

            ManualItemInputView(viewModel: viewModel)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ result: AnalysisResult) -> some View {
        VStack(spacing: 16) {
            // Generate Recipes Button
            PrimaryButton(
                title: "Generate \(selectedIngredients.count > 0 ? "\(selectedIngredients.count) " : "")Recipes",
                action: {
                    Task {
                        // Generate recipes first with selected ingredients
                        await viewModel.generateRecipesWithSelectedIngredients(
                            selectedIngredientsArray(from: result)
                        )

                        // Only proceed if recipes were generated successfully
                        if viewModel.analysisResult?.suggestedRecipes.isEmpty == false {
                            // Save analysis with recipes
                            await viewModel.completeAnalysis()
                            // Then navigate to recipe list
                            showingRecipeList = true
                        }
                    }
                },
                isLoading: viewModel.isGeneratingRecipes
            )
            .disabled(selectedIngredients.isEmpty || viewModel.isGeneratingRecipes)
            .opacity(selectedIngredients.isEmpty ? 0.5 : 1)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // Skip hint
            Text("Recipes will use only selected ingredients")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow)

            Text("No Results")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Unable to analyze the image. Please try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func toggleSelection(_ ingredient: Ingredient) {
        if selectedIngredients.contains(ingredient.id) {
            selectedIngredients.remove(ingredient.id)
        } else {
            selectedIngredients.insert(ingredient.id)
        }
    }

    private func selectAllIngredients(_ ingredients: [Ingredient]) {
        if allSelected(ingredients) {
            selectedIngredients.removeAll()
        } else {
            selectedIngredients = Set(ingredients.map { $0.id })
        }
    }

    private func allSelected(_ ingredients: [Ingredient]) -> Bool {
        ingredients.allSatisfy { selectedIngredients.contains($0.id) }
    }

    private func selectedIngredientsArray(from result: AnalysisResult) -> [Ingredient] {
        var ingredients = result.extractedIngredients.filter { selectedIngredients.contains($0.id) }

        // Add manual items as ingredients
        let manualIngredients = result.manuallyAddedItems.map { Ingredient(name: $0) }
        ingredients.append(contentsOf: manualIngredients)

        return ingredients
    }

    private func updateIngredient(_ ingredient: Ingredient) {
        // Update in viewModel's analysis result
        // This is a simplified version - full implementation would update the actual result
    }
}

// MARK: - Ingredient Edit Sheet

struct IngredientEditSheet: View {
    let ingredient: Ingredient
    let onSave: (Ingredient) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var brandName: String
    @State private var quantity: String
    @State private var selectedCategory: IngredientCategory

    init(ingredient: Ingredient, onSave: @escaping (Ingredient) -> Void) {
        self.ingredient = ingredient
        self.onSave = onSave
        _name = State(initialValue: ingredient.name)
        _brandName = State(initialValue: ingredient.brandName ?? "")
        _quantity = State(initialValue: ingredient.quantity ?? "")
        _selectedCategory = State(initialValue: ingredient.category ?? .other)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient Details") {
                    TextField("Name", text: $name)
                    TextField("Brand (optional)", text: $brandName)
                    TextField("Quantity", text: $quantity)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = ingredient
                        updated.name = name
                        updated.brandName = brandName.isEmpty ? nil : brandName
                        updated.quantity = quantity.isEmpty ? nil : quantity
                        updated.category = selectedCategory
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    @Previewable @StateObject var viewModel = CameraViewModel()
    AnalysisResultView(viewModel: viewModel)
}
