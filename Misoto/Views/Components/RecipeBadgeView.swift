//
//  RecipeBadgeView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RecipeBadgeView: View {
    let badge: RecipeBadge
    
    var body: some View {
        Text(badge.text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(badgeBackgroundColor)
            .cornerRadius(12)
    }
    
    private var badgeColor: Color {
        switch badge.type {
        case .newbieTop:
            return .orange
        case .trending:
            return .red
        case .featured:
            return .blue
        case .popular:
            return .purple
        }
    }
    
    private var badgeBackgroundColor: Color {
        switch badge.type {
        case .newbieTop:
            return Color.orange.opacity(0.1)
        case .trending:
            return Color.red.opacity(0.1)
        case .featured:
            return Color.blue.opacity(0.1)
        case .popular:
            return Color.purple.opacity(0.1)
        }
    }
}

#Preview {
    HStack {
        RecipeBadgeView(badge: RecipeBadge(type: .newbieTop, text: "新手榜TOP50"))
        RecipeBadgeView(badge: RecipeBadge(type: .trending, text: "Trending"))
    }
    .padding()
}

