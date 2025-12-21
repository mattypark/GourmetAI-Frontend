//
//  HomeView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showingProfile = false
    @State private var showingRecipeList = false
    @Binding var refreshID: UUID

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    if viewModel.analyses.isEmpty && !viewModel.hasPantryItems {
                        // Empty state - centered
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        // Content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 32) {
                                // Recent Analyses
                                if !viewModel.analyses.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Recent Analyses")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                            .padding(.horizontal)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(viewModel.analyses) { analysis in
                                                    NavigationLink(value: analysis) {
                                                        AnalysisCardView(analysis: analysis)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }

                                // My Pantry Section
                                if viewModel.hasPantryItems {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("My Pantry")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black)

                                            Spacer()

                                            Text("\(viewModel.pantryCount) items")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal)

                                        // Pantry Card
                                        Button {
                                            showingRecipeList = true
                                        } label: {
                                            PantryCardView(ingredients: viewModel.pantryIngredients)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AnalysisResult.self) { analysis in
                AnalysisDetailView(analysis: analysis)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileMenuView()
            }
            .fullScreenCover(isPresented: $showingRecipeList) {
                RecipeListView(
                    ingredients: viewModel.pantryIngredients,
                    onComplete: {
                        viewModel.loadData()
                    }
                )
            }
            .id(refreshID)
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Custom Header

    private var customHeader: some View {
        HStack {
            // App Logo (left)
            Image("ChefAILogo")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Profile picture button (right)
            Button {
                showingProfile = true
            } label: {
                if let profileImage = settingsViewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("You haven't uploaded any food")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text("Start creating delicious meals by a click of a button.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Pantry Card View

struct PantryCardView: View {
    let ingredients: [Ingredient]

    private var displayIngredients: [Ingredient] {
        Array(ingredients.prefix(6))
    }

    private var remainingCount: Int {
        max(0, ingredients.count - 6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Ingredient Pills
            FlowLayout(spacing: 8) {
                ForEach(displayIngredients) { ingredient in
                    IngredientPill(ingredient: ingredient)
                }

                if remainingCount > 0 {
                    Text("+\(remainingCount) more")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(16)
                }
            }

            // Generate Recipes CTA
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.green)
                Text("Generate Recipes from Pantry")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.4))
            }
            .foregroundColor(.black)
        }
        .padding()
        .background(Color.black.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

struct IngredientPill: View {
    let ingredient: Ingredient

    var body: some View {
        HStack(spacing: 4) {
            if let category = ingredient.category {
                Image(systemName: category.icon)
                    .font(.caption2)
            }
            Text(ingredient.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    @Previewable @State var refreshID = UUID()
    HomeView(refreshID: $refreshID)
}
