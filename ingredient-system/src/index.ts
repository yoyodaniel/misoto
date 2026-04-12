// ─────────────────────────────────────────────────────────────
// Public API — Ingredient Standardization System
// ─────────────────────────────────────────────────────────────

// Data model
export {
  Category,
  Allergen,
  DietaryFlag,
  CanonicalIngredient,
  IngredientAlias,
  IngredientAttributes,
  MatchCandidate,
  ParsedIngredient,
  AmbiguousAlias,
} from "./types";

// Canonical data
export { CANONICAL_INGREDIENTS, CANONICAL_COUNT } from "./data/canonical";
export { ALIAS_DATA, AMBIGUOUS_ALIASES, buildAliasArray } from "./data/aliases";

// Allergen & Dietary helpers
export {
  ALLERGEN_MAP,
  getAllergens,
  containsAllergen,
  findByAllergen,
  computeDietaryFlags,
} from "./data/allergens";

// Normalization utilities
export {
  normalizeText,
  extractAmount,
  extractUnit,
  classifyToken,
  UNIT_MAP,
  KNOWN_UNITS,
  FORM_WORDS,
  STATE_WORDS,
  CUT_WORDS,
  QUALIFIER_WORDS,
  MULTI_WORD_ATTRIBUTES,
} from "./normalizer";

// Matching engine
export { IngredientMatcher } from "./matcher";

// Parser
export { parseIngredientLine, createParser } from "./parser";
