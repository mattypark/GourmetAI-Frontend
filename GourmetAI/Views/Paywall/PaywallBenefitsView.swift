//
//  PaywallBenefitsView.swift
//  ChefAI
//
//  Paywall Screen 1: "Unlock the full Chef experience"
//

import SwiftUI

struct PaywallBenefitsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // Title
            Text("Unlock the full\nGourmet AI experience")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 32)

            // Feature list
            VStack(alignment: .leading, spacing: 20) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    HStack(spacing: 16) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color(white: 0.93))
                            .clipShape(Circle())

                        Text(feature.description)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
