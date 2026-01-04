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
        "Sichuan",
        "Cantonese",
        "Hunan",
        "Shanghainese",
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
        "Surinam",
        
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
        let results: [String]
        if lowercaseQuery.isEmpty {
            results = allCuisines
        } else {
            results = allCuisines.filter { cuisine in
                // Search in both English and translated names
                let englishMatch = cuisine.lowercased().contains(lowercaseQuery)
                let translatedName = CuisineTranslations.translatedName(for: cuisine)
                let translatedMatch = translatedName.lowercased().contains(lowercaseQuery)
                return englishMatch || translatedMatch
            }
        }
        // Sort by translated names alphabetically based on current language
        return results.sorted { cuisine1, cuisine2 in
            let translated1 = CuisineTranslations.translatedName(for: cuisine1)
            let translated2 = CuisineTranslations.translatedName(for: cuisine2)
            return translated1.localizedCaseInsensitiveCompare(translated2) == .orderedAscending
        }
    }
}




