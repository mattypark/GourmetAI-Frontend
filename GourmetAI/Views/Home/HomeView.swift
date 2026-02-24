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
    @ObservedObject private var recipeJobService = RecipeJobService.shared
    @ObservedObject private var categoryService = RecipeCategoryService.shared
    @State private var showingProfile = false
    @State private var hasLoadedInitially = false
    @State private var selectedCompletedJob: RecipeJob?
    @State private var showingAddCategory = false
    @State private var selectedCategory: RecipeCategory?

    private var hasRecipeContent: Bool {
        !recipeJobService.activeJobs.isEmpty || !recipeJobService.completedJobs.isEmpty
    }

    private var hasRecentScans: Bool {
        !viewModel.analyses.isEmpty
    }

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header row: Logo + Search + Settings
                    headerRow
                        .padding(.top, 8)
                        .padding(.bottom, 21)
                        .staggerEntry(index: 0)

                    // Profile row: Avatar + Greeting
                    profileRow
                        .padding(.bottom, 28)
                        .staggerEntry(index: 1)

                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Categories section
                            Text("Categories")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.leading, 20)
                                .padding(.bottom, 16)
                                .staggerEntry(index: 2)

                            // Category grid
                            categoryGrid
                                .padding(.horizontal, 19)
                                .padding(.bottom, 62)
                                .staggerEntry(index: 3)

                            // Recent scans section
                            recentScansSection
                                .staggerEntry(index: 4)

                            // Recent recipes section
                            if hasRecipeContent {
                                contentSection
                                    .padding(.top, 8)
                                    .staggerEntry(index: 5)
                            }

                            if !hasRecentScans && !hasRecipeContent {
                                emptyStateView
                                    .staggerEntry(index: 5)
                            }
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
            .navigationDestination(for: RecipeCategory.self) { category in
                CategoryDetailView(category: category)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileMenuView()
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet()
            }
            .fullScreenCover(item: $selectedCompletedJob) { job in
                RecipeListFromJobView(job: job)
            }
            .onAppear {
                // Always reload analyses so new saves appear
                viewModel.loadData()
                if !hasLoadedInitially {
                    hasLoadedInitially = true
                }
                // Reload profile image in case it was updated in Settings
                settingsViewModel.loadSettings()
                settingsViewModel.loadUserProfile()
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            // App logo
            Image("ChefAILogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(.leading, 19)

            Spacer()

            // Search icon
            Button {
                // Search action
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "1E1E1E"))
                    .frame(width: 24, height: 24)
            }

            // Filter icon
            Button {
                // Filter action (coming soon)
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "1E1E1E"))
                    .frame(width: 24, height: 24)
            }

            // Settings button (glass effect circle)
            Button {
                showingProfile = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "1D1B20"))
                    .frame(width: 31, height: 30)
                    .background(Color.theme.background)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
            }
            .padding(.trailing, 21)
        }
    }

    // MARK: - Profile Row

    private var profileRow: some View {
        HStack(spacing: 15) {
            // Profile avatar
            Group {
                if let profileImage = settingsViewModel.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 42, height: 42)
            .background(Color(hex: "F5F5F5"))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 1)
            )

            // Greeting text
            Text("Hello, \(settingsViewModel.userName.isEmpty ? "Chef" : settingsViewModel.userName).")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)

            Spacer()
        }
        .padding(.leading, 19)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: categoryColumns, spacing: 12) {
            ForEach(categoryService.categories) { category in
                NavigationLink(value: category) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(category.color)
                        .frame(height: 72)
                        .overlay(
                            HStack(spacing: 10) {
                                if let icon = category.iconName {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.35))
                                        .frame(width: 38, height: 38)
                                        .overlay(
                                            Image(systemName: icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(category.textColor)
                                        )
                                }
                                Text(category.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(category.textColor)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                        )
                }
            }

            // Add new category card
            Button {
                showingAddCategory = true
            } label: {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "F5F5F5"))
                    .frame(height: 72)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 23, weight: .medium))
                            .foregroundColor(Color(hex: "1E1E1E"))
                    )
            }
        }
    }

    // MARK: - Recent Scans Section

    private let scanColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var recentScansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent scans")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .padding(.leading, 20)

            if hasRecentScans {
                LazyVGrid(columns: scanColumns, spacing: 12) {
                    ForEach(Array(viewModel.analyses.prefix(6))) { analysis in
                        NavigationLink(value: analysis) {
                            AnalysisCardView(analysis: analysis)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 19)
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No scans yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        HStack {
            Spacer()
            Text("Start creating organic, premium meals by a click of a button.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .frame(width: 278)
                .padding(.top, 30)
            Spacer()
        }
    }

    // MARK: - Content Section (Active + Completed Jobs)

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            if !recipeJobService.activeJobs.isEmpty {
                activeJobsSection
            }

            if !recipeJobService.completedJobs.isEmpty {
                completedJobsSection
            }
        }
    }

    // MARK: - Active Jobs Section

    private var activeJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creating Recipes")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(recipeJobService.activeJobs) { job in
                    RecipeJobCardView(job: job)
                }
            }
            .padding(.horizontal, 19)
        }
    }

    // MARK: - Completed Jobs Section

    private var completedJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent recipes")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                if recipeJobService.completedJobs.count > 3 {
                    Button("Clear All") {
                        recipeJobService.clearCompletedJobs()
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(recipeJobService.completedJobs.prefix(5)) { job in
                    SwipeToDeleteWrapper(onDelete: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            recipeJobService.deleteJob(job.id)
                        }
                    }) {
                        RecipeJobCardView(
                            job: job,
                            onTap: {
                                if job.status == .finished {
                                    selectedCompletedJob = job
                                }
                            },
                            onRetry: {
                                RecipeJobService.shared.retryJob(job.id)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 19)
        }
    }
}

#Preview {
    HomeView()
}
