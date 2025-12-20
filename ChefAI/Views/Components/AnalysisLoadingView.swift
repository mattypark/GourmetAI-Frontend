//
//  AnalysisLoadingView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct AnalysisLoadingView: View {
    let image: UIImage?
    let status: AnalysisStatus

    var body: some View {
        HStack(alignment: .center, spacing: 40) {
            // LEFT: Food image (standalone rounded pill)
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 100, height: 140)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.5))
                    )
            }

            // RIGHT: Status text only (no container)
            statusTextView
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var statusTextView: some View {
        switch status {
        case .detectingIngredients:
            VStack(alignment: .leading, spacing: 4) {
                Text("Detecting ingredients...")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                ProgressView()
                    .scaleEffect(0.8)
            }

        case .ingredientsDetected:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Ingredients detected")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundColor(.gray)
            }

        case .generatingRecipes:
            VStack(alignment: .leading, spacing: 4) {
                Text("Generating recipes...")
                    .font(.title3)
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                ProgressView()
                    .scaleEffect(0.8)
            }

        case .finished:
            HStack(spacing: 6) {
                Text("✨")
                    .font(.title3)
                Text("Done!")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }

        case .idle:
            EmptyView()
        }
    }
}

#Preview("Detecting") {
    ZStack {
        Color.white.ignoresSafeArea()
        AnalysisLoadingView(
            image: nil,
            status: .detectingIngredients
        )
    }
}

#Preview("Detected") {
    ZStack {
        Color.white.ignoresSafeArea()
        AnalysisLoadingView(
            image: nil,
            status: .ingredientsDetected
        )
    }
}

#Preview("Generating") {
    ZStack {
        Color.white.ignoresSafeArea()
        AnalysisLoadingView(
            image: nil,
            status: .generatingRecipes
        )
    }
}

#Preview("Finished") {
    ZStack {
        Color.white.ignoresSafeArea()
        AnalysisLoadingView(
            image: nil,
            status: .finished
        )
    }
}
