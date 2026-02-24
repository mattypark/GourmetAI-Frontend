//
//  OnboardingSummaryView.swift
//  ChefAI
//
//  Legacy file - summary page was removed from the onboarding flow.
//  Kept to avoid Xcode project file issues.
//

import SwiftUI

// MARK: - Summary Item Row (may be reused elsewhere)

struct SummaryItemRow: View {
    let title: String
    let value: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(value)
                        .font(.body)
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.black.opacity(0.3))
                    .font(.title3)
            }
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
