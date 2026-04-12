//
//  IngredientBrowserSheet.swift
//  Misoto
//
//  A full-screen searchable browser for all canonical ingredients.
//  Grouped by food category with a search bar for filtering.
//
//  Created by Daniel Chan on 08.02.2026.
//

import SwiftUI

struct IngredientBrowserSheet: View {
    @Binding var selectedIngredientName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var groupedIngredients: [(category: Ingredient.FoodCategory, ingredients: [IngredientDatabase.Suggestion])] = []
    @State private var showAllergenLegend = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Allergen Legend
                Section {
                    DisclosureGroup(isExpanded: $showAllergenLegend) {
                        allergenLegendContent
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 13))
                                .foregroundColor(.accentColor)
                            Text(LocalizedString("Allergen Guide", comment: "Allergen legend title"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                if groupedIngredients.isEmpty {
                    ContentUnavailableView(
                        LocalizedString("No ingredients found", comment: "Empty state"),
                        systemImage: "magnifyingglass",
                        description: Text(LocalizedString("Try a different search term", comment: "Empty state hint"))
                    )
                } else {
                    ForEach(groupedIngredients, id: \.category) { group in
                        Section {
                            ForEach(group.ingredients) { ingredient in
                                Button {
                                    selectedIngredientName = ingredient.name
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: ingredient.category.iconName)
                                            .font(.system(size: 14))
                                            .foregroundColor(.accentColor)
                                            .frame(width: 24)
                                        
                                        Text(ingredient.name)
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        // Show allergen dots if any
                                        let allergens = IngredientDatabase.shared.allergens(for: ingredient.id)
                                        if !allergens.isEmpty {
                                            HStack(spacing: 4) {
                                                ForEach(allergens.prefix(3), id: \.self) { allergen in
                                                    allergenDot(for: allergen)
                                                }
                                                if allergens.count > 3 {
                                                    Text("+\(allergens.count - 3)")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack(spacing: 8) {
                                Image(systemName: group.category.iconName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                                Text(group.category.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Spacer()
                                
                                Text("\(group.ingredients.count)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizedString("Ingredients", comment: "Ingredient browser title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: LocalizedString("Search ingredients...", comment: "Search prompt")
            )
            .onChange(of: searchText) { _, newValue in
                loadIngredients(query: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadIngredients(query: "")
        }
    }
    
    // MARK: - Helpers
    
    private func loadIngredients(query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        groupedIngredients = IngredientDatabase.shared.allIngredients(matching: q.isEmpty ? nil : q)
    }
    
    // MARK: - Allergen Legend Content
    
    private var allergenLegendContent: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(Ingredient.Allergen.allCases, id: \.self) { allergen in
                HStack(spacing: 8) {
                    Circle()
                        .fill(allergenColor(for: allergen))
                        .frame(width: 10, height: 10)
                    Text(allergen.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Allergen Colors
    
    private func allergenColor(for allergen: Ingredient.Allergen) -> Color {
        switch allergen {
        case .dairy:     return .blue
        case .eggs:      return .yellow
        case .fish:      return .cyan
        case .shellfish: return .orange
        case .treeNuts:  return .brown
        case .peanuts:   return Color(red: 0.76, green: 0.60, blue: 0.42)  // tan
        case .gluten:    return Color(red: 0.85, green: 0.65, blue: 0.13)  // wheat/amber
        case .soy:       return .green
        case .sesame:    return .gray
        }
    }
    
    @ViewBuilder
    private func allergenDot(for allergen: Ingredient.Allergen) -> some View {
        Circle()
            .fill(allergenColor(for: allergen))
            .frame(width: 8, height: 8)
            .help(allergen.displayName)
    }
}

#if DEBUG
struct IngredientBrowserSheet_Preview: PreviewProvider {
    struct Wrapper: View {
        @State var name = ""
        @State var showSheet = true
        
        var body: some View {
            Text("Selected: \(name)")
                .sheet(isPresented: $showSheet) {
                    IngredientBrowserSheet(selectedIngredientName: $name)
                }
        }
    }
    
    static var previews: some View {
        Wrapper()
    }
}
#endif
