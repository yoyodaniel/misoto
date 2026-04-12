// ─────────────────────────────────────────────────────────────
// Ingredient Line Parser
// ─────────────────────────────────────────────────────────────

import { ParsedIngredient, IngredientAttributes } from "./types";
import {
  normalizeText,
  extractAmount,
  extractUnit,
  classifyToken,
  MULTI_WORD_ATTRIBUTES,
} from "./normalizer";
import { IngredientMatcher } from "./matcher";
import { CANONICAL_INGREDIENTS } from "./data/canonical";
import { ALIAS_DATA } from "./data/aliases";

// ── Constants ──────────────────────────────────────────────────

const CONFIDENCE_THRESHOLD = 0.6;

/** Trailing phrases to strip from ingredient text. */
const TRAILING_PHRASES = [
  "to taste", "or to taste", "as needed", "as desired",
  "for garnish", "for serving", "for decoration", "for frying",
  "for greasing", "for dusting", "optional", "divided",
  "or more", "or less", "plus more", "plus extra",
];

/** Connector words to skip between unit and ingredient. */
const CONNECTOR_WORDS = new Set(["of", "the", "a", "an", "some"]);

// ── Factory ────────────────────────────────────────────────────

/**
 * Create a ready-to-use parser with the built-in canonical list and aliases.
 * The IngredientMatcher is constructed once and reused for all calls.
 *
 * Usage:
 * ```ts
 * const parse = createParser();
 * const result = parse("2 tbsp extra-virgin olive oil");
 * ```
 */
export function createParser(): (line: string) => ParsedIngredient {
  const matcher = new IngredientMatcher(CANONICAL_INGREDIENTS, ALIAS_DATA);
  return (line: string) => parseIngredientLine(line, matcher);
}

// ── Core Parser ────────────────────────────────────────────────

/**
 * Parse a single ingredient line into structured data.
 *
 * Strategy:
 * 1. Normalize text (lowercase, fractions, whitespace)
 * 2. Extract amount (leading number)
 * 3. Extract unit (known unit token)
 * 4. Strip connectors ("of") and trailing phrases ("to taste")
 * 5. Try exact alias match on full remaining text
 * 6. Try longest-match via trie (handles attribute words mixed in)
 * 7. Strip recognized attribute words and retry
 * 8. Fuzzy match as last resort
 * 9. Return ParsedIngredient with needsReview flag
 */
export function parseIngredientLine(
  line: string,
  matcher: IngredientMatcher,
): ParsedIngredient {
  const originalText = line;

  // Step 1: Normalize
  let text = normalizeText(line);

  // Step 2: Extract amount
  const { amount, remaining: afterAmount } = extractAmount(text);

  // Step 3: Extract unit
  const { unit, remaining: afterUnit } = extractUnit(afterAmount);

  // Step 4: Strip connectors
  let ingredientText = afterUnit;
  const firstWord = ingredientText.split(/\s+/)[0];
  if (CONNECTOR_WORDS.has(firstWord)) {
    ingredientText = ingredientText.replace(/^\S+\s*/, "");
  }

  // Step 5: Extract multi-word attributes
  const attributes: IngredientAttributes = {};
  for (const [phrase, attr] of Object.entries(MULTI_WORD_ATTRIBUTES)) {
    if (ingredientText.includes(phrase)) {
      if (!attributes[attr.category]) {
        attributes[attr.category] = attr.value;
      }
      ingredientText = ingredientText.replace(phrase, " ").replace(/\s+/g, " ").trim();
    }
  }

  // Step 6: Tokenize
  let tokens = ingredientText.split(/\s+/).filter((t) => t.length > 0);

  // Step 7: Strip trailing phrases
  for (const phrase of TRAILING_PHRASES) {
    const phraseTokens = phrase.split(" ");
    if (tokens.length > phraseTokens.length) {
      const tail = tokens.slice(-phraseTokens.length).join(" ");
      if (tail === phrase) {
        tokens = tokens.slice(0, -phraseTokens.length);
      }
    }
  }

  // Remove trailing "and" if orphaned
  if (tokens.length > 1 && tokens[tokens.length - 1] === "and") {
    tokens = tokens.slice(0, -1);
  }

  // ── Match Strategies ───────────────────────────────────────

  const fullText = tokens.join(" ");

  // Strategy A: Exact match on full remaining text
  const exactId = matcher.exactMatch(fullText);
  if (exactId) {
    return result(amount, unit, exactId, attributes, originalText, [
      { id: exactId, score: 1.0, matchedTokens: tokens },
    ]);
  }

  // Strategy B: Longest trie match
  const longest = matcher.longestMatch(tokens);
  if (longest) {
    captureUnmatchedAttributes(tokens, longest.startIndex, longest.endIndex, attributes);
    const score = Math.max(longest.matchedTokens.length / Math.max(tokens.length, 1), 0.75);
    return result(amount, unit, longest.canonicalId, attributes, originalText, [
      { id: longest.canonicalId, score, matchedTokens: longest.matchedTokens },
    ]);
  }

  // Strategy C: Strip single-token attributes and retry
  const { cleaned, extracted } = stripAttributeTokens(tokens);
  mergeAttributes(attributes, extracted);

  if (cleaned.length > 0) {
    const cleanedText = cleaned.join(" ");
    const cleanedExact = matcher.exactMatch(cleanedText);
    if (cleanedExact) {
      return result(amount, unit, cleanedExact, attributes, originalText, [
        { id: cleanedExact, score: 0.9, matchedTokens: cleaned },
      ]);
    }

    const cleanedLongest = matcher.longestMatch(cleaned);
    if (cleanedLongest) {
      return result(amount, unit, cleanedLongest.canonicalId, attributes, originalText, [
        { id: cleanedLongest.canonicalId, score: 0.8, matchedTokens: cleanedLongest.matchedTokens },
      ]);
    }
  }

  // Strategy D: Fuzzy match
  const fuzzyTokens = cleaned.length > 0 ? cleaned : tokens;
  const fuzzyCandidates = matcher.fuzzyMatch(fuzzyTokens);

  if (fuzzyCandidates.length > 0 && fuzzyCandidates[0].score >= CONFIDENCE_THRESHOLD) {
    return {
      amount,
      unit,
      canonicalIngredientId: fuzzyCandidates[0].id,
      attributes,
      originalText,
      candidates: fuzzyCandidates,
      needsReview: true,
    };
  }

  // No match — return with needsReview
  return {
    amount,
    unit,
    canonicalIngredientId: undefined,
    attributes,
    originalText,
    candidates: fuzzyCandidates,
    needsReview: true,
  };
}

// ── Helpers ────────────────────────────────────────────────────

function result(
  amount: number | undefined,
  unit: string | undefined,
  canonicalId: string,
  attributes: IngredientAttributes,
  originalText: string,
  candidates: Array<{ id: string; score: number; matchedTokens: string[] }>,
): ParsedIngredient {
  return {
    amount,
    unit,
    canonicalIngredientId: canonicalId,
    attributes,
    originalText,
    candidates,
    needsReview: false,
  };
}

function captureUnmatchedAttributes(
  tokens: string[],
  matchStart: number,
  matchEnd: number,
  attrs: IngredientAttributes,
): void {
  const unmatched = [...tokens.slice(0, matchStart), ...tokens.slice(matchEnd + 1)];
  for (const token of unmatched) {
    const cls = classifyToken(token);
    if (cls && !attrs[cls.category]) {
      attrs[cls.category] = cls.value;
    }
  }
}

function stripAttributeTokens(
  tokens: string[],
): { cleaned: string[]; extracted: IngredientAttributes } {
  const cleaned: string[] = [];
  const extracted: IngredientAttributes = {};
  for (const token of tokens) {
    const cls = classifyToken(token);
    if (cls) {
      if (!extracted[cls.category]) {
        extracted[cls.category] = cls.value;
      }
    } else {
      cleaned.push(token);
    }
  }
  return { cleaned, extracted };
}

function mergeAttributes(target: IngredientAttributes, source: IngredientAttributes): void {
  for (const key of ["form", "state", "cut", "qualifier"] as const) {
    if (source[key] && !target[key]) {
      target[key] = source[key];
    }
  }
}
