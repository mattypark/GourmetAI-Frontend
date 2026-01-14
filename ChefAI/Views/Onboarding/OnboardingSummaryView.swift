//
//  OnboardingSummaryView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct OnboardingSummaryView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("Your Profile Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("Tap any item to edit")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)

                // Summary Items
                VStack(spacing: 12) {
                    ForEach(viewModel.summaryItems, id: \.title) { item in
                        SummaryItemRow(
                            title: item.title,
                            value: item.value,
                            onTap: {
                                withAnimation {
                                    viewModel.goToPage(item.page)
                                }
                            }
                        )
                    }
                }

                // Completion Message
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.3))

                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ready to cook!")
                                .font(.headline)
                                .foregroundColor(.black)

                            Text("ChefAI will personalize recipes based on your preferences.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Summary Item Row

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

// MARK: - Summary Section (Alternative Style)

struct SummarySection: View {
    let title: String
    let value: String?
    let values: [String]?
    let icon: String?

    init(title: String, value: String?, icon: String? = nil) {
        self.title = title
        self.value = value
        self.values = nil
        self.icon = icon
    }

    init(title: String, values: [String], icon: String? = nil) {
        self.title = title
        self.value = nil
        self.values = values
        self.icon = icon
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }

            if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(.black)
            } else if let values = values, !values.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(values, id: \.self) { item in
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            } else {
                Text("Not set")
                    .font(.body)
                    .foregroundColor(.gray.opacity(0.5))
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.03))
        .cornerRadius(12)
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()

        OnboardingSummaryView(viewModel: {
            let vm = OnboardingViewModel()
            vm.selectedMainGoal = .eatHealthier
            vm.selectedSkillLevel = .intermediate
            vm.selectedTimeAvailability = .twentyTo40
            vm.selectedAdventureLevel = .sometimesAdventurous
            vm.selectedMealPreferences = [.quickEasy, .highProtein]
            vm.selectedEquipment = [.stove, .oven, .knifeSet]
            return vm
        }())
    }
}
