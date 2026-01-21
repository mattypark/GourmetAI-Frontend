//
//  RecipeJobCardView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-20.
//

import SwiftUI

struct RecipeJobCardView: View {
    let job: RecipeJob
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Thumbnail image (left side)
                thumbnailView

                Spacer()

                // Status indicator (right side)
                statusView
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(job.status.isProcessing)
    }

    // MARK: - Thumbnail

    private var thumbnailView: some View {
        Group {
            if let image = job.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
            }
        }
    }

    // MARK: - Status

    private var statusView: some View {
        HStack(spacing: 6) {
            // Status icon
            statusIcon

            // Status text with optional animated dots
            HStack(spacing: 4) {
                Text(statusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)

                if shouldShowDots {
                    AnimatedDotsView(color: statusColor)
                }
            }
        }
    }

    private var statusIcon: some View {
        Group {
            switch job.status {
            case .thinking:
                Image(systemName: "brain")
                    .foregroundColor(.gray)
            case .searching:
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
            case .sourcesFound:
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.orange)
            case .calculating:
                Image(systemName: "gearshape.2")
                    .foregroundColor(.purple)
            case .finished:
                Image(systemName: "sparkles")
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
        .font(.subheadline)
    }

    private var statusText: String {
        switch job.status {
        case .thinking:
            return "Thinking"
        case .searching:
            return "Searching"
        case .sourcesFound:
            return "\(job.sourceCount) sources"
        case .calculating:
            return "Calculating"
        case .finished:
            return "Finished"
        case .error:
            return "Error"
        }
    }

    private var statusColor: Color {
        switch job.status {
        case .thinking:
            return .gray
        case .searching:
            return .blue
        case .sourcesFound:
            return .orange
        case .calculating:
            return .purple
        case .finished:
            return .green
        case .error:
            return .red
        }
    }

    private var shouldShowDots: Bool {
        [.thinking, .searching, .calculating].contains(job.status)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()

        VStack(spacing: 16) {
            // Thinking state
            RecipeJobCardView(
                job: RecipeJob(
                    analysisId: UUID(),
                    ingredients: ["chicken", "garlic", "olive oil"],
                    thumbnailData: nil
                ),
                onTap: {}
            )

            // Sources found state
            RecipeJobCardView(
                job: {
                    var job = RecipeJob(
                        analysisId: UUID(),
                        ingredients: ["beef", "onion", "potato"],
                        thumbnailData: nil
                    )
                    job.status = .sourcesFound
                    job.sourceCount = 7
                    return job
                }(),
                onTap: {}
            )

            // Calculating state
            RecipeJobCardView(
                job: {
                    var job = RecipeJob(
                        analysisId: UUID(),
                        ingredients: ["salmon", "lemon", "dill"],
                        thumbnailData: nil
                    )
                    job.status = .calculating
                    job.sourceCount = 5
                    return job
                }(),
                onTap: {}
            )

            // Finished state
            RecipeJobCardView(
                job: {
                    var job = RecipeJob(
                        analysisId: UUID(),
                        ingredients: ["pasta", "tomato", "basil"],
                        thumbnailData: nil
                    )
                    job.status = .finished
                    job.sourceCount = 8
                    return job
                }(),
                onTap: {}
            )
        }
        .padding()
    }
}
