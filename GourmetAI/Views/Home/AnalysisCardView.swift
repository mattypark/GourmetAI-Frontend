//
//  AnalysisCardView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct AnalysisCardView: View {
    let analysis: AnalysisResult

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // Square thumbnail
                if let image = analysis.thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                        .contentShape(Rectangle())
                } else {
                    Rectangle()
                        .fill(Color(hex: "F5F5F5"))
                        .frame(width: geo.size.width, height: geo.size.width)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }

                // Bottom gradient overlay with text
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geo.size.width, height: 60)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(analysis.ingredientSummary)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(analysis.date.timeAgo)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.width)
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .cornerRadius(14)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    ZStack {
        Color.theme.background.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            AnalysisCardView(
                analysis: AnalysisResult(
                    extractedIngredients: MockData.mockIngredients,
                    suggestedRecipes: MockData.mockRecipes
                )
            )
            AnalysisCardView(
                analysis: AnalysisResult(
                    extractedIngredients: MockData.mockIngredients,
                    suggestedRecipes: []
                )
            )
        }
        .padding()
    }
}
