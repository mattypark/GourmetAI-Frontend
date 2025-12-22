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
    @State private var hasLoadedInitially = false

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

                    if viewModel.analyses.isEmpty {
                        // Empty state - centered
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        // Content
                        ScrollView {
                            VStack(alignment: .leading, spacing: 32) {
                                // Recent Analyses
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
            .onAppear {
                if !hasLoadedInitially {
                    hasLoadedInitially = true
                    viewModel.loadData()
                }
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

#Preview {
    HomeView()
}
