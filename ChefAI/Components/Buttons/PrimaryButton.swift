//
//  PrimaryButton.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black) 
            .cornerRadius(16)
        }
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        VStack(spacing: 16) {
            PrimaryButton(title: "Continue", action: {})
            PrimaryButton(title: "Loading", action: {}, isLoading: true)
        }
        .padding()
    }
}
