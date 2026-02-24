//
//  PaywallTimelineView.swift
//  ChefAI
//
//  Paywall Screen 2: "How your Chef free trial works"
//

import SwiftUI

struct PaywallTimelineView: View {
    let selectedPlan: SubscriptionPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // Title
            Text("How your Gourmet AI\nfree trial works")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 40)

            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                // Today
                TimelineItem(
                    title: "Today",
                    subtitle: "Get unlimited access to all\nGourmet AI features",
                    isFirst: true,
                    isLast: false,
                    dotColor: .green
                )

                // Day 2
                TimelineItem(
                    title: "In Day 2",
                    subtitle: "Get a reminder your trial is about\nto end",
                    isFirst: false,
                    isLast: false,
                    dotColor: Color(white: 0.75)
                )

                // Day 3
                TimelineItem(
                    title: "In Day 3",
                    subtitle: "You'll be charged \(selectedPlan.displayPrice)\(selectedPlan.period) on\n\(trialEndDateString). Cancel anytime before\nto avoid charges.",
                    isFirst: false,
                    isLast: true,
                    dotColor: Color(white: 0.75)
                )
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var trialEndDateString: String {
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Timeline Item

struct TimelineItem: View {
    let title: String
    let subtitle: String
    let isFirst: Bool
    let isLast: Bool
    let dotColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)

                if !isLast {
                    Rectangle()
                        .fill(Color(white: 0.85))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
            .padding(.bottom, isLast ? 0 : 28)
        }
    }
}
