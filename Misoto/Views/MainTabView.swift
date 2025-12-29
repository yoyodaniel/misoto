//
//  MainTabView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var showUploadRecipe = false
    @State private var showExtractFromImage = false
    @State private var showExtractFromLink = false
    @State private var showAddMenuOptions = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var imageForExtraction: UIImage?
    
    var body: some View {
        ZStack {
            TabView {
                ExploreView()
                    .tabItem {
                        Label(NSLocalizedString("Explore", comment: "Explore tab"), systemImage: "menucard.fill")
                    }
                
                AccountView()
                    .tabItem {
                        Label(NSLocalizedString("Account", comment: "Account tab"), systemImage: "person.fill")
                    }
            }
            
            // Floating Upload Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddMenuOptions = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .offset(y: -40)
                    .padding(.trailing, 20)
                }
            }
        }
        .confirmationDialog(
            NSLocalizedString("Add Menu", comment: "Add menu dialog title"),
            isPresented: $showAddMenuOptions,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("Manual Entry", comment: "Manual entry option")) {
                showUploadRecipe = true
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(NSLocalizedString("Take Picture", comment: "Take picture option")) {
                    showCamera = true
                }
            }
            
            Button(NSLocalizedString("Extract from Image", comment: "Extract from image option")) {
                showExtractFromImage = true
            }
            
            Button(NSLocalizedString("Extract from Link", comment: "Extract from link option")) {
                showExtractFromLink = true
            }
            
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        }
        .sheet(isPresented: $showUploadRecipe) {
            UploadRecipeView()
        }
        .fullScreenCover(isPresented: $showExtractFromImage) {
            ExtractMenuFromImageView(initialImage: imageForExtraction)
                .onDisappear {
                    // Clear images when view is dismissed
                    capturedImage = nil
                    imageForExtraction = nil
                }
        }
        .sheet(isPresented: $showExtractFromLink) {
            ExtractMenuFromLinkView()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { image in
                // Set the image for extraction
                imageForExtraction = image
                capturedImage = image
                // Dismiss camera and show extract view
                showCamera = false
                // Small delay to ensure camera dismisses before showing extract view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showExtractFromImage = true
                }
            }
            .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    MainTabView()
}
