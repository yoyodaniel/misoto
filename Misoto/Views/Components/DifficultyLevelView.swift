//
//  DifficultyLevelView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct DifficultyLevelView: View {
    let difficulty: Recipe.Difficulty
    @Binding var selectedDifficulty: Recipe.Difficulty
    
    var body: some View {
        // Difficulty level buttons - evenly distributed
        HStack(spacing: 8) {
            ForEach(Recipe.Difficulty.allCases, id: \.self) { level in
                Button(action: {
                    selectedDifficulty = level
                }) {
                    Text(level.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedDifficulty == level ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedDifficulty == level ? Color.accentColor : Color.gray.opacity(0.2))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    DifficultyLevelView(
        difficulty: .a,
        selectedDifficulty: .constant(.a)
    )
    .padding()
}

