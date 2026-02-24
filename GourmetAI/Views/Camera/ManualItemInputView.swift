//
//  ManualItemInputView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct ManualItemInputView: View {
    @ObservedObject var viewModel: CameraViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Items Manually")
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                TextField("Enter ingredient name", text: $viewModel.currentManualItem)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: viewModel.currentManualItem) { _, newValue in
                        // OWASP: Enforce 100-character limit at the UI level
                        if newValue.count > 100 {
                            viewModel.currentManualItem = String(newValue.prefix(100))
                        }
                    }
                    .onSubmit {
                        viewModel.addManualItem()
                    }

                Button(action: {
                    viewModel.addManualItem()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .disabled(viewModel.currentManualItem.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(viewModel.currentManualItem.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
            }

            if !viewModel.manualItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.manualItems.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.gray)

                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                viewModel.removeManualItem(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .cardStyle()
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = CameraViewModel()

    ZStack {
        Color.theme.background.ignoresSafeArea()
        ManualItemInputView(viewModel: viewModel)
            .padding()
    }
}
