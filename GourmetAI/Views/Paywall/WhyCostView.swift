//
//  WhyCostView.swift
//  ChefAI
//
//  "Why does Chef AI cost this much?" developer message screen.
//

import SwiftUI

struct WhyCostView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Color.theme.background)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 20) {
                        // Developer photo
                        Image("DeveloperPhoto")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .padding(.top, 20)

                        // Title
                        Text("Hi, I'm Matthew Park")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)

                        // Message
                        VStack(alignment: .leading, spacing: 16) {
                            Text("I'm the developer behind Gourmet AI. I built this app because I believe everyone deserves easy access to great meals — even when you're not sure what to cook with what you have.")
                                .font(.system(size: 16))
                                .foregroundColor(.black)

                            Text("To be transparent, it comes down to cost. Each food scan, recipe generation, and ingredient analysis uses high-quality AI providers to ensure the best accuracy. The average cost per active user is $6-8 per month, and for power users, it can be even higher (meaning I sometimes lose money on those subscriptions).")
                                .font(.system(size: 16))
                                .foregroundColor(.black)

                            Text("I've priced the app to make it sustainable while keeping it accessible. I hope this helps, and I'd love to have you as a user :)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}
