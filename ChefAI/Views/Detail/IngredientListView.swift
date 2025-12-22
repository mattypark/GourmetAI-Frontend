//
//  IngredientListView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct IngredientListView: View {
    let ingredients: [Ingredient]
    let manualItems: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !ingredients.isEmpty {
                Text("Detected Ingredients")
                    .font(.headline)
                    .foregroundColor(.black)

                ForEach(ingredients) { ingredient in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.name)
                                .foregroundColor(.black)

                            if let category = ingredient.category {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        if let confidence = ingredient.confidence {
                            Text("\(Int(confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            if !manualItems.isEmpty {
                if !ingredients.isEmpty {
                    Divider()
                        .background(Color.black.opacity(0.1))
                        .padding(.vertical, 8)
                }

                Text("Manually Added")
                    .font(.headline)
                    .foregroundColor(.black)

                ForEach(manualItems, id: \.self) { item in
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)

                        Text(item)
                            .foregroundColor(.black)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        IngredientListView(
            ingredients: [
                Ingredient(name: "Eggs", category: .dairy, confidence: 0.95),
                Ingredient(name: "Milk", category: .dairy, confidence: 0.92)
            ],
            manualItems: ["Butter", "Salt"]
        )
        .padding()
    }
}
