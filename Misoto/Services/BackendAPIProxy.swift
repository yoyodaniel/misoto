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

    /// Serialize OpenAI callable invocations and reuse one `HTTPSCallable`.
    /// A new `httpsCallable` each request has been linked to
    /// `GTMSessionFetcher … was already running` when the SDK overlaps internal fetches.
    private actor OpenAIChatCompletionsGate {
        static let shared = OpenAIChatCompletionsGate()

        private var cachedCallable: HTTPSCallable?

        private func openAICallable() -> HTTPSCallable {
            if let cachedCallable {
                return cachedCallable
            }
            let callable = BackendAPIProxy.functions.httpsCallable("openaiChatCompletions")
            // Match `timeoutSeconds: 540` on `openaiChatCompletions` — default 70s is too low for vision + cold start.
            callable.timeoutInterval = 540
            cachedCallable = callable
            return callable
        }

        func perform(requestBody: [String: Any]) async throws -> Data {
            let token = String(UUID().uuidString.prefix(8))
            print("🔐 OpenAI callable gate BEGIN \(token)")
            defer { print("🔐 OpenAI callable gate END \(token)") }

            let result: HTTPSCallableResult
            do {
                result = try await openAICallable().call(["openaiRequest": requestBody])
            } catch {
                throw BackendAPIProxy.mapCallableTransportError(error)
            }
            do {
                return try BackendAPIProxy.decodePayload(
                    result.data,
                    httpError: OpenAIError.httpError,
                    apiError: OpenAIError.apiError,
                    invalid: OpenAIError.invalidResponse
                )
            } catch let decodeErr {
                if let raw = result.data as? [String: Any] {
                    print("❌ OpenAI callable: unexpected payload shape keys=\(raw.keys.sorted().joined(separator: ", "))")
                } else {
                    print("❌ OpenAI callable: result.data type=\(type(of: result.data))")
                }
                throw decodeErr
            }
        }
    }

    static func openAIChatCompletions(requestBody: [String: Any]) async throws -> Data {
        guard Auth.auth().currentUser != nil else {
            throw OpenAIError.notAuthenticated
        }
        return try await OpenAIChatCompletionsGate.shared.perform(requestBody: requestBody)
    }

    /// Maps Firebase Callable / URL errors into `OpenAIError` so the UI is not stuck on opaque messages like "NOT FOUND".
    private static func mapCallableTransportError(_ error: Error) -> Error {
        let ns = error as NSError
        if ns.domain == FunctionsErrorDomain, let code = FunctionsErrorCode(rawValue: ns.code) {
            let serverMessage = (ns.userInfo[NSLocalizedDescriptionKey] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let detailsDesc = ns.userInfo[FunctionsErrorDetailsKey].map { String(describing: $0) } ?? ""
            print("❌ BackendAPIProxy: Callable error code=\(code.rawValue) (\(code)) message=\(serverMessage ?? "") details=\(detailsDesc)")
            switch code {
            case .notFound, .unimplemented:
                let hint = LocalizedString(
                    "The recipe AI service was not found on the server. The project may need the openaiChatCompletions function deployed to us-central1, or the app may be pointed at the wrong Firebase project.",
                    comment: "Firebase callable NOT_FOUND / unimplemented"
                )
                return OpenAIError.backendConnectionFailed(hint)
            case .unavailable, .deadlineExceeded:
                let hint = LocalizedString(
                    "The recipe AI service timed out or is temporarily unavailable. Check your connection and try again.",
                    comment: "Firebase callable unavailable or deadline"
                )
                return OpenAIError.backendConnectionFailed(hint)
            case .unauthenticated:
                return OpenAIError.notAuthenticated
            case .invalidArgument, .failedPrecondition, .permissionDenied, .resourceExhausted:
                if let serverMessage, !serverMessage.isEmpty {
                    return OpenAIError.backendConnectionFailed(serverMessage)
                }
                return OpenAIError.backendConnectionFailed(
                    LocalizedString("The recipe AI service could not run this request.", comment: "Callable rejected without message")
                )
            case .cancelled:
                return OpenAIError.backendConnectionFailed(
                    LocalizedString("The request was cancelled.", comment: "Callable cancelled")
                )
            case .internal, .unknown, .aborted, .outOfRange, .dataLoss, .alreadyExists:
                let fallback = (serverMessage.flatMap { !$0.isEmpty ? $0 : nil })
                    ?? LocalizedString("Something went wrong while contacting the recipe AI service.", comment: "Callable internal/unknown")
                return OpenAIError.backendConnectionFailed(fallback)
            case .OK:
                return error
            }
        }
        if ns.domain == NSURLErrorDomain {
            print("❌ BackendAPIProxy: URLError code=\(ns.code) \(ns.localizedDescription)")
            let hint: String
            switch ns.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
                hint = LocalizedString(
                    "No network connection or the server could not be reached. Check Wi‑Fi or cellular data and try again.",
                    comment: "URLError network"
                )
            default:
                hint = ns.localizedDescription
            }
            return OpenAIError.backendConnectionFailed(hint)
        }
        print("❌ BackendAPIProxy: Unmapped error domain=\(ns.domain) code=\(ns.code) \(error.localizedDescription)")
        return OpenAIError.backendConnectionFailed(error.localizedDescription)
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
