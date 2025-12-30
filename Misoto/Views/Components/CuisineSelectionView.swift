//
//  CuisineSelectionView.swift
//  Misoto
//
//  Searchable cuisine selection view
//

import SwiftUI

struct CuisineSelectionView: View {
    @Binding var selectedCuisine: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredCuisines: [String] {
        CuisineTypes.searchCuisines(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: NSLocalizedString("Search cuisines...", comment: "Search cuisines placeholder"))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Cuisine list
                List {
                    // Option to clear selection
                    Button(action: {
                        selectedCuisine = nil
                        dismiss()
                    }) {
                        HStack {
                            Text(NSLocalizedString("None", comment: "None option"))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCuisine == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    ForEach(filteredCuisines, id: \.self) { cuisine in
                        Button(action: {
                            selectedCuisine = cuisine
                            dismiss()
                        }) {
                            HStack {
                                Text(cuisine)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedCuisine == cuisine {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(NSLocalizedString("Select Cuisine", comment: "Select cuisine title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Custom search bar component
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    CuisineSelectionView(selectedCuisine: .constant(nil))
}



