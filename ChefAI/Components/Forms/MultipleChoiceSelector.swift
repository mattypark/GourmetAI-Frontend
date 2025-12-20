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
                Button(action: {
                    selected = item
                }) {
                    VStack(spacing: 12) {
                        if let iconProvider = iconProvider {
                            Image(systemName: iconProvider(item))
                                .font(.system(size: 32))
                                .foregroundColor(selected == item ? .white : .black)
                        }

                        Text(item.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selected == item ? .white : .black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 120)
                    .background(selected == item ? Color.black : Color.theme.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selected == item ? Color.black : Color.theme.cardBorder, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    @Previewable @State var selected: CookingGoal? = nil

    ZStack {
        Color.white.ignoresSafeArea()
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
