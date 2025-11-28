//
//  TextFieldWithLabel.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct TextFieldWithLabel: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.theme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.theme.cardBorder, lineWidth: 1)
                )
                .onSubmit {
                    onSubmit?()
                }
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    ZStack {
        Color.black.ignoresSafeArea()
        TextFieldWithLabel(
            label: "Add Item",
            placeholder: "Enter ingredient name",
            text: $text
        )
        .padding()
    }
}
