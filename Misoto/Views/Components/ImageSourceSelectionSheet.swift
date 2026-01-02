//
//  ImageSourceSelectionSheet.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct ImageSourceSelectionSheet: View {
    let onTakePicture: () -> Void
    let onSelectFromLibrary: () -> Void
    let onCancel: () -> Void
    let showCameraOption: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and message
            VStack(spacing: 8) {
                Text(LocalizedString("Add Dish Image", comment: "Add dish image dialog title"))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(LocalizedString("Choose how you want to add an image", comment: "Add image alert message"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Action buttons
            VStack(spacing: 0) {
                if showCameraOption {
                    Button(action: {
                        onTakePicture()
                    }) {
                        Text(LocalizedString("Take picture", comment: "Take picture option"))
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                }
                
                Button(action: {
                    onSelectFromLibrary()
                }) {
                    Text(LocalizedString("Select from Photo Library", comment: "Select from photo library option"))
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // Cancel button
            Button(action: {
                onCancel()
            }) {
                Text(LocalizedString("Cancel", comment: "Cancel button"))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 270)
        .background(Color.clear)
        .presentationDetents([.height(showCameraOption ? 200 : 170)])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    ImageSourceSelectionSheet(
        onTakePicture: {},
        onSelectFromLibrary: {},
        onCancel: {},
        showCameraOption: true
    )
}

