//
//  RecipeTypeSelectionView.swift
//  ChefAI
//

import SwiftUI

// MARK: - Scan Intent

enum ScanIntent: CaseIterable {
    case findRecipes   // raw ingredients → recipe ideas
    case identifyDish  // cooked meal photo → identify dish + ingredients

    var title: String {
        switch self {
        case .findRecipes:  return "Find recipes from ingredients"
        case .identifyDish: return "Identify a cooked dish"
        }
    }

    var subtitle: String {
        switch self {
        case .findRecipes:  return "Turn your raw ingredients into recipe ideas"
        case .identifyDish: return "Recognize a dish and break down its ingredients"
        }
    }

    var icon: String {
        switch self {
        case .findRecipes:  return "carrot.fill"
        case .identifyDish: return "fork.knife"
        }
    }
}

// MARK: - RecipeTypeSelectionView (Step 1: intent)

struct RecipeTypeSelectionView: View {
    let ingredients: [Ingredient]
    let analysisId: UUID
    let thumbnailData: Data?
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIntent: ScanIntent? = nil
    @State private var showingRecipeTypePicker = false

    private let deepOlive = Color(hex: "1A2517")
    private let softSage  = Color(hex: "ACC8A2")
    private let screenBackground = Color.theme.background

    var body: some View {
        ZStack {
            screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What would you like to do?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("Choose how you want to use your scan")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(ScanIntent.allCases, id: \.title) { intent in
                                intentCard(intent)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }

                nextButton
            }
        }
        // "Find recipes" → pick a recipe type style first
        .fullScreenCover(isPresented: $showingRecipeTypePicker) {
            RecipeTypePicker(
                ingredients: ingredients,
                analysisId: analysisId,
                thumbnailData: thumbnailData,
                onDismiss: onDismiss
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(screenBackground)
                    .clipShape(Circle())
            }
            Spacer()
            Text("Scan Options")
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Intent Card

    private func intentCard(_ intent: ScanIntent) -> some View {
        let isSelected = selectedIntent == intent
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIntent = intent
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? softSage.opacity(0.25) : Color.black.opacity(0.05))
                        .frame(width: 52, height: 52)
                    Image(systemName: intent.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? deepOlive : .black)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(intent.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? deepOlive : .black)
                    Text(intent.subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? deepOlive : Color.gray.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? softSage.opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? deepOlive.opacity(0.4) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            handleNext()
        } label: {
            Text("Next")
                .font(.headline)
                .foregroundColor(softSage)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(selectedIntent == nil ? Color.gray : deepOlive)
                .cornerRadius(28)
        }
        .disabled(selectedIntent == nil)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(screenBackground)
    }

    private func handleNext() {
        guard let intent = selectedIntent else { return }
        switch intent {
        case .findRecipes:
            // Show recipe style picker
            showingRecipeTypePicker = true
        case .identifyDish:
            // Skip recipe type — go straight to generation with dish-identification context
            RecipeJobService.shared.startRecipeGeneration(
                analysisId: analysisId,
                ingredients: ingredients,
                thumbnailData: thumbnailData,
                recipeType: "Identify Dish",
                customPrompt: nil
            )
            onDismiss()
        }
    }
}

// MARK: - RecipeTypePicker (Step 2: recipe style, only for findRecipes intent)

struct RecipeTypePicker: View {
    let ingredients: [Ingredient]
    let analysisId: UUID
    let thumbnailData: Data?
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: RecipeType? = nil
    @State private var customPromptText: String = ""
    @State private var showingCustomLimitAlert = false

    private let deepOlive = Color(hex: "1A2517")
    private let softSage  = Color(hex: "ACC8A2")
    private let screenBackground = Color.theme.background
    private let maxFreeCustomSearches = 3

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What are you in the mood for?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("Choose a recipe style to personalize results")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(RecipeType.presets) { type in
                                recipeTypeCard(type)
                            }
                        }
                        .padding(.horizontal, 24)

                        customOptionCard
                            .padding(.horizontal, 24)

                        if selectedType == .custom {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("e.g. Korean-inspired, air fryer recipes...", text: $customPromptText)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .padding(14)
                                    .background(Color.theme.background)
                                    .cornerRadius(12)
                                Text("Be specific for best results")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }

                generateButton
            }
        }
        .alert("Custom Search Limit", isPresented: $showingCustomLimitAlert) {
            Button("OK") {}
        } message: {
            Text("You've used all \(maxFreeCustomSearches) custom searches for today. Upgrade to Premium for unlimited custom searches.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(screenBackground)
                    .clipShape(Circle())
            }
            Spacer()
            Text("Recipe Style")
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Preset Card

    private func recipeTypeCard(_ type: RecipeType) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = type
                customPromptText = ""
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? softSage : .black)
                Text(type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? softSage : .black)
                    .multilineTextAlignment(.center)
                Text(type.subtitle)
                    .font(.caption2)
                    .foregroundColor(isSelected ? softSage.opacity(0.8) : .gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? deepOlive : Color.white)
            .cornerRadius(16)
        }
    }

    // MARK: - Custom Card

    private var customOptionCard: some View {
        let isSelected = selectedType == .custom
        return Button {
            if !SubscriptionService.shared.hasAccess && customSearchesUsedToday >= maxFreeCustomSearches {
                showingCustomLimitAlert = true
                return
            }
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = .custom
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? softSage : .black)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? softSage : .black)
                    Text("Type your own search")
                        .font(.caption2)
                        .foregroundColor(isSelected ? softSage.opacity(0.8) : .gray)
                }
                Spacer()
                if !SubscriptionService.shared.hasAccess {
                    let remaining = max(0, maxFreeCustomSearches - customSearchesUsedToday)
                    Text("\(remaining) left today")
                        .font(.caption2)
                        .foregroundColor(isSelected ? softSage.opacity(0.7) : .gray)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? deepOlive : Color.white)
            .cornerRadius(16)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            startGeneration()
        } label: {
            Text("Generate Recipes")
                .font(.headline)
                .foregroundColor(softSage)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isGenerateDisabled ? Color.gray : deepOlive)
                .cornerRadius(28)
        }
        .disabled(isGenerateDisabled)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(screenBackground)
    }

    // MARK: - Helpers

    private var isGenerateDisabled: Bool {
        guard let type = selectedType else { return true }
        if type == .custom && customPromptText.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        return false
    }

    private var customSearchesUsedToday: Int {
        UserDefaults.standard.integer(forKey: "customSearchCount_\(dateKey)")
    }

    private var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Actions

    private func startGeneration() {
        guard let type = selectedType else { return }

        if type == .custom {
            let key = "customSearchCount_\(dateKey)"
            UserDefaults.standard.set(customSearchesUsedToday + 1, forKey: key)
        }

        let prompt = type == .custom ? customPromptText.trimmingCharacters(in: .whitespaces) : nil

        RecipeJobService.shared.startRecipeGeneration(
            analysisId: analysisId,
            ingredients: ingredients,
            thumbnailData: thumbnailData,
            recipeType: type.rawValue,
            customPrompt: prompt
        )

        onDismiss()
    }
}
