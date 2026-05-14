//
//  RecipeSearchKeywordMigrationService.swift
//  Misoto
//
//  Created by Codex on 08.05.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class RecipeSearchKeywordMigrationService {
    private let firestore = FirebaseManager.shared.firestore
    private let recipesCollection = "recipes"

    private let lastCreatedAtCheckpointKey = "recipeKeywordMigration.lastCreatedAt"
    private let lastRecipeIDCheckpointKey = "recipeKeywordMigration.lastRecipeID"

    func runBackfill(batchSize: Int = 200) async throws -> Int {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw MigrationError.unauthorized
        }

        let safeBatchSize = max(1, min(batchSize, 500))
        var query = firestore.collection(recipesCollection)
            .whereField("authorID", isEqualTo: currentUserID)
            .order(by: "createdAt")
            .order(by: FieldPath.documentID())
            .limit(to: safeBatchSize)

        if let checkpointDate = checkpointDate(),
           let checkpointRecipeID = checkpointRecipeID() {
            query = query.start(after: [checkpointDate, checkpointRecipeID])
        }

        let snapshot = try await query.getDocuments()
        guard !snapshot.documents.isEmpty else {
            return 0
        }

        var updatedCount = 0
        for chunk in snapshot.documents.chunked(into: 200) {
            let batch = firestore.batch()
            for doc in chunk {
                guard let recipe = try? doc.data(as: Recipe.self) else { continue }
                if recipe.searchKeywords.isEmpty {
                    let keywords = buildSearchKeywords(for: recipe)
                    batch.updateData(["searchKeywords": keywords], forDocument: doc.reference)
                    updatedCount += 1
                }
            }
            try await batch.commit()
        }

        if let last = snapshot.documents.last,
           let recipe = try? last.data(as: Recipe.self) {
            saveCheckpoint(createdAt: recipe.createdAt, recipeID: last.documentID)
        }

        return updatedCount
    }

    func resetCheckpoint() {
        UserDefaults.standard.removeObject(forKey: lastCreatedAtCheckpointKey)
        UserDefaults.standard.removeObject(forKey: lastRecipeIDCheckpointKey)
    }

    // MARK: - Helpers

    private func buildSearchKeywords(for recipe: Recipe) -> [String] {
        var tokens = Set<String>()

        func addToken(_ value: String?, includePrefixes: Bool) {
            guard let value else { return }
            let normalized = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { return }
            tokens.insert(normalized)

            let separators = CharacterSet.alphanumerics.inverted
            let splitTokens = normalized
                .components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count >= 2 }
            splitTokens.forEach { token in
                tokens.insert(token)
                guard includePrefixes, token.count >= 3 else { return }
                let maxPrefix = min(8, token.count)
                for prefixLength in 3...maxPrefix {
                    tokens.insert(String(token.prefix(prefixLength)))
                }
            }
        }

        addToken(recipe.title, includePrefixes: true)
        addToken(recipe.titleEnglish, includePrefixes: true)
        addToken(recipe.titleLocal, includePrefixes: true)
        addToken(recipe.titleOriginal, includePrefixes: true)
        addToken(recipe.description, includePrefixes: false)
        addToken(recipe.cuisine, includePrefixes: true)
        addToken(recipe.cuisineEnglish, includePrefixes: true)
        addToken(recipe.authorName, includePrefixes: true)
        addToken(recipe.authorUsername, includePrefixes: true)
        recipe.ingredients.forEach { addToken($0.name, includePrefixes: true) }

        return Array(tokens).sorted()
    }

    private func saveCheckpoint(createdAt: Date, recipeID: String) {
        UserDefaults.standard.set(createdAt.timeIntervalSince1970, forKey: lastCreatedAtCheckpointKey)
        UserDefaults.standard.set(recipeID, forKey: lastRecipeIDCheckpointKey)
    }

    private func checkpointDate() -> Date? {
        let interval = UserDefaults.standard.double(forKey: lastCreatedAtCheckpointKey)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    private func checkpointRecipeID() -> String? {
        UserDefaults.standard.string(forKey: lastRecipeIDCheckpointKey)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
