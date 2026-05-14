//
//  BackendAPIProxy.swift
//  Misoto
//
//  Authenticated Firebase Callable wrappers — API secrets live only in Cloud Functions.
//

import FirebaseAuth
import FirebaseFunctions
import Foundation

// MARK: - Backend API proxy

enum BackendAPIProxy {

    private static let region = "us-central1"

    private static var functions: Functions {
        Functions.functions(region: region)
    }

    static func openAIChatCompletions(requestBody: [String: Any]) async throws -> Data {
        guard Auth.auth().currentUser != nil else {
            throw OpenAIError.notAuthenticated
        }
        let callable = functions.httpsCallable("openaiChatCompletions")
        let result = try await callable.call(["openaiRequest": requestBody])
        return try decodePayload(result.data, httpError: OpenAIError.httpError, apiError: OpenAIError.apiError, invalid: OpenAIError.invalidResponse)
    }

    static func usdaFoodsSearch(query: String, dataTypes: String?, pageSize: Int) async throws -> Data {
        guard Auth.auth().currentUser != nil else {
            throw USDAProxyError.notAuthenticated
        }
        var payload: [String: Any] = ["query": query, "pageSize": pageSize]
        if let dataTypes {
            payload["dataTypes"] = dataTypes
        }
        let callable = functions.httpsCallable("usdaFoodsSearchProxy")
        let result = try await callable.call(payload)
        return try decodePayload(result.data, httpError: USDAProxyError.httpError, apiError: USDAProxyError.apiError, invalid: USDAProxyError.invalidResponse)
    }

    static func algoliaRecipeSearch(query: String, limit: Int) async throws -> Data {
        guard Auth.auth().currentUser != nil else {
            throw SearchError.notAuthenticated
        }
        let callable = functions.httpsCallable("algoliaRecipeSearchProxy")
        let result = try await callable.call(["query": query, "limit": limit])
        return try decodePayload(result.data, httpError: { _ in SearchError.requestFailed }, apiError: { _ in SearchError.requestFailed }, invalid: SearchError.invalidResponse)
    }

    private static func decodePayload<E>(
        _ raw: Any?,
        httpError: (Int) -> E,
        apiError: (String) -> E,
        invalid: E
    ) throws -> Data where E: Error {
        guard let dict = raw as? [String: Any],
              let status = dict["status"] as? Int,
              let bodyString = dict["body"] as? String,
              let bodyData = bodyString.data(using: .utf8) else {
            throw invalid
        }
        guard (200 ..< 300).contains(status) else {
            if let errJson = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let err = errJson["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw apiError(msg)
            }
            throw httpError(status)
        }
        return bodyData
    }
}

// MARK: - USDA proxy errors

enum USDAProxyError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case httpError(Int)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return LocalizedString("Please sign in to look up nutrition.", comment: "USDA proxy requires auth")
        case .invalidResponse:
            return "Invalid response from nutrition search."
        case .httpError(let code):
            return "Nutrition search HTTP error: \(code)"
        case .apiError(let message):
            return message
        }
    }
}
