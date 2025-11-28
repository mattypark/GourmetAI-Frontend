//
//  SavedRecipeImagesView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct SavedRecipeImagesView: View {
    let recipes: [Recipe]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(recipes) { recipe in
                if let imageData = recipe.savedImageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.theme.cardBorder, lineWidth: 1)
                        )
                } else {
                    // Placeholder for recipes without saved images
                    Rectangle()
                        .fill(Color.theme.surface)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.theme.cardBorder, lineWidth: 1)
                        )
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SavedRecipeImagesView(recipes: MockData.mockRecipes)
            .padding()
    }
}
