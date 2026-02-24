//
//  AddCategorySheet.swift
//  ChefAI
//

import SwiftUI

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var categoryService = RecipeCategoryService.shared
    @State private var name = ""
    @State private var selectedColorHex = RecipeCategory.presetColors[0].hex
    @State private var selectedIcon: String? = nil

    private let colorColumns = [
        GridItem(.adaptive(minimum: 44), spacing: 12)
    ]

    private let iconColumns = [
        GridItem(.adaptive(minimum: 44), spacing: 12)
    ]

    /// A darkened version of the selected color for readable text on the pastel preview card
    private var previewTextColor: Color {
        let hex = selectedColorHex
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        let factor = 0.45
        return Color(red: r * factor, green: g * factor, blue: b * factor)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Preview card
                        previewCard
                            .padding(.horizontal, 20)

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)

                            TextField("e.g. Quick meals", text: $name)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .padding(14)
                                .background(Color(hex: "F5F5F5"))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)

                        // Icon picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)

                            LazyVGrid(columns: iconColumns, spacing: 12) {
                                // "None" option
                                Circle()
                                    .fill(selectedIcon == nil ? Color.black : Color(hex: "F5F5F5"))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedIcon == nil ? .white : .gray)
                                    )
                                    .onTapGesture {
                                        selectedIcon = nil
                                    }

                                ForEach(RecipeCategory.presetIcons, id: \.self) { icon in
                                    let isSelected = selectedIcon == icon
                                    Circle()
                                        .fill(isSelected ? Color.black : Color(hex: "F5F5F5"))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(isSelected ? .white : .black)
                                        )
                                        .onTapGesture {
                                            selectedIcon = icon
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)

                            LazyVGrid(columns: colorColumns, spacing: 12) {
                                ForEach(RecipeCategory.presetColors, id: \.hex) { preset in
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black, lineWidth: selectedColorHex == preset.hex ? 2.5 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColorHex = preset.hex
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 24)
                }

                // Create button pinned at bottom
                VStack {
                    Spacer()
                    Button {
                        categoryService.addCategory(
                            name: name.trimmingCharacters(in: .whitespaces),
                            colorHex: selectedColorHex,
                            iconName: selectedIcon
                        )
                        dismiss()
                    } label: {
                        Text("Create")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.black)
                            .cornerRadius(28)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 30, height: 30)
                            .background(Color(hex: "F5F5F5"))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(hex: selectedColorHex))
            .frame(height: 80)
            .overlay(
                HStack(spacing: 12) {
                    // Icon area
                    if let icon = selectedIcon {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(previewTextColor)
                            )
                    }

                    // Name
                    Text(name.isEmpty ? "Category Name" : name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(name.isEmpty ? previewTextColor.opacity(0.4) : previewTextColor)

                    Spacer()
                }
                .padding(.horizontal, 16)
            )
    }
}

#Preview {
    AddCategorySheet()
}
