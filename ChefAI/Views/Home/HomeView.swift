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
    @State private var showingProfile = false
    @State private var hasLoadedInitially = false
    @State private var selectedCompletedJob: RecipeJob?

    // Combined check for empty state
    private var hasContent: Bool {
        !recipeJobService.activeJobs.isEmpty || !recipeJobService.completedJobs.isEmpty
    }

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

                    if !hasContent {
                        // Empty state - centered
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        // Content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 32) {
                                // Active Recipe Jobs Section
                                if !recipeJobService.activeJobs.isEmpty {
                                    activeJobsSection
                                }

                                // Completed Recipe Jobs Section
                                if !recipeJobService.completedJobs.isEmpty {
                                    completedJobsSection
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
            .fullScreenCover(item: $selectedCompletedJob) { job in
                RecipeListFromJobView(job: job)
            }
            .onAppear {
                if !hasLoadedInitially {
                    hasLoadedInitially = true
                    viewModel.loadData()
                }
            }
        }
    }

    // MARK: - Active Jobs Section

    private var activeJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Creating Recipes")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(recipeJobService.activeJobs) { job in
                    RecipeJobCardView(job: job) {
                        // Active jobs are not tappable
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Completed Jobs Section

    private var completedJobsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(settingsViewModel.userName.isEmpty ? "Chef" : settingsViewModel.userName)'s Recipes")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                Spacer()

                if recipeJobService.completedJobs.count > 3 {
                    Button("Clear All") {
                        recipeJobService.clearCompletedJobs()
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(recipeJobService.completedJobs.prefix(5)) { job in
                    RecipeJobCardView(job: job, onTap: {
                        print("🔘 Card tapped for job \(job.id), status: \(job.status.rawValue)")
                        if job.status == .finished {
                            selectedCompletedJob = job
                        } else if job.status == .error {
                            RecipeJobService.shared.retryJob(job.id)
                        }
                    })
                }
            }
            .padding(.horizontal)
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

#Preview {
    HomeView()
}
