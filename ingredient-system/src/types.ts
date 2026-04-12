// ─────────────────────────────────────────────────────────────
// Data Model — Ingredient Standardization System
// ─────────────────────────────────────────────────────────────

/**
 * Taxonomy of ingredient categories.
 * Each canonical ingredient belongs to exactly one category.
 */
export enum Category {
  PRODUCE   = "produce",
  MEAT      = "meat",
  POULTRY   = "poultry",
  SEAFOOD   = "seafood",
  DAIRY     = "dairy",
  GRAIN     = "grain",
  LEGUME    = "legume",
  SPICE     = "spice",
  HERB      = "herb",
  OIL       = "oil",
  VINEGAR   = "vinegar",
  SAUCE     = "sauce",
  CONDIMENT = "condiment",
  BAKING    = "baking",
  NUT       = "nut",
  BEVERAGE  = "beverage",
  MISC      = "misc",
}

/**
 * FDA "Big 9" allergen categories.
 * Used in commonAllergens field of CanonicalIngredient.
 */
export enum Allergen {
  DAIRY     = "dairy",
  EGGS      = "eggs",
  FISH      = "fish",
  SHELLFISH = "shellfish",
  TREE_NUTS = "tree_nuts",
  PEANUTS   = "peanuts",
  GLUTEN    = "gluten",
  SOY       = "soy",
  SESAME    = "sesame",
}

/**
 * Dietary compatibility flags.
 * Indicates which dietary restrictions an ingredient is compatible with.
 */
export enum DietaryFlag {
  VEGAN       = "vegan",
  VEGETARIAN  = "vegetarian",
  GLUTEN_FREE = "gluten_free",
  DAIRY_FREE  = "dairy_free",
  NUT_FREE    = "nut_free",
}

/**
 * A canonical (base) ingredient.
 * ID convention: UPPER_SNAKE_CASE, prefixed by category.
 * Example: PRODUCE_TOMATO, SPICE_CUMIN, MEAT_CHICKEN
 */
export interface CanonicalIngredient {
  id: string;
  name: string;
  category: Category;
  defaultUnitHint?: string;
  commonAllergens?: Allergen[];
  dietaryFlags?: DietaryFlag[];
}

/**
 * An alias that maps messy text to a canonical ingredient ID.
 * Locale-aware for future i18n. English-only in the initial seed.
 */
export interface IngredientAlias {
  alias: string;
  canonicalId: string;
  locale: string;
  notes?: string;
}

/**
 * Preparation attributes extracted from an ingredient line.
 * These describe HOW the ingredient is prepared, not WHAT it is.
 */
export interface IngredientAttributes {
  /** Processing form: fresh, dried, canned, frozen, preserved, pickled, fermented */
  form?: string;
  /** Cooking state: raw, cooked, roasted, fried, steamed, boiled, grilled, smoked */
  state?: string;
  /** Physical cut: chopped, diced, minced, sliced, grated, julienned, crushed, ground */
  cut?: string;
  /** Descriptive qualifier: extra-virgin, boneless, skinless, peeled, large, organic */
  qualifier?: string;
  /** Optional brand name (e.g. "Kikkoman") — rarely extracted from raw text */
  optionalBrand?: string;
  /** Optional origin (e.g. "Japanese", "Thai") — extracted when present */
  optionalOrigin?: string;
}

/**
 * A candidate match with a confidence score.
 */
export interface MatchCandidate {
  id: string;
  score: number;
  matchedTokens: string[];
}

/**
 * The result of parsing a single ingredient line.
 */
export interface ParsedIngredient {
  /** Numeric amount (e.g. 2, 0.5, 1.5). Undefined if "to taste" / none given. */
  amount?: number;
  /** Normalized unit token (e.g. "tbsp", "cup", "g"). Undefined if count-based. */
  unit?: string;
  /** Resolved canonical ingredient ID. Undefined if no match found. */
  canonicalIngredientId?: string;
  /** Extracted preparation attributes. */
  attributes: IngredientAttributes;
  /** Original unparsed text for traceability. */
  originalText: string;
  /** Top candidate matches with scores (always includes best match if any). */
  candidates: MatchCandidate[];
  /** True if confidence is below threshold — human review recommended. */
  needsReview: boolean;
}

/**
 * Entry for known ambiguous aliases that map to multiple canonicals.
 */
export interface AmbiguousAlias {
  alias: string;
  candidates: string[];
  notes: string;
}
