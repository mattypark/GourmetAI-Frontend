//
//  FloatingPlusButton.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct FloatingPlusButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 64, height: 64)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FloatingPlusButton {}
    }
}
