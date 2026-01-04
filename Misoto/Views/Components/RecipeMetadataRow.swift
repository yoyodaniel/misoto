//
//  RecipeMetadataRow.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RecipeMetadataRow: View {
    let totalTime: Int // in minutes
    let difficulty: Recipe.Difficulty
    let favoriteCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Time
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                Text(LocalizedString("Time", comment: "Time label"))
                    .font(.system(size: 14))
                Text(formatTime(totalTime))
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.primary)
            
            // Difficulty
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                Text(LocalizedString("Difficulty", comment: "Difficulty label"))
                    .font(.system(size: 14))
                Text(difficulty.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.primary)
            
            // Favorites
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                Text(LocalizedString("Collected by", comment: "Collected by label"))
                    .font(.system(size: 14))
                Text("\(favoriteCount)")
                    .font(.system(size: 14, weight: .medium))
                Text(LocalizedString("people", comment: "People count"))
                    .font(.system(size: 14))
            }
            .foregroundColor(.primary)
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return LocalizedString("About %d minutes", comment: "Time format for minutes")
                .replacingOccurrences(of: "%d", with: "\(minutes)")
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return LocalizedString("About %d hours", comment: "Time format for hours")
                    .replacingOccurrences(of: "%d", with: "\(hours)")
            } else {
                return String(format: LocalizedString("About %d-%d minutes", comment: "Time range format"), minutes - 10, minutes)
            }
        }
    }
}

#Preview {
    RecipeMetadataRow(
        totalTime: 15,
        difficulty: .c,
        favoriteCount: 1309
    )
    .padding()
}

