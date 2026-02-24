//
//  AnalysisLoadingView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI

struct AnalysisLoadingView: View {
    let images: [UIImage]
    @ObservedObject var cameraViewModel: CameraViewModel
    let onBack: () -> Void

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

    /// Backward-compatible init for single image
    init(image: UIImage?, cameraViewModel: CameraViewModel, onBack: @escaping () -> Void) {
        self.images = image.map { [$0] } ?? []
        self.cameraViewModel = cameraViewModel
        self.onBack = onBack
    }

    /// Multi-image init
    init(images: [UIImage], cameraViewModel: CameraViewModel, onBack: @escaping () -> Void) {
        self.images = images
        self.cameraViewModel = cameraViewModel
        self.onBack = onBack
    }

    private var progressPercent: Int {
        Int(cameraViewModel.analysisProgress * 100)
    }

    private var statusText: String {
        let text = cameraViewModel.analysisStatus.displayText
        return text.isEmpty ? "Finding Ingredients..." : text
    }

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header — pinned to top
                headerView

                // Push content down from header
                Spacer()
                    .frame(minHeight: 24, maxHeight: 48)

                // Centered content group
                VStack(spacing: 24) {
                    // Image preview(s)
                    imagePreview

                    // Status text
                    Text(statusText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    // Progress percentage
                    Text("\(progressPercent)%")
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
                                .frame(width: geometry.size.width * cameraViewModel.analysisProgress, height: 16)
                                .animation(.easeInOut(duration: 0.4), value: cameraViewModel.analysisProgress)
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
                }

                // Balance the bottom space
                Spacer()
                    .frame(minHeight: 60)
            }
        }
        .onAppear {
            currentFact = foodFacts.randomElement() ?? foodFacts[0]
        }
    }

    // MARK: - Image Preview

    @ViewBuilder
    private var imagePreview: some View {
        if images.count == 1, let image = images.first {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(16)
                .padding(.horizontal, 24)
        } else if images.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(height: 120)
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
                    .background(Color.theme.background)
                    .clipShape(Circle())
            }

            Spacer()

            Text("Gourmet AI")
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
}

#Preview {
    AnalysisLoadingView(
        image: nil,
        cameraViewModel: CameraViewModel(),
        onBack: {}
    )
}
