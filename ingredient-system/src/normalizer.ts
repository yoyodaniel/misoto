// ─────────────────────────────────────────────────────────────
// Text Normalization & Attribute Classification
// ─────────────────────────────────────────────────────────────

import { IngredientAttributes } from "./types";

// ── Unicode Fraction Map ──────────────────────────────────────

const UNICODE_FRACTIONS: Record<string, number> = {
  "\u00BD": 0.5,   // ½
  "\u2153": 1 / 3, // ⅓
  "\u2154": 2 / 3, // ⅔
  "\u00BC": 0.25,  // ¼
  "\u00BE": 0.75,  // ¾
  "\u2155": 0.2,   // ⅕
  "\u2156": 0.4,   // ⅖
  "\u2157": 0.6,   // ⅗
  "\u2158": 0.8,   // ⅘
  "\u2159": 1 / 6, // ⅙
  "\u215A": 5 / 6, // ⅚
  "\u215B": 0.125, // ⅛
  "\u215C": 0.375, // ⅜
  "\u215D": 0.625, // ⅝
  "\u215E": 0.875, // ⅞
};

// ── Unit Synonym Map → normalized unit key ────────────────────

export const UNIT_MAP: Record<string, string> = {
  // Volume — spoons
  tablespoon: "tbsp", tablespoons: "tbsp", tbs: "tbsp", tbsps: "tbsp", tbsp: "tbsp",
  teaspoon: "tsp", teaspoons: "tsp", tsps: "tsp", tsp: "tsp",
  // Volume — cups / pints / quarts / gallons
  cup: "cup", cups: "cup",
  pint: "pint", pints: "pint", pt: "pint",
  quart: "quart", quarts: "quart", qt: "quart",
  gallon: "gallon", gallons: "gallon", gal: "gallon",
  // Volume — metric
  milliliter: "ml", milliliters: "ml", millilitre: "ml", millilitres: "ml", ml: "ml",
  liter: "l", liters: "l", litre: "l", litres: "l", l: "l",
  "fluid ounce": "fl oz", "fluid ounces": "fl oz", "fl oz": "fl oz",
  // Weight — imperial
  ounce: "oz", ounces: "oz", oz: "oz",
  pound: "lb", pounds: "lb", lb: "lb", lbs: "lb",
  // Weight — metric
  gram: "g", grams: "g", gramme: "g", grammes: "g", g: "g",
  kilogram: "kg", kilograms: "kg", kilo: "kg", kg: "kg",
  milligram: "mg", milligrams: "mg", mg: "mg",
  // Count-like units
  piece: "piece", pieces: "piece", pc: "piece", pcs: "piece",
  slice: "slice", slices: "slice",
  clove: "clove", cloves: "clove",
  sprig: "sprig", sprigs: "sprig",
  stalk: "stalk", stalks: "stalk",
  stem: "stem", stems: "stem",
  head: "head", heads: "head",
  bulb: "bulb", bulbs: "bulb",
  ear: "ear", ears: "ear",
  leaf: "leaf", leaves: "leaf",
  bunch: "bunch", bunches: "bunch",
  handful: "handful", handfuls: "handful",
  stick: "stick", sticks: "stick",
  sheet: "sheet", sheets: "sheet",
  strip: "strip", strips: "strip",
  // Containers
  can: "can", cans: "can", tin: "can", tins: "can",
  jar: "jar", jars: "jar",
  bottle: "bottle", bottles: "bottle",
  package: "package", packages: "package", pkg: "package", pkgs: "package",
  packet: "package", packets: "package",
  bag: "bag", bags: "bag",
  box: "box", boxes: "box",
  // Approximate
  pinch: "pinch", pinches: "pinch",
  dash: "dash", dashes: "dash",
  drop: "drop", drops: "drop",
  knob: "knob",
  splash: "splash",
  drizzle: "drizzle",
  // Length
  inch: "inch", inches: "inch",
  cm: "cm", centimeter: "cm", centimeters: "cm",
  // Size as unit (e.g. "4 large eggs")
  large: "large", medium: "medium", med: "medium", small: "small",
};

export const KNOWN_UNITS = new Set(Object.values(UNIT_MAP));

// ── Attribute Word Sets ────────────────────────────────────────

export const FORM_WORDS = new Set([
  "fresh", "dried", "canned", "frozen", "preserved", "pickled", "fermented",
  "dehydrated", "cured", "marinated", "brined", "candied", "crystallized",
  "rehydrated", "sun-dried", "air-dried", "freeze-dried",
]);

export const STATE_WORDS = new Set([
  "raw", "cooked", "roasted", "fried", "steamed", "boiled", "grilled",
  "toasted", "blanched", "sauteed", "sautéed", "baked", "braised",
  "charred", "seared", "poached", "caramelized", "smoked", "stir-fried",
  "deep-fried", "pan-fried", "broiled", "blackened", "wilted", "softened",
]);

export const CUT_WORDS = new Set([
  "chopped", "diced", "minced", "sliced", "grated", "julienned",
  "crushed", "ground", "mashed", "pureed", "puréed", "shredded",
  "torn", "halved", "quartered", "cubed", "crumbled", "flaked",
  "zested", "segmented", "pitted", "chiffonade", "brunoised",
]);

export const QUALIFIER_WORDS = new Set([
  "extra-virgin", "virgin", "light", "dark", "unsalted", "salted",
  "organic", "boneless", "skinless", "bone-in", "skin-on", "seedless",
  "peeled", "unpeeled", "deveined", "trimmed", "packed", "drained",
  "rinsed", "chilled", "thawed", "ripe", "overripe", "unripe",
  "baby", "young", "mature", "thick-cut", "thin", "lean",
  "low-sodium", "reduced-fat", "full-fat", "nonfat", "whole",
  "raw", "uncooked", "dry", "wet",
]);

/** Multi-word attribute phrases to detect before single-token classification. */
export const MULTI_WORD_ATTRIBUTES: Record<string, { category: keyof IngredientAttributes; value: string }> = {
  "extra virgin":     { category: "qualifier", value: "extra-virgin" },
  "bone in":          { category: "qualifier", value: "bone-in" },
  "skin on":          { category: "qualifier", value: "skin-on" },
  "room temperature": { category: "qualifier", value: "room-temperature" },
  "low sodium":       { category: "qualifier", value: "low-sodium" },
  "reduced fat":      { category: "qualifier", value: "reduced-fat" },
  "full fat":         { category: "qualifier", value: "full-fat" },
  "thick cut":        { category: "qualifier", value: "thick-cut" },
  "roughly chopped":  { category: "cut", value: "roughly chopped" },
  "finely chopped":   { category: "cut", value: "finely chopped" },
  "thinly sliced":    { category: "cut", value: "thinly sliced" },
  "coarsely chopped": { category: "cut", value: "coarsely chopped" },
  "finely diced":     { category: "cut", value: "finely diced" },
  "finely minced":    { category: "cut", value: "finely minced" },
  "stir fried":       { category: "state", value: "stir-fried" },
  "deep fried":       { category: "state", value: "deep-fried" },
  "pan fried":        { category: "state", value: "pan-fried" },
  "sun dried":        { category: "form", value: "sun-dried" },
  "air dried":        { category: "form", value: "air-dried" },
  "freeze dried":     { category: "form", value: "freeze-dried" },
};

// ── Normalization ──────────────────────────────────────────────

/**
 * Normalize an ingredient text string:
 * - lowercase
 * - replace unicode fractions with decimals
 * - split number-unit combos ("200g" → "200 g")
 * - resolve text fractions ("1/2" → "0.5")
 * - strip parentheticals (capture content)
 * - normalize whitespace
 */
export function normalizeText(s: string): string {
  let r = s.toLowerCase().trim();

  // Replace unicode fractions with space-padded decimals
  for (const [frac, val] of Object.entries(UNICODE_FRACTIONS)) {
    r = r.split(frac).join(` ${val} `);
  }

  // Split number+unit combos: "200g" → "200 g"
  r = r.replace(/(\d+(?:\.\d+)?)(g|kg|ml|l|oz|lb|cm|mm)\b/gi, "$1 $2");

  // Replace text fractions: "1/2" → decimal
  r = r.replace(/(\d+)\s*\/\s*(\d+)/g, (_, num, den) =>
    String(Math.round((parseFloat(num) / parseFloat(den)) * 10000) / 10000),
  );

  // Flatten parenthetical content into the line
  r = r.replace(/\(([^)]*)\)/g, " $1 ");

  // Replace commas with spaces
  r = r.replace(/,/g, " ");

  // Remove periods not in decimals
  r = r.replace(/\.(?!\d)/g, " ");

  // Collapse whitespace
  r = r.replace(/\s+/g, " ").trim();

  return r;
}

// ── Amount Extraction ──────────────────────────────────────────

/**
 * Extract a numeric amount from the start of a normalized string.
 * Handles: "2", "2.5", "0.5", combined "1 0.5" (= 1½), ranges "2-3" (takes first).
 */
export function extractAmount(text: string): { amount: number | undefined; remaining: string } {
  // Match leading number(s)
  const match = text.match(/^(\d+(?:\.\d+)?)\s*(?:-\s*\d+(?:\.\d+)?)?\s*(.*)/);
  if (!match) return { amount: undefined, remaining: text };

  let amount = parseFloat(match[1]);
  let remaining = match[2].trim();

  // Check for a second fractional number right after (e.g. "1 0.5" from "1 ½")
  const fracMatch = remaining.match(/^(\d*\.\d+)\s+(.*)/);
  if (fracMatch) {
    amount += parseFloat(fracMatch[1]);
    remaining = fracMatch[2].trim();
  }

  return { amount, remaining };
}

// ── Unit Extraction ────────────────────────────────────────────

/**
 * Extract a unit token from the start of a remaining string.
 * Tries two-word units first, then single-word.
 */
export function extractUnit(text: string): { unit: string | undefined; remaining: string } {
  const tokens = text.split(/\s+/);
  if (tokens.length === 0) return { unit: undefined, remaining: text };

  // Two-word units ("fl oz", "fluid ounce")
  if (tokens.length >= 2) {
    const twoWord = `${tokens[0]} ${tokens[1]}`;
    if (UNIT_MAP[twoWord]) {
      return { unit: UNIT_MAP[twoWord], remaining: tokens.slice(2).join(" ") };
    }
  }

  // Single-word unit
  if (UNIT_MAP[tokens[0]]) {
    return { unit: UNIT_MAP[tokens[0]], remaining: tokens.slice(1).join(" ") };
  }

  return { unit: undefined, remaining: text };
}

// ── Attribute Classification ───────────────────────────────────

/**
 * Classify a single token as an ingredient attribute, or return null.
 */
export function classifyToken(token: string): { category: keyof IngredientAttributes; value: string } | null {
  if (FORM_WORDS.has(token))      return { category: "form", value: token };
  if (STATE_WORDS.has(token))     return { category: "state", value: token };
  if (CUT_WORDS.has(token))       return { category: "cut", value: token };
  if (QUALIFIER_WORDS.has(token)) return { category: "qualifier", value: token };
  return null;
}
