//
//  SwipeToDeleteWrapper.swift
//  ChefAI
//

import SwiftUI

struct SwipeToDeleteWrapper<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var showingDelete = false

    private let deleteWidth: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button behind the card
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        offset = -500
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDelete()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                        Text("Delete")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteWidth)
                    .frame(maxHeight: .infinity)
                }
                .frame(width: deleteWidth)
            }
            .frame(maxHeight: .infinity)
            .background(Color.red)
            .cornerRadius(16)
            .opacity(showingDelete ? 1 : 0)

            // Main content
            content()
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 {
                                offset = max(translation, -deleteWidth - 20)
                                showingDelete = true
                            } else if showingDelete {
                                offset = min(0, -deleteWidth + translation)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.easeOut(duration: 0.2)) {
                                if offset < -deleteWidth / 2 {
                                    offset = -deleteWidth
                                    showingDelete = true
                                } else {
                                    offset = 0
                                    showingDelete = false
                                }
                            }
                        }
                )
                .onTapGesture {
                    if showingDelete {
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = 0
                            showingDelete = false
                        }
                    }
                }
        }
        .clipped()
    }
}
