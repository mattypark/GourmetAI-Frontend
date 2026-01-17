//
//  AnalysisLoadingView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct AnalysisLoadingView: View {
    let image: UIImage?
    let onBack: () -> Void

    @State private var progress: Double = 0
    @State private var currentFact: String = ""

    private let foodFacts = [
        "Onions taste sweeter the longer you cook them—not because sugar is added, but because heat breaks down their complex carbohydrates into simple sugars.",
        "Honey never spoils. Archaeologists have found 3,000-year-old honey in Egyptian tombs that was still edible.",
        "Bananas are berries, but strawberries aren't. Botanically, berries come from one flower with one ovary.",
        "Carrots were originally purple. Orange carrots were developed in the 17th century by Dutch growers.",
        "Apples float because they are 25% air, making them less dense than water.",
        "A single spaghetti noodle is called a spaghetto.",
        "Cucumbers are 96% water, making them one of the most hydrating foods.",
        "Almonds are seeds, not nuts. They're actually related to peaches.",
        "Lemons contain more sugar than strawberries by weight.",
        "Nutmeg is a hallucinogen in large doses. Don't eat too much!"
    ]

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                VStack(spacing: 24) {
                    // Image preview (smaller)
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                    }

                    // Finding Ingredients text
                    Text("Finding Ingredients...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    // Progress percentage
                    Text("\(Int(progress))%")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.black)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemGray4))
                                .frame(height: 16)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black)
                                .frame(width: geometry.size.width * (progress / 100), height: 16)
                        }
                    }
                    .frame(height: 16)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 40)

                    // Random Fact section
                    VStack(spacing: 12) {
                        Text("Random Fact:")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)

                        Text(currentFact)
                            .font(.body)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer()
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            currentFact = foodFacts.randomElement() ?? foodFacts[0]
            startProgressAnimation()
        }
    }

    private var headerView: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Chef AI")
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func startProgressAnimation() {
        // Animate progress from 0 to 100 with random increments
        progress = 0
        animateProgress()
    }

    private func animateProgress() {
        guard progress < 100 else { return }

        // Random increment between 8 and 25
        let increment = Double.random(in: 8...25)
        let nextProgress = min(progress + increment, 100)

        // Random delay between 0.3 and 0.8 seconds
        let delay = Double.random(in: 0.3...0.8)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.3)) {
                progress = nextProgress
            }

            if progress < 100 {
                animateProgress()
            }
        }
    }
}

#Preview {
    AnalysisLoadingView(
        image: nil,
        onBack: {}
    )
}
