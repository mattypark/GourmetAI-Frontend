//
//  RecipeJobCardView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-20.
//

import SwiftUI

struct RecipeJobCardView: View {
    let job: RecipeJob
    var onTap: () -> Void = {}
    var onRetry: () -> Void = {}

    @State private var holdProgress: CGFloat = 0
    @State private var holdTimer: Timer?
    @State private var isHolding = false

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail image (left side)
            thumbnailView

            Spacer()

            // Status indicator (right side)
            statusView
        }
        .padding(16)
        .background(Color.theme.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .contentShape(Rectangle())
        .simultaneousGesture(tapGesture)
        .simultaneousGesture(holdGesture)
    }

    // Only allow tap on finished jobs
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                if job.status == .finished {
                    onTap()
                }
            }
    }

    // Hold gesture for error jobs
    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard job.status == .error, !isHolding else { return }
                startHold()
            }
            .onEnded { _ in
                cancelHold()
            }
    }

    private func startHold() {
        isHolding = true
        holdProgress = 0

        withAnimation(.linear(duration: 3)) {
            holdProgress = 1.0
        }

        holdTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                holdProgress = 0
                isHolding = false
                onRetry()
            }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
        isHolding = false
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
            // Status icon (with hold progress ring for error state)
            if job.status == .error {
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 3)
                        .frame(width: 28, height: 28)

                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.red)
                        .font(.system(size: 12, weight: .bold))
                }
            } else {
                statusIcon
            }

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
                Image(systemName: "arrow.clockwise.circle")
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
            return "Hold to Retry"
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
            RecipeJobCardView(
                job: RecipeJob(
                    analysisId: UUID(),
                    ingredients: ["chicken", "garlic", "olive oil"],
                    thumbnailData: nil
                )
            )

            RecipeJobCardView(
                job: {
                    var job = RecipeJob(
                        analysisId: UUID(),
                        ingredients: ["beef", "onion", "potato"],
                        thumbnailData: nil
                    )
                    job.status = .error
                    job.errorMessage = "Server timeout"
                    return job
                }(),
                onRetry: { print("Retrying!") }
            )

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
                onTap: { print("Tapped finished") }
            )
        }
        .padding()
    }
}
