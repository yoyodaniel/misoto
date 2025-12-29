//
//  ServingsPickerView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct ServingsPickerView: View {
    @Binding var servings: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Servings picker - compact height for inline display
            Picker("", selection: $servings) {
                ForEach(1..<21, id: \.self) { serving in
                    Text("\(serving)").tag(serving)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 120, height: 80)
            .labelsHidden()
            
            Text(NSLocalizedString("servings", comment: "Servings unit"))
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize()
        }
    }
}

#Preview {
    ServingsPickerView(servings: .constant(4))
        .padding()
}

