//
//  TimePickerView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

enum TimeUnit: String, CaseIterable {
    case seconds = "seconds"
    case minutes = "minutes"
    case hours = "hours"
    case days = "days"
    
    var displayName: String {
        switch self {
        case .seconds: return NSLocalizedString("seconds", comment: "Seconds unit")
        case .minutes: return NSLocalizedString("minutes", comment: "Minutes unit")
        case .hours: return NSLocalizedString("hours", comment: "Hours unit")
        case .days: return NSLocalizedString("days", comment: "Days unit")
        }
    }
    
    // Convert value in this unit to minutes
    func toMinutes(_ value: Int) -> Int {
        switch self {
        case .seconds: return value / 60
        case .minutes: return value
        case .hours: return value * 60
        case .days: return value * 24 * 60
        }
    }
    
    // Convert minutes to value in this unit
    func fromMinutes(_ minutes: Int) -> Int {
        switch self {
        case .seconds: return minutes * 60
        case .minutes: return minutes
        case .hours: return minutes / 60
        case .days: return minutes / (24 * 60)
        }
    }
    
    // Maximum value for the picker in this unit
    var maxValue: Int {
        switch self {
        case .seconds: return 3600 // 1 hour in seconds
        case .minutes: return 1440 // 1 day in minutes
        case .hours: return 168 // 1 week in hours
        case .days: return 30 // 30 days
        }
    }
}

struct TimePickerView: View {
    @Binding var totalMinutes: Int
    
    @State private var selectedValue: Int
    @State private var selectedUnit: TimeUnit
    
    init(totalMinutes: Binding<Int>) {
        self._totalMinutes = totalMinutes
        // Initialize with current value converted to a reasonable unit
        let minutes = totalMinutes.wrappedValue
        if minutes >= 1440 { // 1 day or more
            _selectedUnit = State(initialValue: .days)
            _selectedValue = State(initialValue: minutes / (24 * 60))
        } else if minutes >= 60 { // 1 hour or more
            _selectedUnit = State(initialValue: .hours)
            _selectedValue = State(initialValue: minutes / 60)
        } else if minutes < 1 && minutes > 0 { // Less than 1 minute
            _selectedUnit = State(initialValue: .seconds)
            _selectedValue = State(initialValue: minutes * 60)
        } else {
            _selectedUnit = State(initialValue: .minutes)
            _selectedValue = State(initialValue: minutes)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Number picker
            Picker("", selection: $selectedValue) {
                ForEach(0..<selectedUnit.maxValue, id: \.self) { value in
                    Text("\(value)")
                        .font(.system(size: 14))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60, height: 100)
            .labelsHidden()
            .onChange(of: selectedValue) { _, _ in
                updateTotalMinutes()
            }
            
            // Unit picker
            Picker("", selection: $selectedUnit) {
                ForEach(TimeUnit.allCases, id: \.self) { unit in
                    Text(unit.displayName)
                        .font(.system(size: 12))
                        .tag(unit)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 70, height: 100)
            .labelsHidden()
            .onChange(of: selectedUnit) { oldUnit, newUnit in
                // Convert current value to new unit
                let currentMinutes = oldUnit.toMinutes(selectedValue)
                selectedValue = newUnit.fromMinutes(currentMinutes)
                // Clamp to max value
                if selectedValue >= newUnit.maxValue {
                    selectedValue = newUnit.maxValue - 1
                }
                updateTotalMinutes()
            }
        }
    }
    
    private func updateTotalMinutes() {
        totalMinutes = selectedUnit.toMinutes(selectedValue)
    }
}

#Preview {
    TimePickerView(totalMinutes: .constant(30))
        .padding()
}

