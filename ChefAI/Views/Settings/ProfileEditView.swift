//
//  ProfileEditView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedSections: Set<String> = ["basic"]
    @State private var showingImagePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture
                        profilePictureSection

                        // Basic Info Section
                        PreferenceSectionView(
                            title: "Basic Info",
                            icon: "person.fill",
                            isExpanded: expandedSections.contains("basic"),
                            onToggle: { toggleSection("basic") }
                        ) {
                            VStack(spacing: 16) {
                                ProfileTextField(
                                    icon: "person.fill",
                                    title: "Name",
                                    text: $viewModel.userName
                                )

                                ProfileTextField(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    text: $viewModel.userEmail,
                                    keyboardType: .emailAddress
                                )

                                ProfileTextEditor(
                                    icon: "text.alignleft",
                                    title: "Bio",
                                    text: $viewModel.userBio
                                )
                            }
                        }

                        // Cooking Goal Section
                        PreferenceSectionView(
                            title: "Cooking Goal",
                            icon: "target",
                            isExpanded: expandedSections.contains("goal"),
                            onToggle: { toggleSection("goal") }
                        ) {
                            CompactMultipleChoiceSelector(
                                items: CookingGoal.allCases,
                                selected: $viewModel.mainGoal,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Dietary Restrictions Section
                        PreferenceSectionView(
                            title: "Dietary Restrictions",
                            icon: "leaf.fill",
                            isExpanded: expandedSections.contains("dietary"),
                            onToggle: { toggleSection("dietary") }
                        ) {
                            TagPicker(
                                items: DietaryRestriction.allCases,
                                selectedItems: $viewModel.dietaryRestrictions,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Cooking Skill Level Section
                        PreferenceSectionView(
                            title: "Skill Level",
                            icon: "chart.bar.fill",
                            isExpanded: expandedSections.contains("skill"),
                            onToggle: { toggleSection("skill") }
                        ) {
                            CompactMultipleChoiceSelector(
                                items: SkillLevel.allCases,
                                selected: $viewModel.cookingSkillLevel,
                                iconProvider: nil
                            )
                        }

                        // Cooking Style Section
                        PreferenceSectionView(
                            title: "Cooking Style",
                            icon: "frying.pan.fill",
                            isExpanded: expandedSections.contains("style"),
                            onToggle: { toggleSection("style") }
                        ) {
                            CompactMultipleChoiceSelector(
                                items: CookingStyle.allCases,
                                selected: $viewModel.cookingStyle,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Cuisine Preferences Section
                        PreferenceSectionView(
                            title: "Favorite Cuisines",
                            icon: "fork.knife",
                            isExpanded: expandedSections.contains("cuisine"),
                            onToggle: { toggleSection("cuisine") }
                        ) {
                            TagPicker(
                                items: CuisineType.allCases,
                                selectedItems: $viewModel.cuisinePreferences,
                                iconProvider: { $0.icon }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerWithCrop { image in
                    viewModel.updateProfileImage(image)
                }
            }
        }
    }

    private var profilePictureSection: some View {
        VStack(spacing: 12) {
            Button {
                showingImagePicker = true
            } label: {
                ZStack {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Camera overlay
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .offset(x: 35, y: 35)
                }
            }

            Text("Tap to change photo")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 16)
    }

    private func toggleSection(_ section: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

// MARK: - Preference Section View

struct PreferenceSectionView<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            if isExpanded {
                content()
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .padding(.top, 1)
            }
        }
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Compact Multiple Choice Selector

struct CompactMultipleChoiceSelector<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let items: [T]
    @Binding var selected: T?
    var iconProvider: ((T) -> String)?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(items), id: \.self) { item in
                Button(action: {
                    selected = item
                }) {
                    HStack(spacing: 8) {
                        if let iconProvider = iconProvider {
                            Image(systemName: iconProvider(item))
                                .font(.system(size: 16))
                                .foregroundColor(selected == item ? .black : .white)
                        }

                        Text(item.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selected == item ? .black : .white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(selected == item ? Color.white : Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected == item ? Color.white : Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Profile Text Field

struct ProfileTextField: View {
    let icon: String
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            TextField("", text: $text)
                .font(.body)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Profile Text Editor

struct ProfileTextEditor: View {
    let icon: String
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(height: 100)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Image Picker with Crop

struct ImagePickerWithCrop: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true // This enables the crop/move interface
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerWithCrop

        init(_ parent: ImagePickerWithCrop) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Use the edited (cropped) image if available, otherwise use original
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImagePicked(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImagePicked(originalImage)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = SettingsViewModel()
    ProfileEditView(viewModel: viewModel)
}
