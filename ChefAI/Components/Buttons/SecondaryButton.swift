//
//  SecondaryButton.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 2)
                )
                .cornerRadius(16)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SecondaryButton(title: "Cancel") {}
            .padding()
    }
}
