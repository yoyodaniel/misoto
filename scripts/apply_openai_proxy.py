#!/usr/bin/env python3
"""Apply BackendAPIProxy migration to OpenAIService.swift using slices from the live file."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "Misoto" / "Services" / "OpenAIService.swift"
lines = path.read_text(encoding="utf-8").splitlines(keepends=True)


def join_slice(start: int, end: int) -> str:
    return "".join(lines[start:end])


# Slices captured from 1-based line numbers (see script comments)
preamble_url = join_slice(58, 68)  # 59–68
preamble_api = join_slice(539, 549)  # 540–549
block_a = join_slice(234, 254)  # 235–254
block_b = join_slice(470, 490)  # 471–490
block_c = join_slice(1379, 1398)  # 1380–1398 (no “// Make the request”)
block_d = join_slice(2337, 2343)  # 2338–2343

repl_a = "        let data = try await BackendAPIProxy.openAIChatCompletions(requestBody: requestBody)\n        \n"
repl_b = "        let responseData = try await BackendAPIProxy.openAIChatCompletions(requestBody: requestBody)\n        \n"

text = "".join(lines)

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

text = text.replace(preamble_url, "")
text = text.replace(preamble_api, "")

for old, new in (
    (block_a, repl_a),
    (block_b, repl_b),
    (block_c, repl_a),
    (block_d, repl_a),
):
    if old not in text:
        raise SystemExit(f"Missing expected block (first 100 chars): {old[:100]!r}")
    text = text.replace(old, new)

if "URLSession.shared.data(for: request)" in text:
    raise SystemExit("still contains URLSession.shared.data(for: request)")

if "baseURL" in text or "apiKey" in text:
    raise SystemExit("still contains baseURL or apiKey")

path.write_text(text, encoding="utf-8")
print("OK", path)
