//
//  CameraSheetView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct CameraSheetView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Add Fridge Photo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    VStack(spacing: 16) {
                        // Camera option
                        Button(action: { viewModel.presentCamera() }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                Text("Take Photo")
                                    .font(.headline)
                                Spacer()
                            }
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }

                        // Photo library option
                        Button(action: { viewModel.presentPhotoPicker() }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .font(.title3)
                                Text("Choose from Library")
                                    .font(.headline)
                                Spacer()
                            }
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $viewModel.isShowingCamera) {
                ImagePicker(
                    sourceType: .camera,
                    selectedImage: $viewModel.selectedImage,
                    onImageSelected: { image in
                        viewModel.imageSelected(image)
                    }
                )
            }
            .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
                ImagePicker(
                    sourceType: .photoLibrary,
                    selectedImage: $viewModel.selectedImage,
                    onImageSelected: { image in
                        viewModel.imageSelected(image)
                    }
                )
            }
            .fullScreenCover(isPresented: $viewModel.isShowingPreview) {
                ImagePreviewView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    CameraSheetView()
}
