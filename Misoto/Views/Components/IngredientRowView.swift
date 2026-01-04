//
//  IngredientRowView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Blue bullet point
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
                .padding(.top, 8)
            
            // Amount, unit, and ingredient name with spacing
            Text(formatIngredient())
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatIngredient() -> String {
        var parts: [String] = []
        
        // Add amount if available
        if !ingredient.amount.isEmpty {
            parts.append(ingredient.amount)
        }
        
        // Add unit if available
        if !ingredient.unit.isEmpty {
            let translatedUnit = UnitTranslations.abbreviation(for: ingredient.unit, amount: ingredient.amount)
            parts.append(translatedUnit)
        }
        
        // Add ingredient name
        parts.append(ingredient.name)
        
        // Join all parts with spaces
        return parts.joined(separator: " ")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        IngredientRowView(ingredient: Ingredient(amount: "2", unit: "根", name: "日本豆腐"))
        IngredientRowView(ingredient: Ingredient(amount: "4", unit: "个", name: "鸡蛋"))
        IngredientRowView(ingredient: Ingredient(amount: "150", unit: "g", name: "虾仁"))
        IngredientRowView(ingredient: Ingredient(amount: "30", unit: "ml", name: "水"))
        IngredientRowView(ingredient: Ingredient(amount: "适量", unit: "", name: "葱花"))
    }
    .padding()
}

