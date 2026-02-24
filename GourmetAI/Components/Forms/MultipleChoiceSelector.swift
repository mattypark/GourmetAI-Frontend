//
//  MultipleChoiceSelector.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct MultipleChoiceSelector<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let items: [T]
    @Binding var selected: T?
    var iconProvider: ((T) -> String)?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(Array(items), id: \.self) { item in
                MultipleChoiceButton(
                    item: item,
                    isSelected: selected == item,
                    iconProvider: iconProvider,
                    onTap: { selected = item }
                )
            }
        }
    }
}

struct MultipleChoiceButton<T: RawRepresentable & Hashable>: View where T.RawValue == String {
    let item: T
    let isSelected: Bool
    var iconProvider: ((T) -> String)?
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                if let iconProvider = iconProvider {
                    Image(systemName: iconProvider(item))
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? .white : .black)
                }

                Text(item.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .background(isSelected ? Color.black : Color.black.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.1), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
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
    @Previewable @State var selected: CookingGoal? = nil

    ZStack {
        Color.theme.background.ignoresSafeArea()
        ScrollView {
            MultipleChoiceSelector(
                items: CookingGoal.allCases,
                selected: $selected,
                iconProvider: { $0.icon }
            )
            .padding()
        }
    }
}
