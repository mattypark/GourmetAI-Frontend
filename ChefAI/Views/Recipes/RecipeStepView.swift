//
//  RecipeStepView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI
import Combine

struct RecipeStepView: View {
    let step: RecipeStep
    let isCompleted: Bool
    let onToggle: () -> Void

    @State private var showingTimer: Bool = false
    @State private var timeRemaining: Int = 0
    @State private var timerActive: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main Step Row
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 12) {
                    // Step Number
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : Color.white.opacity(0.15))
                            .frame(width: 36, height: 36)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.stepNumber)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Instruction
                        Text(step.instruction)
                            .font(.body)
                            .foregroundColor(isCompleted ? .white.opacity(0.5) : .white)
                            .multilineTextAlignment(.leading)
                            .strikethrough(isCompleted)

                        // Meta info row
                        HStack(spacing: 16) {
                            // Duration
                            if let durationDisplay = step.durationDisplay {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    Text(durationDisplay)
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.6))
                            }

                            // Technique badge
                            if let technique = step.technique, !technique.isEmpty {
                                techniqueBadge(technique)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Timer Section (if has duration)
            if let duration = step.duration, duration > 0 {
                timerSection(duration: duration)
            }

            // Tips Section
            if !step.tips.isEmpty {
                tipsSection
            }

            // GIF/Video Section (placeholder for future implementation)
            if step.hasMedia {
                mediaSection
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Technique Badge

    private func techniqueBadge(_ technique: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: techniqueIcon(for: technique))
                .font(.caption2)
            Text(technique.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [techniqueColor(for: technique), techniqueColor(for: technique).opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }

    private func techniqueIcon(for technique: String) -> String {
        let lowerTechnique = technique.lowercased()
        switch lowerTechnique {
        case "chop", "dice", "mince", "julienne", "slice":
            return "scissors"
        case "sear", "sauté", "fry", "pan-fry":
            return "flame"
        case "simmer", "boil", "poach":
            return "drop.fill"
        case "bake", "roast":
            return "oven.fill"
        case "mix", "stir", "fold", "whisk":
            return "arrow.triangle.2.circlepath"
        case "marinate", "rest":
            return "clock"
        case "grill", "broil":
            return "flame.fill"
        case "steam":
            return "cloud.fill"
        default:
            return "fork.knife"
        }
    }

    private func techniqueColor(for technique: String) -> Color {
        let lowerTechnique = technique.lowercased()
        switch lowerTechnique {
        case "chop", "dice", "mince", "julienne", "slice":
            return .blue
        case "sear", "sauté", "fry", "pan-fry", "grill", "broil":
            return .orange
        case "simmer", "boil", "poach", "steam":
            return .cyan
        case "bake", "roast":
            return .red
        case "mix", "stir", "fold", "whisk":
            return .purple
        case "marinate", "rest":
            return .green
        default:
            return .gray
        }
    }

    // MARK: - Timer Section

    private func timerSection(duration: Int) -> some View {
        VStack(spacing: 8) {
            if showingTimer {
                HStack {
                    // Timer Display
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining <= 10 && timerActive ? .red : .white)

                    Spacer()

                    // Timer Controls
                    HStack(spacing: 12) {
                        if timerActive {
                            Button {
                                timerActive = false
                            } label: {
                                Image(systemName: "pause.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                        } else {
                            Button {
                                if timeRemaining == 0 {
                                    timeRemaining = duration
                                }
                                timerActive = true
                            } label: {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                        }

                        Button {
                            timeRemaining = duration
                            timerActive = false
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            } else {
                Button {
                    timeRemaining = duration
                    showingTimer = true
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("Start Timer (\(formatTime(duration)))")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if timerActive && timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining == 0 {
                    timerActive = false
                    // Could add haptic feedback or notification here
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("Tip")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
            }

            ForEach(step.tips, id: \.self) { tip in
                Text(tip)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Media Section (Placeholder)

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let gifURL = step.gifURL {
                // GIF placeholder - would use AsyncImage or SDWebImage in production
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 120)

                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.5))
                        Text("Tap to view technique")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            if let videoURL = step.videoURL {
                Button {
                    // Open video URL
                    if let url = URL(string: videoURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("Watch Video Tutorial")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                RecipeStepView(
                    step: RecipeStep(
                        stepNumber: 1,
                        instruction: "Heat olive oil in a large skillet over medium-high heat until shimmering.",
                        duration: 60,
                        technique: "sauté",
                        tips: ["Make sure the pan is hot before adding oil"]
                    ),
                    isCompleted: false,
                    onToggle: {}
                )

                RecipeStepView(
                    step: RecipeStep(
                        stepNumber: 2,
                        instruction: "Season chicken breasts with salt, pepper, and garlic powder on both sides.",
                        technique: "season"
                    ),
                    isCompleted: true,
                    onToggle: {}
                )

                RecipeStepView(
                    step: RecipeStep(
                        stepNumber: 3,
                        instruction: "Sear chicken for 6-7 minutes per side until golden brown and cooked through.",
                        duration: 420,
                        technique: "sear",
                        tips: [
                            "Don't move the chicken while searing",
                            "Internal temperature should reach 165°F"
                        ]
                    ),
                    isCompleted: false,
                    onToggle: {}
                )
            }
            .padding()
        }
    }
}
