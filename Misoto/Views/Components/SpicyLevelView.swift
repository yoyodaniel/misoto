//
//  SpicyLevelView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct SpicyLevelView: View {
    let spicyLevel: Recipe.SpicyLevel
    @Binding var selectedSpicyLevel: Recipe.SpicyLevel
    
    // Spicy level descriptions
    private func description(for level: Recipe.SpicyLevel) -> String {
        switch level {
        case .none:
            return LocalizedString("None", comment: "No spice level")
        case .one:
            return LocalizedString("Mild", comment: "Mild spice level")
        case .two:
            return LocalizedString("Hot", comment: "Hot spice level")
        case .three:
            return LocalizedString("Very Hot", comment: "Very hot spice level")
        case .four:
            return LocalizedString("Extreme", comment: "Extreme spice level")
        case .five:
            return LocalizedString("Insane", comment: "Insane spice level")
        }
    }
    
    // Convert SpicyLevel to Int for picker
    private var selectedLevel: Int {
        selectedSpicyLevel.rawValue
    }
    
    private func updateSpicyLevel(_ level: Int) {
        if let newLevel = Recipe.SpicyLevel(rawValue: level) {
            selectedSpicyLevel = newLevel
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Fire icons on the left
            HStack(spacing: 4) {
                if selectedSpicyLevel != .none {
                    ForEach(0..<selectedSpicyLevel.chiliCount, id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Description text
            Text(description(for: selectedSpicyLevel))
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            // Spacer to push picker to the right
            Spacer()
            
            // Picker on the right
            Picker("", selection: Binding(
                get: { selectedLevel },
                set: { updateSpicyLevel($0) }
            )) {
                ForEach(0...5, id: \.self) { level in
                    Text("\(level)").tag(level)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60, height: 100)
        }
    }
}

#Preview {
    SpicyLevelView(
        spicyLevel: .three,
        selectedSpicyLevel: .constant(.three)
    )
    .padding()
}

