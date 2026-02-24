//
//  AddToCategorySheet.swift
//  ChefAI
//

import SwiftUI

struct AddToCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var categoryService = RecipeCategoryService.shared
    let recipeId: UUID
    @State private var showingNewCategory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                if categoryService.categories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.4))

                        Text("No categories yet")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.gray)

                        Button {
                            showingNewCategory = true
                        } label: {
                            Text("Create Category")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black)
                                .cornerRadius(20)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(categoryService.categories) { category in
                                categoryRow(category)
                            }

                            // New category button
                            Button {
                                showingNewCategory = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black)

                                    Text("New Category")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color(hex: "F5F5F5"))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Add to Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showingNewCategory) {
                AddCategorySheet()
            }
        }
    }

    private func categoryRow(_ category: RecipeCategory) -> some View {
        let isInCategory = category.recipeIds.contains(recipeId)

        return Button {
            if isInCategory {
                categoryService.removeRecipe(recipeId, fromCategory: category.id)
            } else {
                categoryService.addRecipe(recipeId, toCategory: category.id)
            }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(category.color)
                    .frame(width: 40, height: 40)

                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: isInCategory ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isInCategory ? .black : .gray.opacity(0.4))
            }
            .padding(12)
            .background(Color.theme.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AddToCategorySheet(recipeId: UUID())
}
