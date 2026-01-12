//
//  MainTabView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showUploadRecipe = false
    @State private var showExtractFromImage = false
    @State private var showExtractFromLink = false
    @State private var showExtractFromWebsite = false
    @State private var showAddMenuOptions = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var imageForExtraction: UIImage?
    @State private var pendingExtractionImage: UIImage? // Image waiting to be shown in extract view
    @State private var showLoginSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ExploreView(showLoginSheet: $showLoginSheet)
                    .tabItem {
                        Label(LocalizedString("Explore", comment: "Explore tab"), systemImage: "menucard.fill")
                    }
                    .tag(0)
                
                AccountView(showLoginSheet: $showLoginSheet)
                    .tabItem {
                        Label(LocalizedString("Account", comment: "Account tab"), systemImage: "person.fill")
                    }
                    .tag(1)
            }
            .onChange(of: selectedTab) { _, newTab in
                // If user taps Account tab and is not authenticated, show login sheet
                if newTab == 1 && !authViewModel.isAuthenticated {
                    showLoginSheet = true
                    // Reset to Explore tab after showing login
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTab = 0
                    }
                }
            }
            
            // Floating Upload Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        HapticFeedback.buttonTap()
                        // Check authentication before showing add menu options
                        if Auth.auth().currentUser != nil {
                            showAddMenuOptions = true
                        } else {
                            showLoginSheet = true
                        }
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
            LocalizedString("Add Menu", comment: "Add menu dialog title"),
            isPresented: $showAddMenuOptions,
            titleVisibility: .visible
        ) {
            Button(LocalizedString("Manual Entry", comment: "Manual entry option")) {
                if Auth.auth().currentUser != nil {
                    showUploadRecipe = true
                } else {
                    showLoginSheet = true
                }
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(LocalizedString("Take Picture", comment: "Take picture option")) {
                    if Auth.auth().currentUser != nil {
                        showCamera = true
                    } else {
                        showLoginSheet = true
                    }
                }
            }
            
            Button(LocalizedString("Extract from Image", comment: "Extract from image option")) {
                if Auth.auth().currentUser != nil {
                    // Clear any pending image when manually selecting extract from image
                    pendingExtractionImage = nil
                    showExtractFromImage = true
                } else {
                    showLoginSheet = true
                }
            }
            
            Button(LocalizedString("Extract from Link", comment: "Extract from link option")) {
                if Auth.auth().currentUser != nil {
                    showExtractFromLink = true
                } else {
                    showLoginSheet = true
                }
            }
            
            Button(LocalizedString("Extract from Website", comment: "Extract from website option")) {
                if Auth.auth().currentUser != nil {
                    showExtractFromWebsite = true
                } else {
                    showLoginSheet = true
                }
            }
            
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showUploadRecipe) {
            UploadRecipeView()
        }
        .fullScreenCover(isPresented: $showExtractFromImage) {
            // Use pendingExtractionImage if available (from camera), otherwise use imageForExtraction (from manual selection)
            ExtractMenuFromImageView(initialImage: pendingExtractionImage ?? imageForExtraction)
                .onDisappear {
                    // Clear images when view is dismissed
                    capturedImage = nil
                    imageForExtraction = nil
                    pendingExtractionImage = nil
                }
        }
        .sheet(isPresented: $showExtractFromLink) {
            ExtractMenuFromLinkView()
        }
        .sheet(isPresented: $showExtractFromWebsite) {
            ExtractMenuFromWebsiteView()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { image in
                // Store the image in both variables
                // pendingExtractionImage is used specifically for the extract view
                // This ensures the image is available when the view is created
                imageForExtraction = image
                capturedImage = image
                pendingExtractionImage = image
                
                // Dismiss camera first
                showCamera = false
                
                // Use a small delay to ensure camera fully dismisses and state is updated
                // before showing extract view
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
                    // Verify image is still set before showing extract view
                    if pendingExtractionImage != nil {
                        showExtractFromImage = true
                    }
                }
            }
            .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    MainTabView()
}
