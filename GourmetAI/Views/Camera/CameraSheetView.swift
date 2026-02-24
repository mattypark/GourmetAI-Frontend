//
//  CameraSheetView.swift
//  ChefAI
//

import SwiftUI

struct CameraSheetView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var pickerImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FBFFF1").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: "F5F5F5"))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer().frame(height: 28)

                    // Mode toggle
                    VStack(spacing: 8) {
                        Text("What would you like to do?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Choose a mode to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    // Mode cards
                    VStack(spacing: 14) {
                        scanModeCard(
                            mode: .ingredients,
                            icon: "refrigerator.fill",
                            title: "Scan Ingredients",
                            description: "Photo your fridge, pantry, or groceries. AI detects what you have and suggests recipes.",
                            accentColor: Color.black
                        )

                        scanModeCard(
                            mode: .dish,
                            icon: "fork.knife",
                            title: "Identify a Dish",
                            description: "Photo a cooked meal (from TikTok, a restaurant, or your plate). AI reverse-engineers the full recipe with detailed steps.",
                            accentColor: Color.black
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 28)

                    // Photo source buttons
                    VStack(spacing: 12) {
                        Button(action: { viewModel.presentCamera() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Take Photo")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                        }

                        Button(action: { viewModel.presentPhotoPicker() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Choose from Library")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.isShowingCamera) {
                ImagePicker(
                    sourceType: .camera,
                    selectedImage: $pickerImage,
                    onImageSelected: { image in
                        viewModel.imageSelected(image)
                    }
                )
            }
            .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
                ImagePicker(
                    sourceType: .photoLibrary,
                    selectedImage: $pickerImage,
                    onImageSelected: { image in
                        viewModel.imageSelected(image)
                    }
                )
            }
            .fullScreenCover(isPresented: $viewModel.isShowingPreview) {
                if viewModel.scanMode == .dish {
                    DishScanReviewView(cameraViewModel: viewModel, onDismiss: { dismiss() })
                } else {
                    MultiImageReviewView(
                        cameraViewModel: viewModel,
                        onDismiss: { dismiss() }
                    )
                }
            }
        }
    }

    // MARK: - Mode Card

    private func scanModeCard(mode: ScanMode, icon: String, title: String, description: String, accentColor: Color) -> some View {
        let isSelected = viewModel.scanMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.scanMode = mode
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.black : Color(hex: "F5F5F5"))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : .black)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : Color(hex: "DDDDDD"))
            }
            .padding(16)
            .background(isSelected ? Color.black.opacity(0.04) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(isSelected ? 0 : 0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CameraSheetView()
}
