#!/usr/bin/env python3
"""Rewrite OpenAIService.swift to use BackendAPIProxy instead of direct OpenAI HTTPS."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "Misoto" / "Services" / "OpenAIService.swift"
text = path.read_text(encoding="utf-8")

if "import FirebaseAuth" not in text:
    text = text.replace(
        "import Foundation\nimport UIKit\nimport NaturalLanguage\n",
        "import Foundation\nimport UIKit\nimport NaturalLanguage\nimport FirebaseAuth\n",
    )

text = text.replace(
    """    private static var apiKey: String {
        APIKeyProvider.openAIKey
    }
    private static let baseURL = "https://api.openai.com/v1"
    
""",
    "",
)

text = text.replace(
    """        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
""",
    "",
)
text = text.replace(
    "        guard !apiKey.isEmpty else { throw OpenAIError.apiKeyNotConfigured }\n",
    "",
)

preamble_url = r"""        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
"""
text = text.replace(preamble_url, "")

preamble_api = r"""        // Create the request
        guard let apiURL = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
"""
text = text.replace(preamble_api, "")

block_a = r"""        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
"""
text = text.replace(block_a, """        let data = try await BackendAPIProxy.openAIChatCompletions(requestBody: requestBody)
        
""")

block_b = r"""        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (responseData, apiResponse) = try await URLSession.shared.data(for: request)
        
        guard let apiHTTPResponse = apiResponse as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard apiHTTPResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(apiHTTPResponse.statusCode)
        }
        
"""
text = text.replace(block_b, """        let responseData = try await BackendAPIProxy.openAIChatCompletions(requestBody: requestBody)
        
""")

block_c = r"""        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
"""
text = text.replace(block_c, """        let data = try await BackendAPIProxy.openAIChatCompletions(requestBody: requestBody)
        
""")

block_d = r"""        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
"""
text = text.replace(block_d, """        let data = try await BackendAPIProxy.openAIChatCompletions(requestBody: requestBody)
        
""")

if "URLSession.shared.data(for: request)" in text:
    raise SystemExit("still contains URLSession.shared.data(for: request)")

if "baseURL" in text or "apiKey" in text:
    raise SystemExit("still contains baseURL or apiKey")

path.write_text(text, encoding="utf-8")
print("OK:", path)
