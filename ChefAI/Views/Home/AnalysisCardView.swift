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
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail image
            if let image = analysis.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 150)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.theme.surface)
                    .frame(width: 200, height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.date.timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(analysis.ingredientSummary)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                if !analysis.suggestedRecipes.isEmpty {
                    Text("\(analysis.suggestedRecipes.count) recipes")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 200)
        .cardStyle()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AnalysisCardView(
            analysis: AnalysisResult(
                extractedIngredients: MockData.mockIngredients,
                suggestedRecipes: MockData.mockRecipes
            )
        )
        .padding()
    }
}
