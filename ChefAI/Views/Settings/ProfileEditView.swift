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
                Color.white.ignoresSafeArea()

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

                        // Main Goal Section
                        PreferenceSectionView(
                            title: "Main Goal",
                            icon: "target",
                            isExpanded: expandedSections.contains("goal"),
                            onToggle: { toggleSection("goal") }
                        ) {
                            CompactMultipleChoiceSelector(
                                items: MainGoal.allCases,
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
                                items: ExtendedDietaryRestriction.allCases,
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

                        // Meal Preferences Section
                        PreferenceSectionView(
                            title: "Meal Preferences",
                            icon: "fork.knife.circle.fill",
                            isExpanded: expandedSections.contains("meals"),
                            onToggle: { toggleSection("meals") }
                        ) {
                            TagPicker(
                                items: MealPreference.allCases,
                                selectedItems: $viewModel.mealPreferences,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Time Availability Section
                        PreferenceSectionView(
                            title: "Cooking Time",
                            icon: "clock.fill",
                            isExpanded: expandedSections.contains("time"),
                            onToggle: { toggleSection("time") }
                        ) {
                            CompactMultipleChoiceSelector(
                                items: TimeAvailability.allCases,
                                selected: $viewModel.timeAvailability,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Cooking Equipment Section
                        PreferenceSectionView(
                            title: "Equipment",
                            icon: "wrench.and.screwdriver.fill",
                            isExpanded: expandedSections.contains("equipment"),
                            onToggle: { toggleSection("equipment") }
                        ) {
                            TagPicker(
                                items: CookingEquipment.allCases,
                                selectedItems: $viewModel.cookingEquipment,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Cooking Struggles Section
                        PreferenceSectionView(
                            title: "Cooking Struggles",
                            icon: "exclamationmark.triangle.fill",
                            isExpanded: expandedSections.contains("struggles"),
                            onToggle: { toggleSection("struggles") }
                        ) {
                            TagPicker(
                                items: CookingStruggle.allCases,
                                selectedItems: $viewModel.cookingStruggles,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Adventure Level Section
                        PreferenceSectionView(
                            title: "Adventure Level",
                            icon: "sparkles",
                            isExpanded: expandedSections.contains("adventure"),
                            onToggle: { toggleSection("adventure") }
                        ) {
                            CompactMultipleChoiceSelector(
                                items: AdventureLevel.allCases,
                                selected: $viewModel.adventureLevel,
                                iconProvider: { $0.icon }
                            )
                        }

                        // Cuisine Preferences Section (Legacy)
                        PreferenceSectionView(
                            title: "Favorite Cuisines",
                            icon: "globe",
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
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.black)
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
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }

                    // Camera overlay
                    Circle()
                        .fill(Color.black)
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
                .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
                        .frame(width: 24)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.03))
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())

            // Content
            if isExpanded {
                content()
                    .padding()
                    .background(Color.black.opacity(0.02))
                    .cornerRadius(12)
                    .padding(.top, 1)
            }
        }
        .background(Color.black.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
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
                                .foregroundColor(selected == item ? .white : .black)
                        }

                        Text(item.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selected == item ? .white : .black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(selected == item ? Color.black : Color.black.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected == item ? Color.black : Color.black.opacity(0.1), lineWidth: 1)
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
                    .foregroundColor(.gray)
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            TextField("", text: $text)
                .font(.body)
                .foregroundColor(.black)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .padding()
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
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
                    .foregroundColor(.gray)
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(.black)
                .scrollContentBackground(.hidden)
                .frame(height: 100)
                .padding()
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
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
