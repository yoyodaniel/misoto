//
//  StepVideoThumbnail.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct StepVideoThumbnail: View {
    let imageURL: String?
    let videoURL: String?
    let onPlayTapped: (() -> Void)?
    
    @State private var showVideoPlayer = false
    
    var body: some View {
        ZStack {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .cornerRadius(12)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                    }
            }
            
            // Play Button Overlay
            if videoURL != nil || onPlayTapped != nil {
                Button(action: {
                    if let onPlayTapped = onPlayTapped {
                        onPlayTapped()
                    } else if let videoURL = videoURL, let url = URL(string: videoURL) {
                        // Open video URL
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    StepVideoThumbnail(
        imageURL: nil,
        videoURL: nil,
        onPlayTapped: nil
    )
    .padding()
}

