//
//  RecipeDetailView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss
    @State private var checkedIngredients: Set<UUID> = []
    @State private var completedSteps: Set<Int> = []
    @State private var showingShareSheet: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                heroImageSection

                // Content
                VStack(alignment: .leading, spacing: 24) {
                    // Title & Meta
                    titleSection

                    // Quick Stats
                    statsSection

                    Divider()
                        .background(Color.black.opacity(0.1))

                    // Nutrition Info
                    if let nutrition = recipe.nutritionPerServing, nutrition.hasMacros {
                        nutritionSection(nutrition)
                        Divider()
                            .background(Color.black.opacity(0.1))
                    }

                    // Ingredients
                    ingredientsSection

                    Divider()
                        .background(Color.black.opacity(0.1))

                    // Instructions
                    instructionsSection

                    // Tips
                    if !recipe.tips.isEmpty {
                        Divider()
                            .background(Color.black.opacity(0.1))
                        tipsSection
                    }

                    // Source
                    if let source = recipe.source {
                        sourceSection(source)
                    }
                }
                .padding()
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }

    // MARK: - Hero Image Section

    private var heroImageSection: some View {
        ZStack(alignment: .bottom) {
            if let imageURL = recipe.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        heroPlaceholder
                    }
                }
            } else {
                heroPlaceholder
            }

            // Gradient Overlay
            LinearGradient(
                colors: [.clear, .white.opacity(0.9)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .frame(height: 250)
        .clipped()
    }

    private var heroPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.05), Color.black.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 50))
                    .foregroundColor(.black.opacity(0.2))

                if let cuisine = recipe.cuisineType {
                    Text(cuisine)
                        .font(.headline)
                        .foregroundColor(.black.opacity(0.3))
                }
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)

            if let description = recipe.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.black.opacity(0.7))
            }

            // Tags
            if !recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recipe.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.08))
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(
                icon: "clock",
                value: recipe.totalTimeDisplay,
                label: "Total Time"
            )

            Divider()
                .frame(height: 40)
                .background(Color.black.opacity(0.1))

            if let servings = recipe.servings {
                statItem(
                    icon: "person.2",
                    value: "\(servings)",
                    label: "Servings"
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.black.opacity(0.1))
            }

            if let difficulty = recipe.difficulty {
                statItem(
                    icon: difficulty.icon,
                    value: difficulty.rawValue,
                    label: "Difficulty"
                )
            }
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.03))
        .cornerRadius(12)
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(value)
                    .font(.headline)
            }
            .foregroundColor(.black)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Nutrition Section

    private func nutritionSection(_ nutrition: NutritionInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition per Serving")
                .font(.headline)
                .foregroundColor(.black)

            HStack(spacing: 0) {
                if let calories = nutrition.calories {
                    nutritionItem(value: "\(calories)", unit: "cal", label: "Calories")
                }
                if let protein = nutrition.protein {
                    nutritionItem(value: "\(Int(protein))g", unit: "", label: "Protein")
                }
                if let carbs = nutrition.carbs {
                    nutritionItem(value: "\(Int(carbs))g", unit: "", label: "Carbs")
                }
                if let fat = nutrition.fat {
                    nutritionItem(value: "\(Int(fat))g", unit: "", label: "Fat")
                }
            }
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.03))
            .cornerRadius(12)
        }
    }

    private func nutritionItem(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value + unit)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                    .foregroundColor(.black)

                Spacer()

                Text("\(checkedIngredients.count)/\(recipe.ingredients.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
            }

            VStack(spacing: 4) {
                ForEach(recipe.ingredients) { ingredient in
                    ingredientRow(ingredient)
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
    }

    private func ingredientRow(_ ingredient: RecipeIngredient) -> some View {
        let isChecked = checkedIngredients.contains(ingredient.id)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                toggleIngredient(ingredient)
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox with animation
                ZStack {
                    Circle()
                        .stroke(isChecked ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isChecked {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isChecked ? 1.0 : 1.0)

                // Ingredient text
                Text(ingredient.displayText)
                    .font(.body)
                    .foregroundColor(isChecked ? .gray : .black)
                    .strikethrough(isChecked, color: .gray)

                Spacer()

                // Optional badge
                if ingredient.isOptional {
                    Text("Optional")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleIngredient(_ ingredient: RecipeIngredient) {
        if checkedIngredients.contains(ingredient.id) {
            checkedIngredients.remove(ingredient.id)
        } else {
            checkedIngredients.insert(ingredient.id)
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.headline)
                .foregroundColor(.black)

            if recipe.hasDetailedSteps {
                // Detailed steps with techniques
                ForEach(recipe.detailedSteps) { step in
                    RecipeStepView(
                        step: step,
                        isCompleted: completedSteps.contains(step.stepNumber),
                        onToggle: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                toggleStep(step.stepNumber)
                            }
                        }
                    )
                }
            } else {
                // Simple instructions
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    simpleStepRow(index: index + 1, instruction: instruction)
                }
            }
        }
    }

    private func simpleStepRow(index: Int, instruction: String) -> some View {
        let isCompleted = completedSteps.contains(index)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                toggleStep(index)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Step number
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.black.opacity(0.08))
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(index)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                }

                // Instruction text
                Text(instruction)
                    .font(.body)
                    .foregroundColor(isCompleted ? .gray : .black)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func toggleStep(_ stepNumber: Int) {
        if completedSteps.contains(stepNumber) {
            completedSteps.remove(stepNumber)
        } else {
            completedSteps.insert(stepNumber)
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("Chef's Tips")
                    .font(.headline)
                    .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(recipe.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.orange)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - Source Section

    private func sourceSection(_ source: RecipeSource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source")
                .font(.caption)
                .foregroundColor(.gray)

            Text(source.attribution)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))

            if let url = source.url, let link = URL(string: url) {
                Link(destination: link) {
                    HStack {
                        Text("View Original")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Share

    private var shareText: String {
        var text = "Check out this recipe: \(recipe.name)"
        if let description = recipe.description {
            text += "\n\(description)"
        }
        text += "\n\nGenerated by ChefAI"
        return text
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    RecipeDetailView(
        recipe: Recipe(
            name: "Garlic Butter Chicken",
            description: "A delicious pan-seared chicken with garlic butter sauce that's perfect for weeknight dinners.",
            instructions: [
                "Season chicken breasts with salt and pepper",
                "Heat olive oil in a large skillet over medium-high heat",
                "Add chicken and cook 6-7 minutes per side until golden",
                "Remove chicken and set aside",
                "Add butter and garlic to the pan",
                "Return chicken to pan and spoon sauce over",
                "Garnish with fresh parsley and serve"
            ],
            ingredients: [
                RecipeIngredient(name: "Chicken breast", amount: "2", unit: "lbs"),
                RecipeIngredient(name: "Garlic cloves", amount: "4", unit: "minced"),
                RecipeIngredient(name: "Butter", amount: "3", unit: "tbsp"),
                RecipeIngredient(name: "Olive oil", amount: "2", unit: "tbsp"),
                RecipeIngredient(name: "Fresh parsley", amount: "2", unit: "tbsp", isOptional: true)
            ],
            tags: ["Quick Meals", "High Protein", "Keto"],
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            difficulty: .easy,
            cuisineType: "American",
            nutritionPerServing: NutritionInfo(calories: 350, protein: 42, carbs: 2, fat: 18),
            tips: [
                "Let the chicken rest for 5 minutes before slicing",
                "Don't move the chicken while it's searing for best browning",
                "Use room temperature chicken for more even cooking"
            ],
            source: RecipeSource(name: "ChefAI Generated", author: "ChefAI")
        )
    )
}
