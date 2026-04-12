//
//  IngredientNameField.swift
//  Misoto
//
//  A TextField with typeahead autocomplete from the canonical ingredient database.
//  Shows suggestions as the user types, allowing them to tap to select.
//  Includes a "Browse all" option to open the full ingredient browser.
//
//  Created by Daniel Chan on 08.02.2026.
//

import SwiftUI

// MARK: - PreferenceKey for capturing field position

private struct FieldGlobalMinXKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct IngredientNameField: View {
    @Binding var text: String
    var focusField: FocusState<Int?>.Binding
    var focusIndex: Int
    
    @State private var suggestions: [IngredientDatabase.Suggestion] = []
    @State private var showSuggestions = false
    @State private var isUserTyping = false
    @State private var fieldMinX: CGFloat = 0
    @State private var showBrowser = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(LocalizedString("Ingredient", comment: "Ingredient placeholder"), text: $text)
                .autocapitalization(.words)
                .focused(focusField, equals: focusIndex)
                .onChange(of: text) { _, newValue in
                    guard isUserTyping else { return }
                    updateSuggestions(for: newValue)
                }
                .onChange(of: focusField.wrappedValue) { _, newFocus in
                    if newFocus == focusIndex {
                        isUserTyping = true
                        updateSuggestions(for: text)
                    } else {
                        // Small delay to allow tap on suggestion to register
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showSuggestions = false
                            isUserTyping = false
                        }
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: FieldGlobalMinXKey.self,
                            value: geo.frame(in: .global).minX
                        )
                    }
                )
                .onPreferenceChange(FieldGlobalMinXKey.self) { value in
                    fieldMinX = value
                }
            
            if showSuggestions && !suggestions.isEmpty {
                let screenWidth = UIScreen.main.bounds.width
                let horizontalPadding: CGFloat = 0
                let dropdownWidth = screenWidth
                let xOffset = -fieldMinX
                
                suggestionsList
                    .frame(width: dropdownWidth)
                    .offset(x: xOffset)
                    .frame(width: 0, alignment: .leading) // Zero layout footprint
            }
        }
        .sheet(isPresented: $showBrowser) {
            IngredientBrowserSheet(selectedIngredientName: $text)
        }
    }
    
    // MARK: - Suggestions Dropdown
    
    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { suggestion in
                Button {
                    selectSuggestion(suggestion)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: suggestion.category.iconName)
                            .font(.system(size: 13))
                            .foregroundColor(.accentColor)
                            .frame(width: 18)
                        
                        Text(suggestion.name)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(suggestion.category.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.trailing, 30)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.leading, 34)
            }
            
            // "Browse all" footer
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    showSuggestions = false
                }
                showBrowser = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                    
                    Text(LocalizedString("Browse all ingredients", comment: "Open ingredient browser"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.accentColor.opacity(0.6))
                        .padding(.trailing, 30)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 4)
        .zIndex(999)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Logic
    
    private func updateSuggestions(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            withAnimation(.easeOut(duration: 0.15)) {
                suggestions = []
                showSuggestions = false
            }
            return
        }
        
        let newSuggestions = IngredientDatabase.shared.suggestions(for: trimmed, limit: 3)
        withAnimation(.easeOut(duration: 0.15)) {
            suggestions = newSuggestions
            showSuggestions = !newSuggestions.isEmpty
        }
    }
    
    private func selectSuggestion(_ suggestion: IngredientDatabase.Suggestion) {
        isUserTyping = false
        text = suggestion.name
        withAnimation(.easeOut(duration: 0.15)) {
            suggestions = []
            showSuggestions = false
        }
    }
}

#if DEBUG
struct IngredientNameField_Preview: PreviewProvider {
    struct Wrapper: View {
        @State var text = ""
        @FocusState var focus: Int?
        
        var body: some View {
            VStack {
                IngredientNameField(
                    text: $text,
                    focusField: $focus,
                    focusIndex: 0
                )
                .padding()
                
                Spacer()
            }
        }
    }
    
    static var previews: some View {
        Wrapper()
    }
}
#endif
