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

    @State private var selectedIngredients: Set<UUID> = []
    @State private var showingAllIngredients = false
    @State private var editingIngredient: Ingredient?
    @State private var showingEditSheet = false
    @State private var showingRecipeList = false
    @State private var showingAddMore = false
    @State private var showingAuthSheet = false

    private let maxVisibleIngredients = 6

    // Light gray background color (explicit, not system-adaptive)
    private let lightGrayBackground = Color(red: 230/255, green: 230/255, blue: 230/255)

    var body: some View {
        ZStack {
            // Light gray background (explicit color, ignores dark mode)
            lightGrayBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                if let result = viewModel.analysisResult {
                    // Main content - fills available space
                    ScrollView {
                        VStack(spacing: 20) {
                            // Image preview (smaller)
                            if let thumbnailImage = result.thumbnailImage {
                                Image(uiImage: thumbnailImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(16)
                                    .padding(.horizontal, 24)
                            }

                            // Stats row
                            statsRow(result)
                                .padding(.horizontal, 24)

                            // Ingredients list
                            ingredientsList(result.extractedIngredients)
                                .padding(.horizontal, 24)

                            // See more / Add more button
                            if showingAllIngredients {
                                Button {
                                    showingAddMore = true
                                } label: {
                                    Text("Add more")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 8)
                            } else if result.extractedIngredients.count > maxVisibleIngredients {
                                Button {
                                    withAnimation {
                                        showingAllIngredients = true
                                    }
                                } label: {
                                    Text("See more")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }

                    // Bottom buttons - pinned to bottom
                    bottomButtonsView(result)
                } else {
                    Spacer()
                    emptyState
                    Spacer()
                }
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
        .sheet(isPresented: $showingAddMore) {
            AddMoreIngredientsSheet(viewModel: viewModel)
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
        .sheet(isPresented: $showingAuthSheet) {
            AuthenticationView(onSuccess: {
                // After successful auth, retry save
                Task {
                    await viewModel.saveAnalysisOnly()
                    if !viewModel.needsAuthentication {
                        dismiss()
                    }
                }
            })
        }
        .onChange(of: viewModel.needsAuthentication) { _, needsAuth in
            if needsAuth {
                showingAuthSheet = true
                viewModel.needsAuthentication = false
            }
        }
        .onAppear {
            // Select all ingredients by default
            if let result = viewModel.analysisResult {
                selectedIngredients = Set(result.extractedIngredients.map { $0.id })
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                viewModel.cancel()
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Chef AI")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Stats Row

    private func statsRow(_ result: AnalysisResult) -> some View {
        HStack(spacing: 0) {
            // Ingredients count
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("🥕")
                        .font(.title3)
                    Text("\(result.extractedIngredients.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                Text("Ingredients")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)

            // Manually added count
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("➕")
                        .font(.title3)
                    Text("\(result.manuallyAddedItems.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                Text("Added")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)

            // Selected count
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .foregroundColor(.black)
                    Text("\(selectedIngredients.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                Text("Selected")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Ingredients List

    private func ingredientsList(_ ingredients: [Ingredient]) -> some View {
        let displayIngredients = showingAllIngredients
            ? ingredients
            : Array(ingredients.prefix(maxVisibleIngredients))

        return VStack(spacing: 0) {
            ForEach(displayIngredients) { ingredient in
                ingredientRow(ingredient)

                if ingredient.id != displayIngredients.last?.id {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                toggleSelection(ingredient)
            } label: {
                Image(systemName: selectedIngredients.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectedIngredients.contains(ingredient.id) ? .black : .gray.opacity(0.4))
            }

            // Ingredient info
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.black)

                HStack(spacing: 4) {
                    if let category = ingredient.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    if let qty = ingredient.quantityDisplay {
                        Text("|")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(qty)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            // Confidence percentage
            if let confidence = ingredient.confidence {
                Text("\(Int(confidence * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Edit button
            Button {
                editingIngredient = ingredient
                showingEditSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Bottom Buttons

    private func bottomButtonsView(_ result: AnalysisResult) -> some View {
        HStack(spacing: 12) {
            // Save button
            Button {
                Task {
                    await viewModel.saveAnalysisOnly()
                    dismiss()
                }
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 80, height: 56)
                    .background(Color.white)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // Create Recipes button - starts background job and returns to home
            Button {
                // Get selected ingredients
                let selectedIngredientsList = selectedIngredientsArray(from: result)

                // Start background recipe generation job
                RecipeJobService.shared.startRecipeGeneration(
                    analysisId: result.id,
                    ingredients: selectedIngredientsList,
                    thumbnailData: result.imageData
                )

                // Save the analysis
                Task {
                    await viewModel.saveAnalysisOnly()
                }

                // Dismiss back to home - the job will show progress there
                dismiss()
            } label: {
                Text("Create Recipes")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
            }
            .disabled(selectedIngredients.isEmpty)
            .opacity(selectedIngredients.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(lightGrayBackground)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow)

            Text("No Results")
                .font(.headline)
                .foregroundColor(.black)

            Text("Unable to analyze the image. Please try again.")
                .font(.subheadline)
                .foregroundColor(.gray)
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

    private func selectedIngredientsArray(from result: AnalysisResult) -> [Ingredient] {
        var ingredients = result.extractedIngredients.filter { selectedIngredients.contains($0.id) }
        let manualIngredients = result.manuallyAddedItems.map { Ingredient(name: $0) }
        ingredients.append(contentsOf: manualIngredients)
        return ingredients
    }

    private func updateIngredient(_ ingredient: Ingredient) {
        // Update in viewModel's analysis result
    }
}

// MARK: - Add More Ingredients Sheet

struct AddMoreIngredientsSheet: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter ingredient name", text: $viewModel.currentManualItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button {
                    viewModel.addManualItem()
                } label: {
                    Text("Add Ingredient")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .disabled(viewModel.currentManualItem.isEmpty)

                // Show added items
                if !viewModel.manualItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Added:")
                            .font(.caption)
                            .foregroundColor(.gray)

                        ForEach(viewModel.manualItems, id: \.self) { item in
                            HStack {
                                Text(item)
                                Spacer()
                                Button {
                                    if let index = viewModel.manualItems.firstIndex(of: item) {
                                        viewModel.removeManualItem(at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
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
                }
            }
        }
        .presentationDetents([.medium])
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
