//
//  AlgoliaRecipeSearchService.swift
//  Misoto
//
//  Created by Codex on 09.05.2026.
//

import FirebaseAuth
import Foundation

@MainActor
final class AlgoliaRecipeSearchService {
    static let shared = AlgoliaRecipeSearchService()

    private struct SearchResponse: Decodable {
        let hits: [SearchHit]
    }

    private struct SearchHit: Decodable {
        let objectID: String
        let id: String?
    }

    private init() {}

    /// Recipe search runs through an authenticated Cloud Function; no Algolia keys ship in the client.
    var isConfigured: Bool {
        Auth.auth().currentUser != nil
    }

    func searchRecipeIDs(query: String, limit: Int) async throws -> [String] {
        guard Auth.auth().currentUser != nil else {
            throw SearchError.notAuthenticated
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        let data = try await BackendAPIProxy.algoliaRecipeSearch(
            query: normalizedQuery,
            limit: max(1, min(limit, 100))
        )
        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.hits.map { $0.id ?? $0.objectID }
    }
}

enum SearchError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return LocalizedString("Please sign in to search recipes.", comment: "Algolia proxy requires auth")
        case .invalidResponse:
            return "Invalid response from recipe search."
        case .requestFailed:
            return "Algolia search request failed."
        }
    }
}
