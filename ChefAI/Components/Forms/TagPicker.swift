//
//  TagPicker.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct TagPicker<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let items: [T]
    @Binding var selectedItems: Set<T>
    var iconProvider: ((T) -> String)?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(items), id: \.self) { item in
                TagPickerButton(
                    item: item,
                    isSelected: selectedItems.contains(item),
                    iconProvider: iconProvider,
                    onTap: {
                        if selectedItems.contains(item) {
                            selectedItems.remove(item)
                        } else {
                            selectedItems.insert(item)
                        }
                    }
                )
            }
        }
    }
}

struct TagPickerButton<T: RawRepresentable & Hashable>: View where T.RawValue == String {
    let item: T
    let isSelected: Bool
    var iconProvider: ((T) -> String)?
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let iconProvider = iconProvider {
                    Image(systemName: iconProvider(item))
                        .font(.system(size: 14))
                }

                Text(item.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.black.opacity(0.1) : Color.black.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.1), lineWidth: isSelected ? 2 : 1.5)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    @Previewable @State var selected: Set<DietaryRestriction> = []

    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            TagPicker(
                items: DietaryRestriction.allCases,
                selectedItems: $selected,
                iconProvider: { $0.icon }
            )
            .padding()
        }
    }
}
