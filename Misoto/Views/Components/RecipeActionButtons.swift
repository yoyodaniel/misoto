//
//  RecipeActionButtons.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RecipeActionButtons: View {
    let isFavorite: Bool
    let onFavoriteTapped: () -> Void
    let onWriteNoteTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Favorite Button
            Button(action: onFavoriteTapped) {
                Text(LocalizedString("Collect", comment: "Favorite button"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFavorite ? Color.red : Color.blue)
                    .cornerRadius(12)
            }
            
            // Write Note Button
            Button(action: onWriteNoteTapped) {
                Text(LocalizedString("Write Note", comment: "Write note button"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    RecipeActionButtons(
        isFavorite: false,
        onFavoriteTapped: {},
        onWriteNoteTapped: {}
    )
    .padding()
}

