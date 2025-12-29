//
//  TimePickerView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct TimePickerView: View {
    @Binding var totalMinutes: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Minutes picker - compact height
            Picker("", selection: $totalMinutes) {
                ForEach(0..<600, id: \.self) { minute in
                    Text("\(minute)").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
            .labelsHidden()
            
            Text(NSLocalizedString("minutes", comment: "Minutes unit"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TimePickerView(totalMinutes: .constant(30))
        .padding()
}

