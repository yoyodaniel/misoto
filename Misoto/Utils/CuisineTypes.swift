//
//  CuisineTypes.swift
//  Misoto
//
//  Comprehensive list of cuisine types for recipe categorization
//

import Foundation

class CuisineTypes {
    static let allCuisines: [String] = [
        // Asian
        "Chinese",
        "Japanese",
        "Korean",
        "Thai",
        "Vietnamese",
        "Indian",
        "Indonesian",
        "Malaysian",
        "Singaporean",
        "Filipino",
        "Burmese",
        "Cambodian",
        "Laotian",
        "Sri Lankan",
        "Pakistani",
        "Bangladeshi",
        
        // European
        "Italian",
        "French",
        "Spanish",
        "Greek",
        "Turkish",
        "German",
        "British",
        "Irish",
        "Scottish",
        "Polish",
        "Russian",
        "Swedish",
        "Norwegian",
        "Danish",
        "Finnish",
        "Dutch",
        "Belgian",
        "Swiss",
        "Austrian",
        "Portuguese",
        "Czech",
        "Hungarian",
        "Romanian",
        "Bulgarian",
        
        // Middle Eastern
        "Lebanese",
        "Israeli",
        "Iranian",
        "Iraqi",
        "Syrian",
        "Egyptian",
        "Moroccan",
        "Tunisian",
        "Algerian",
        "Yemeni",
        
        // African
        "Ethiopian",
        "Nigerian",
        "South African",
        "Ghanaian",
        "Kenyan",
        "Senegalese",
        "Tanzanian",
        
        // American
        "American",
        "Mexican",
        "Tex-Mex",
        "Cuban",
        "Brazilian",
        "Argentinian",
        "Peruvian",
        "Colombian",
        "Chilean",
        "Venezuelan",
        "Jamaican",
        "Caribbean",
        
        // Other
        "Australian",
        "New Zealand",
        "Fusion",
        "Mediterranean",
        "Middle Eastern",
        "International",
        "Vegetarian",
        "Vegan",
        "Other"
    ]
    
    static func searchCuisines(query: String) -> [String] {
        let lowercaseQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        if lowercaseQuery.isEmpty {
            return allCuisines
        }
        return allCuisines.filter { cuisine in
            cuisine.lowercased().contains(lowercaseQuery)
        }
    }
}


