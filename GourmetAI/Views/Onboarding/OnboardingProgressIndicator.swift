//
//  OnboardingProgressIndicator.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.white : Color.theme.surface)
                    .frame(width: index == currentPage ? 32 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            OnboardingProgressIndicator(currentPage: 0, totalPages: 3)
            OnboardingProgressIndicator(currentPage: 1, totalPages: 3)
            OnboardingProgressIndicator(currentPage: 2, totalPages: 3)
        }
    }
}
