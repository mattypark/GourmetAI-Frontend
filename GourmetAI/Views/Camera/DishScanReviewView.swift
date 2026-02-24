//
//  DishScanReviewView.swift
//  ChefAI
//
//  Single-image review + analysis screen for "Identify a Dish" mode.
//  User confirms the photo, taps "Identify Dish", sees a loading overlay,
//  then is taken directly to a full RecipeDetailView for the identified dish.
//

import SwiftUI

struct DishScanReviewView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "FBFFF1").ignoresSafeArea()

            VStack(spacing: 0) {
                headerView.padding(.top, 34)

                if let image = cameraViewModel.selectedImages.first {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Photo preview
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                                .clipped()
                                .cornerRadius(20)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            // Hint text
                            VStack(spacing: 6) {
                                Text("Ready to identify this dish?")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text("AI will analyze the image and generate a detailed recipe with exact techniques, temperatures, and step-by-step instructions.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 120)
                    }
                } else {
                    Spacer()
                    Text("No image selected")
                        .foregroundColor(.gray)
                    Spacer()
                }

                // Bottom button
                VStack(spacing: 12) {
                    if let error = cameraViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    Button {
                        Task { await cameraViewModel.analyzeDishFromImage() }
                    } label: {
                        Text("Identify Dish")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(cameraViewModel.selectedImages.isEmpty ? Color.gray : Color.black)
                            .cornerRadius(28)
                    }
                    .disabled(cameraViewModel.selectedImages.isEmpty || cameraViewModel.isAnalyzing)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(Color(hex: "FBFFF1"))
            }

            // Loading overlay
            if cameraViewModel.isAnalyzing {
                dishLoadingOverlay
            }
        }
        .fullScreenCover(isPresented: $cameraViewModel.showingDishScanResult) {
            if let recipe = cameraViewModel.dishScanResult {
                DishScanResultView(
                    recipe: recipe,
                    dishName: cameraViewModel.dishScanName,
                    thumbnailImage: cameraViewModel.selectedImages.first,
                    onDismiss: {
                        cameraViewModel.resetAfterAnalysis()
                        onDismiss()
                    }
                )
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                cameraViewModel.cancel()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "F5F5F5"))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Identify Dish")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Loading Overlay

    private var dishLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.6)

                Text("Identifying dish...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Analyzing ingredients and building your recipe")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: max(geo.size.width * cameraViewModel.analysisProgress, 8), height: 6)
                            .animation(.easeInOut(duration: 0.3), value: cameraViewModel.analysisProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 40)
            }
            .padding(40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: cameraViewModel.isAnalyzing)
    }
}

// MARK: - Dish Scan Result View

struct DishScanResultView: View {
    let recipe: Recipe
    let dishName: String
    let thumbnailImage: UIImage?
    let onDismiss: () -> Void

    @State private var completedSteps: Set<UUID> = []
    @State private var activeTab: DishTab = .steps

    enum DishTab: String, CaseIterable {
        case steps = "Steps"
        case ingredients = "Ingredients"
        case nutrition = "Nutrition"
    }

    var body: some View {
        ZStack {
            Color(hex: "FBFFF1").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero image
                        if let img = thumbnailImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        colors: [.clear, Color.black.opacity(0.5)],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                )
                        }

                        // Dish name + meta
                        VStack(alignment: .leading, spacing: 12) {
                            Text(dishName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            if let desc = recipe.description {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Meta pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if let prep = recipe.prepTime {
                                        metaPill(icon: "clock", text: "Prep \(prep)m")
                                    }
                                    if let cook = recipe.cookTime {
                                        metaPill(icon: "flame", text: "Cook \(cook)m")
                                    }
                                    if let servings = recipe.servings {
                                        metaPill(icon: "person.2", text: "\(servings) servings")
                                    }
                                    if let diff = recipe.difficulty {
                                        metaPill(icon: "chart.bar", text: diff.rawValue)
                                    }
                                    if let cuisine = recipe.cuisineType {
                                        metaPill(icon: "globe", text: cuisine)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                        // Tab bar
                        HStack(spacing: 0) {
                            ForEach(DishTab.allCases, id: \.self) { tab in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        activeTab = tab
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(tab.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(activeTab == tab ? .semibold : .regular)
                                            .foregroundColor(activeTab == tab ? .black : .gray)
                                        Rectangle()
                                            .fill(activeTab == tab ? Color.black : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        Divider().padding(.horizontal, 20)

                        // Tab content
                        Group {
                            switch activeTab {
                            case .steps:
                                stepsTab
                            case .ingredients:
                                ingredientsTab
                            case .nutrition:
                                nutritionTab
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "F5F5F5"))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Dish Recipe")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Steps Tab

    private var stepsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            let steps = recipe.detailedSteps.isEmpty ? recipe.instructions.enumerated().map { (i, text) in
                RecipeStep(stepNumber: i + 1, instruction: text)
            } : recipe.detailedSteps

            ForEach(steps) { step in
                RecipeStepView(
                    step: step,
                    isCompleted: completedSteps.contains(step.id),
                    onToggle: {
                        if completedSteps.contains(step.id) {
                            completedSteps.remove(step.id)
                        } else {
                            completedSteps.insert(step.id)
                        }
                    }
                )
            }

            if !recipe.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pro Tips")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top, 8)

                    ForEach(recipe.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    // MARK: - Ingredients Tab

    private var ingredientsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(recipe.ingredients) { ingredient in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 6, height: 6)

                    Text(ingredient.name)
                        .font(.body)
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(ingredient.amount)\(ingredient.unit.map { " \($0)" } ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if ingredient.isOptional {
                        Text("optional")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 12)

                if ingredient.id != recipe.ingredients.last?.id {
                    Divider()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Nutrition Tab

    private var nutritionTab: some View {
        Group {
            if let n = recipe.nutritionPerServing {
                VStack(spacing: 16) {
                    Text("Per Serving")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        if let cal = n.calories {
                            nutritionCard(label: "Calories", value: "\(cal)", unit: "kcal", color: .orange)
                        }
                        if let protein = n.protein {
                            nutritionCard(label: "Protein", value: String(format: "%.1f", protein), unit: "g", color: .blue)
                        }
                        if let carbs = n.carbs {
                            nutritionCard(label: "Carbs", value: String(format: "%.1f", carbs), unit: "g", color: .green)
                        }
                        if let fat = n.fat {
                            nutritionCard(label: "Fat", value: String(format: "%.1f", fat), unit: "g", color: .purple)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Nutrition info not available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
    }

    private func nutritionCard(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(unit)
                .font(.caption)
                .foregroundColor(.gray)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }
}
