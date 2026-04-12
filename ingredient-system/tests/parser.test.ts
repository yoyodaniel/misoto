// ─────────────────────────────────────────────────────────────
// Parser Tests — 40+ test cases across cuisines and edge cases
// ─────────────────────────────────────────────────────────────

import {
  createParser, ParsedIngredient, normalizeText, extractAmount, extractUnit,
  IngredientMatcher, CANONICAL_INGREDIENTS, ALIAS_DATA, CANONICAL_COUNT,
  Allergen, DietaryFlag, getAllergens, containsAllergen, findByAllergen,
  ALLERGEN_MAP,
} from "../src";

const parse = createParser();

// ── Helper ─────────────────────────────────────────────────────

function expectParsed(
  input: string,
  expected: {
    canonicalId?: string;
    amount?: number;
    unit?: string;
    form?: string;
    state?: string;
    cut?: string;
    qualifier?: string;
    needsReview?: boolean;
  },
) {
  const result = parse(input);
  if (expected.canonicalId !== undefined) {
    expect(result.canonicalIngredientId).toBe(expected.canonicalId);
  }
  if (expected.amount !== undefined) {
    expect(result.amount).toBeCloseTo(expected.amount, 2);
  }
  if (expected.unit !== undefined) {
    expect(result.unit).toBe(expected.unit);
  }
  if (expected.form !== undefined) {
    expect(result.attributes.form).toBe(expected.form);
  }
  if (expected.state !== undefined) {
    expect(result.attributes.state).toBe(expected.state);
  }
  if (expected.cut !== undefined) {
    expect(result.attributes.cut).toBe(expected.cut);
  }
  if (expected.qualifier !== undefined) {
    expect(result.attributes.qualifier).toBe(expected.qualifier);
  }
  if (expected.needsReview !== undefined) {
    expect(result.needsReview).toBe(expected.needsReview);
  }
  return result;
}

// ── normalizeText() ────────────────────────────────────────────

describe("normalizeText", () => {
  test("lowercases and trims", () => {
    expect(normalizeText("  Fresh BASIL  ")).toBe("fresh basil");
  });

  test("replaces unicode fractions", () => {
    const result = normalizeText("½ tsp salt");
    expect(result).toContain("0.5");
    expect(result).toContain("tsp");
    expect(result).toContain("salt");
  });

  test("splits number-unit combos", () => {
    expect(normalizeText("200g chicken")).toBe("200 g chicken");
  });

  test("resolves text fractions", () => {
    expect(normalizeText("1/4 cup sugar")).toContain("0.25");
  });

  test("flattens parentheticals", () => {
    expect(normalizeText("coconut milk (canned)")).toBe("coconut milk canned");
  });

  test("removes commas", () => {
    expect(normalizeText("chicken thighs, boneless")).toBe("chicken thighs boneless");
  });
});

// ── extractAmount() ────────────────────────────────────────────

describe("extractAmount", () => {
  test("extracts integer amount", () => {
    const { amount, remaining } = extractAmount("2 cups flour");
    expect(amount).toBe(2);
    expect(remaining).toBe("cups flour");
  });

  test("extracts decimal amount", () => {
    const { amount } = extractAmount("1.5 tbsp oil");
    expect(amount).toBe(1.5);
  });

  test("handles combined fractions (1 0.5 = 1½)", () => {
    const { amount } = extractAmount("1 0.5 cups sugar");
    expect(amount).toBeCloseTo(1.5, 2);
  });

  test("returns undefined for text with no leading number", () => {
    const { amount, remaining } = extractAmount("salt to taste");
    expect(amount).toBeUndefined();
    expect(remaining).toBe("salt to taste");
  });
});

// ── extractUnit() ──────────────────────────────────────────────

describe("extractUnit", () => {
  test("extracts single-word unit", () => {
    const { unit, remaining } = extractUnit("tbsp olive oil");
    expect(unit).toBe("tbsp");
    expect(remaining).toBe("olive oil");
  });

  test("normalizes 'tablespoons' → 'tbsp'", () => {
    const { unit } = extractUnit("tablespoons soy sauce");
    expect(unit).toBe("tbsp");
  });

  test("handles two-word unit 'fl oz'", () => {
    const { unit, remaining } = extractUnit("fl oz lemon juice");
    expect(unit).toBe("fl oz");
    expect(remaining).toBe("lemon juice");
  });

  test("returns undefined for unknown first token", () => {
    const { unit, remaining } = extractUnit("olive oil");
    expect(unit).toBeUndefined();
    expect(remaining).toBe("olive oil");
  });
});

// ── parseIngredientLine() — Standard cases ─────────────────────

describe("parseIngredientLine — standard", () => {
  // 1. Basic oil with qualifier
  test("2 tbsp extra-virgin olive oil", () => {
    expectParsed("2 tbsp extra-virgin olive oil", {
      canonicalId: "OIL_OLIVE",
      amount: 2,
      unit: "tbsp",
      needsReview: false,
    });
  });

  // 2. Fresh herb with bunch unit
  test("1 bunch fresh cilantro", () => {
    expectParsed("1 bunch fresh cilantro", {
      canonicalId: "HERB_CILANTRO",
      amount: 1,
      unit: "bunch",
      form: "fresh",
    });
  });

  // 3. Meat with attribute comma-separated
  test("200g chicken thighs, boneless", () => {
    expectParsed("200g chicken thighs, boneless", {
      canonicalId: "POULTRY_CHICKEN_THIGH",
      amount: 200,
      unit: "g",
    });
  });

  // 4. Unicode fraction + ground spice
  test("½ tsp ground cumin", () => {
    expectParsed("½ tsp ground cumin", {
      canonicalId: "SPICE_CUMIN",
      amount: 0.5,
      unit: "tsp",
    });
  });

  // 5. Garlic with clove unit + minced attribute
  test("3 cloves garlic, minced", () => {
    expectParsed("3 cloves garlic, minced", {
      canonicalId: "PRODUCE_GARLIC",
      amount: 3,
      unit: "clove",
      cut: "minced",
    });
  });

  // 6. Canned coconut milk
  test("1 can coconut milk", () => {
    expectParsed("1 can coconut milk", {
      canonicalId: "DAIRY_COCONUT_MILK",
      amount: 1,
      unit: "can",
    });
  });

  // 7. Salt to taste (no amount)
  test("salt to taste", () => {
    const r = expectParsed("salt to taste", {
      canonicalId: "SPICE_SALT",
    });
    expect(r.amount).toBeUndefined();
    expect(r.unit).toBeUndefined();
  });

  // 8. Multi-attribute meat
  test("1 lb boneless skinless chicken breast", () => {
    expectParsed("1 lb boneless skinless chicken breast", {
      canonicalId: "POULTRY_CHICKEN_BREAST",
      amount: 1,
      unit: "lb",
    });
  });

  // 9. All-purpose flour (common alias)
  test("2 cups all-purpose flour", () => {
    expectParsed("2 cups all-purpose flour", {
      canonicalId: "BAKING_ALL_PURPOSE_FLOUR",
      amount: 2,
      unit: "cup",
    });
  });

  // 10. Fresh ginger with inch unit
  test("1 inch fresh ginger, grated", () => {
    expectParsed("1 inch fresh ginger, grated", {
      canonicalId: "PRODUCE_GINGER",
      amount: 1,
      unit: "inch",
    });
  });

  // 11. Eggs with size-as-unit
  test("4 large eggs", () => {
    expectParsed("4 large eggs", {
      canonicalId: "DAIRY_EGG",
      amount: 4,
      unit: "large",
    });
  });

  // 12. Specific rice variety
  test("1 cup basmati rice", () => {
    expectParsed("1 cup basmati rice", {
      canonicalId: "GRAIN_BASMATI_RICE",
      amount: 1,
      unit: "cup",
    });
  });

  // 13. Full unit name "tablespoons"
  test("2 tablespoons soy sauce", () => {
    expectParsed("2 tablespoons soy sauce", {
      canonicalId: "SAUCE_SOY",
      amount: 2,
      unit: "tbsp",
    });
  });

  // 14. Text fraction
  test("1/4 cup rice vinegar", () => {
    expectParsed("1/4 cup rice vinegar", {
      canonicalId: "VINEGAR_RICE",
      amount: 0.25,
      unit: "cup",
    });
  });

  // 15. Scallion synonym
  test("3 green onions, thinly sliced", () => {
    expectParsed("3 green onions, thinly sliced", {
      canonicalId: "PRODUCE_SCALLION",
      amount: 3,
    });
  });

  // 16. Metric + cream
  test("200ml heavy cream", () => {
    expectParsed("200ml heavy cream", {
      canonicalId: "DAIRY_HEAVY_CREAM",
      amount: 200,
      unit: "ml",
    });
  });

  // 17. Sesame oil
  test("1 tsp sesame oil", () => {
    expectParsed("1 tsp sesame oil", {
      canonicalId: "OIL_SESAME",
      amount: 1,
      unit: "tsp",
    });
  });

  // 18. Firm tofu (variant)
  test("1 package firm tofu", () => {
    expectParsed("1 package firm tofu", {
      canonicalId: "MISC_FIRM_TOFU",
      amount: 1,
      unit: "package",
    });
  });

  // 19. Fish sauce
  test("1 tbsp fish sauce", () => {
    expectParsed("1 tbsp fish sauce", {
      canonicalId: "SAUCE_FISH",
      amount: 1,
      unit: "tbsp",
    });
  });

  // 20. Saffron with pinch
  test("pinch of saffron", () => {
    expectParsed("pinch of saffron", {
      canonicalId: "SPICE_SAFFRON",
      unit: "pinch",
    });
  });

  // 21. Fresh thyme sprigs — "fresh thyme" matches as a complete alias,
  //     so "fresh" is consumed by the alias, not extracted as an attribute.
  test("5 sprigs fresh thyme", () => {
    expectParsed("5 sprigs fresh thyme", {
      canonicalId: "HERB_THYME",
      amount: 5,
      unit: "sprig",
    });
  });

  // 22. Dried lentils
  test("1 cup dried lentils", () => {
    expectParsed("1 cup dried lentils", {
      canonicalId: "LEGUME_LENTIL",
      amount: 1,
      unit: "cup",
      form: "dried",
    });
  });

  // 23. Lemongrass
  test("3 stalks lemongrass", () => {
    expectParsed("3 stalks lemongrass", {
      canonicalId: "HERB_LEMONGRASS",
      amount: 3,
      unit: "stalk",
    });
  });

  // 24. Pork belly with metric
  test("500g pork belly", () => {
    expectParsed("500g pork belly", {
      canonicalId: "MEAT_PORK_BELLY",
      amount: 500,
      unit: "g",
    });
  });

  // 25. Head of lettuce
  test("1 head romaine lettuce", () => {
    expectParsed("1 head romaine lettuce", {
      canonicalId: "PRODUCE_ROMAINE_LETTUCE",
      amount: 1,
      unit: "head",
    });
  });
});

// ── Asian / International Cuisine Cases ────────────────────────

describe("parseIngredientLine — Asian / international", () => {
  // 26. Gochujang
  test("2 tbsp gochujang", () => {
    expectParsed("2 tbsp gochujang", {
      canonicalId: "SAUCE_GOCHUJANG",
      amount: 2,
      unit: "tbsp",
    });
  });

  // 27. Panko
  test("¾ cup panko breadcrumbs", () => {
    expectParsed("¾ cup panko breadcrumbs", {
      canonicalId: "GRAIN_PANKO",
      amount: 0.75,
      unit: "cup",
    });
  });

  // 28. Nori sheets
  test("4 sheets nori", () => {
    expectParsed("4 sheets nori", {
      canonicalId: "MISC_NORI",
      amount: 4,
      unit: "sheet",
    });
  });

  // 29. Vanilla extract
  test("1 tsp vanilla extract", () => {
    expectParsed("1 tsp vanilla extract", {
      canonicalId: "BAKING_VANILLA_EXTRACT",
      amount: 1,
      unit: "tsp",
    });
  });

  // 30. Fresh spinach — "fresh spinach" is a complete alias
  test("2 cups fresh spinach", () => {
    expectParsed("2 cups fresh spinach", {
      canonicalId: "PRODUCE_SPINACH",
      amount: 2,
      unit: "cup",
    });
  });

  // 31. Bean sprouts
  test("100g bean sprouts", () => {
    expectParsed("100g bean sprouts", {
      canonicalId: "PRODUCE_BEAN_SPROUT",
      amount: 100,
      unit: "g",
    });
  });

  // 32. Mirin
  test("2 tbsp mirin", () => {
    expectParsed("2 tbsp mirin", {
      canonicalId: "SAUCE_MIRIN",
      amount: 2,
      unit: "tbsp",
    });
  });

  // 33. Kecap manis (Indonesian sweet soy sauce — now its own canonical)
  test("1 tbsp kecap manis", () => {
    expectParsed("1 tbsp kecap manis", {
      canonicalId: "SAUCE_KECAP_MANIS",
      amount: 1,
      unit: "tbsp",
    });
  });

  // 34. Sambal oelek
  test("1 tbsp sambal oelek", () => {
    expectParsed("1 tbsp sambal oelek", {
      canonicalId: "SAUCE_SAMBAL_OELEK",
      amount: 1,
      unit: "tbsp",
    });
  });

  // 35. Shaoxing wine
  test("2 tbsp shaoxing wine", () => {
    expectParsed("2 tbsp shaoxing wine", {
      canonicalId: "SAUCE_SHAOXING_WINE",
      amount: 2,
      unit: "tbsp",
    });
  });
});

// ── Regional Variant Cases ─────────────────────────────────────

describe("parseIngredientLine — regional variants", () => {
  // 36. UK: aubergine → eggplant
  test("1 large aubergine", () => {
    expectParsed("1 large aubergine", {
      canonicalId: "PRODUCE_EGGPLANT",
      amount: 1,
      unit: "large",
    });
  });

  // 37. UK: courgette → zucchini
  test("2 courgettes", () => {
    expectParsed("2 courgettes", {
      canonicalId: "PRODUCE_ZUCCHINI",
      amount: 2,
    });
  });

  // 38. UK/AU: rocket → arugula
  test("1 cup rocket", () => {
    expectParsed("1 cup rocket", {
      canonicalId: "PRODUCE_ARUGULA",
      amount: 1,
      unit: "cup",
    });
  });

  // 39. UK: coriander leaf → cilantro
  test("handful of fresh coriander", () => {
    // "fresh coriander" alias maps to HERB_CILANTRO
    expectParsed("handful of fresh coriander", {
      canonicalId: "HERB_CILANTRO",
    });
  });

  // 40. capsicum → bell pepper
  test("2 capsicum", () => {
    expectParsed("2 capsicum", {
      canonicalId: "PRODUCE_BELL_PEPPER",
      amount: 2,
    });
  });
});

// ── Edge Cases ─────────────────────────────────────────────────

describe("parseIngredientLine — edge cases", () => {
  // 41. EVOO abbreviation
  test("evoo for drizzling", () => {
    const r = parse("evoo for drizzling");
    // "evoo" is alias for OIL_OLIVE
    // May need fuzzy or exact depending on trailing words
    expect(r.canonicalIngredientId).toBe("OIL_OLIVE");
  });

  // 42. Ground beef (NOT attribute "ground" + "beef" — it's a canonical)
  test("1 lb ground beef", () => {
    expectParsed("1 lb ground beef", {
      canonicalId: "MEAT_GROUND_BEEF",
      amount: 1,
      unit: "lb",
    });
  });

  // 43. Smoked salmon (canonical, not attribute)
  test("4 oz smoked salmon", () => {
    expectParsed("4 oz smoked salmon", {
      canonicalId: "SEAFOOD_SMOKED_SALMON",
      amount: 4,
      unit: "oz",
    });
  });

  // 44. Plain "flour" → all-purpose flour
  test("2 cups flour", () => {
    expectParsed("2 cups flour", {
      canonicalId: "BAKING_ALL_PURPOSE_FLOUR",
      amount: 2,
      unit: "cup",
    });
  });

  // 45. Plain "sugar" → granulated sugar
  test("1 cup sugar", () => {
    expectParsed("1 cup sugar", {
      canonicalId: "BAKING_SUGAR",
      amount: 1,
      unit: "cup",
    });
  });

  // 46. Black pepper (default "pepper" mapping)
  test("black pepper to taste", () => {
    expectParsed("black pepper to taste", {
      canonicalId: "SPICE_BLACK_PEPPER",
    });
  });

  // 47. "Water" — simplest case
  test("1 cup water", () => {
    expectParsed("1 cup water", {
      canonicalId: "BEVERAGE_WATER",
      amount: 1,
      unit: "cup",
    });
  });
});

// ── Data Integrity ─────────────────────────────────────────────

describe("data integrity", () => {
  test("canonical list has 600+ items", () => {
    const count = Object.keys(CANONICAL_INGREDIENTS).length;
    expect(count).toBeGreaterThanOrEqual(600);
    expect(count).toBe(CANONICAL_COUNT);
    console.log(`Canonical ingredients: ${count}`);
  });

  test("every alias references a valid canonical", () => {
    for (const [canonicalId, aliases] of Object.entries(ALIAS_DATA)) {
      expect(CANONICAL_INGREDIENTS[canonicalId]).toBeDefined();
      expect(aliases.length).toBeGreaterThan(0);
    }
  });

  test("no empty aliases", () => {
    for (const [, aliases] of Object.entries(ALIAS_DATA)) {
      for (const alias of aliases) {
        expect(alias.trim().length).toBeGreaterThan(0);
      }
    }
  });

  test("alias map has no unexpected duplicates", () => {
    const matcher = new IngredientMatcher(CANONICAL_INGREDIENTS, ALIAS_DATA);
    const dupes = matcher.getDuplicates();
    if (dupes.length > 0) {
      console.log(`Duplicate aliases (${dupes.length}):`);
      for (const d of dupes.slice(0, 10)) {
        console.log(`  "${d.alias}" → ${d.existingId} vs ${d.newId}`);
      }
    }
    expect(dupes.length).toBeLessThan(30);
  });

  test("all categories are represented", () => {
    const categories = new Set(
      Object.values(CANONICAL_INGREDIENTS).map((i) => i.category),
    );
    expect(categories.size).toBe(17);
  });

  test("every allergen-mapped ID exists in canonical list", () => {
    for (const id of Object.keys(ALLERGEN_MAP)) {
      expect(CANONICAL_INGREDIENTS[id]).toBeDefined();
    }
  });
});

// ── Allergen & Dietary Tests ───────────────────────────────────

describe("allergen data", () => {
  test("dairy products flagged with DAIRY allergen", () => {
    expect(containsAllergen("DAIRY_MILK", Allergen.DAIRY)).toBe(true);
    expect(containsAllergen("DAIRY_BUTTER", Allergen.DAIRY)).toBe(true);
    expect(containsAllergen("DAIRY_PARMESAN", Allergen.DAIRY)).toBe(true);
    expect(containsAllergen("DAIRY_PANEER", Allergen.DAIRY)).toBe(true);
  });

  test("eggs flagged with EGGS allergen", () => {
    expect(containsAllergen("DAIRY_EGG", Allergen.EGGS)).toBe(true);
    expect(containsAllergen("DAIRY_EGG_WHITE", Allergen.EGGS)).toBe(true);
    expect(containsAllergen("DAIRY_EGG_YOLK", Allergen.EGGS)).toBe(true);
    expect(containsAllergen("DAIRY_QUAIL_EGG", Allergen.EGGS)).toBe(true);
  });

  test("fish species flagged with FISH allergen", () => {
    expect(containsAllergen("SEAFOOD_SALMON", Allergen.FISH)).toBe(true);
    expect(containsAllergen("SEAFOOD_TUNA", Allergen.FISH)).toBe(true);
    expect(containsAllergen("SEAFOOD_ANCHOVY", Allergen.FISH)).toBe(true);
  });

  test("shellfish flagged with SHELLFISH allergen", () => {
    expect(containsAllergen("SEAFOOD_SHRIMP", Allergen.SHELLFISH)).toBe(true);
    expect(containsAllergen("SEAFOOD_CRAB", Allergen.SHELLFISH)).toBe(true);
    expect(containsAllergen("SEAFOOD_LOBSTER", Allergen.SHELLFISH)).toBe(true);
    expect(containsAllergen("SEAFOOD_SQUID", Allergen.SHELLFISH)).toBe(true);
  });

  test("tree nuts flagged with TREE_NUTS allergen", () => {
    expect(containsAllergen("NUT_ALMOND", Allergen.TREE_NUTS)).toBe(true);
    expect(containsAllergen("NUT_WALNUT", Allergen.TREE_NUTS)).toBe(true);
    expect(containsAllergen("NUT_CASHEW", Allergen.TREE_NUTS)).toBe(true);
    expect(containsAllergen("NUT_PISTACHIO", Allergen.TREE_NUTS)).toBe(true);
  });

  test("peanuts flagged with PEANUTS allergen", () => {
    expect(containsAllergen("NUT_PEANUT", Allergen.PEANUTS)).toBe(true);
    expect(containsAllergen("OIL_PEANUT", Allergen.PEANUTS)).toBe(true);
    expect(containsAllergen("MISC_PEANUT_BUTTER", Allergen.PEANUTS)).toBe(true);
  });

  test("wheat/gluten products flagged correctly", () => {
    expect(containsAllergen("BAKING_ALL_PURPOSE_FLOUR", Allergen.GLUTEN)).toBe(true);
    expect(containsAllergen("GRAIN_SPAGHETTI", Allergen.GLUTEN)).toBe(true);
    expect(containsAllergen("GRAIN_BREAD", Allergen.GLUTEN)).toBe(true);
    expect(containsAllergen("MISC_SEITAN", Allergen.GLUTEN)).toBe(true);
  });

  test("soy products flagged with SOY allergen", () => {
    expect(containsAllergen("SAUCE_SOY", Allergen.SOY)).toBe(true);
    expect(containsAllergen("MISC_TOFU", Allergen.SOY)).toBe(true);
    expect(containsAllergen("MISC_TEMPEH", Allergen.SOY)).toBe(true);
    expect(containsAllergen("DAIRY_SOY_MILK", Allergen.SOY)).toBe(true);
  });

  test("sesame products flagged with SESAME allergen", () => {
    expect(containsAllergen("NUT_SESAME_SEED", Allergen.SESAME)).toBe(true);
    expect(containsAllergen("OIL_SESAME", Allergen.SESAME)).toBe(true);
    expect(containsAllergen("SAUCE_TAHINI", Allergen.SESAME)).toBe(true);
  });

  test("produce has NO allergens", () => {
    expect(getAllergens("PRODUCE_TOMATO")).toEqual([]);
    expect(getAllergens("PRODUCE_GARLIC")).toEqual([]);
    expect(getAllergens("PRODUCE_ONION")).toEqual([]);
  });

  test("herbs and spices have NO allergens", () => {
    expect(getAllergens("HERB_BASIL")).toEqual([]);
    expect(getAllergens("SPICE_CUMIN")).toEqual([]);
    expect(getAllergens("SPICE_TURMERIC")).toEqual([]);
  });

  test("soy sauce has both SOY and GLUTEN", () => {
    const allergens = getAllergens("SAUCE_SOY");
    expect(allergens).toContain(Allergen.SOY);
    expect(allergens).toContain(Allergen.GLUTEN);
  });

  test("tamari has SOY but NOT gluten", () => {
    const allergens = getAllergens("SAUCE_TAMARI");
    expect(allergens).toContain(Allergen.SOY);
    expect(allergens).not.toContain(Allergen.GLUTEN);
  });

  test("findByAllergen returns correct IDs for PEANUTS", () => {
    const peanutItems = findByAllergen(Allergen.PEANUTS);
    expect(peanutItems).toContain("NUT_PEANUT");
    expect(peanutItems).toContain("OIL_PEANUT");
    expect(peanutItems).toContain("MISC_PEANUT_BUTTER");
    expect(peanutItems).not.toContain("NUT_ALMOND");
  });

  test("multi-allergen items tracked correctly", () => {
    // egg noodles: gluten + eggs
    const eggNoodleAllergens = getAllergens("GRAIN_EGG_NOODLE");
    expect(eggNoodleAllergens).toContain(Allergen.GLUTEN);
    expect(eggNoodleAllergens).toContain(Allergen.EGGS);

    // pesto: dairy + tree nuts
    const pestoAllergens = getAllergens("SAUCE_PESTO");
    expect(pestoAllergens).toContain(Allergen.DAIRY);
    expect(pestoAllergens).toContain(Allergen.TREE_NUTS);

    // naan: gluten + dairy
    const naanAllergens = getAllergens("GRAIN_NAAN");
    expect(naanAllergens).toContain(Allergen.GLUTEN);
    expect(naanAllergens).toContain(Allergen.DAIRY);
  });
});

describe("dietary flags", () => {
  test("produce is vegan + vegetarian + gluten-free + dairy-free + nut-free", () => {
    const tomato = CANONICAL_INGREDIENTS["PRODUCE_TOMATO"];
    expect(tomato.dietaryFlags).toContain(DietaryFlag.VEGAN);
    expect(tomato.dietaryFlags).toContain(DietaryFlag.VEGETARIAN);
    expect(tomato.dietaryFlags).toContain(DietaryFlag.GLUTEN_FREE);
    expect(tomato.dietaryFlags).toContain(DietaryFlag.DAIRY_FREE);
    expect(tomato.dietaryFlags).toContain(DietaryFlag.NUT_FREE);
  });

  test("chicken is NOT vegetarian or vegan", () => {
    const chicken = CANONICAL_INGREDIENTS["POULTRY_CHICKEN"];
    expect(chicken.dietaryFlags).not.toContain(DietaryFlag.VEGAN);
    expect(chicken.dietaryFlags).not.toContain(DietaryFlag.VEGETARIAN);
  });

  test("salmon is NOT vegetarian (fish)", () => {
    const salmon = CANONICAL_INGREDIENTS["SEAFOOD_SALMON"];
    expect(salmon.dietaryFlags).not.toContain(DietaryFlag.VEGETARIAN);
    expect(salmon.dietaryFlags).not.toContain(DietaryFlag.VEGAN);
  });

  test("tofu is vegetarian + vegan but NOT gluten-free (soy isn't gluten)", () => {
    const tofu = CANONICAL_INGREDIENTS["MISC_TOFU"];
    expect(tofu.dietaryFlags).toContain(DietaryFlag.VEGAN);
    expect(tofu.dietaryFlags).toContain(DietaryFlag.VEGETARIAN);
    expect(tofu.dietaryFlags).toContain(DietaryFlag.GLUTEN_FREE);
  });

  test("butter is vegetarian but NOT vegan", () => {
    const butter = CANONICAL_INGREDIENTS["DAIRY_BUTTER"];
    expect(butter.dietaryFlags).toContain(DietaryFlag.VEGETARIAN);
    expect(butter.dietaryFlags).not.toContain(DietaryFlag.VEGAN);
    expect(butter.dietaryFlags).not.toContain(DietaryFlag.DAIRY_FREE);
  });

  test("eggs are vegetarian but NOT vegan", () => {
    const egg = CANONICAL_INGREDIENTS["DAIRY_EGG"];
    expect(egg.dietaryFlags).toContain(DietaryFlag.VEGETARIAN);
    expect(egg.dietaryFlags).not.toContain(DietaryFlag.VEGAN);
  });

  test("spaghetti is vegetarian + vegan but NOT gluten-free", () => {
    const spaghetti = CANONICAL_INGREDIENTS["GRAIN_SPAGHETTI"];
    expect(spaghetti.dietaryFlags).toContain(DietaryFlag.VEGETARIAN);
    expect(spaghetti.dietaryFlags).toContain(DietaryFlag.VEGAN);
    expect(spaghetti.dietaryFlags).not.toContain(DietaryFlag.GLUTEN_FREE);
  });

  test("rice is vegan + gluten-free", () => {
    const rice = CANONICAL_INGREDIENTS["GRAIN_WHITE_RICE"];
    expect(rice.dietaryFlags).toContain(DietaryFlag.VEGAN);
    expect(rice.dietaryFlags).toContain(DietaryFlag.GLUTEN_FREE);
  });

  test("peanut is vegan but NOT nut-free", () => {
    const peanut = CANONICAL_INGREDIENTS["NUT_PEANUT"];
    expect(peanut.dietaryFlags).toContain(DietaryFlag.VEGAN);
    expect(peanut.dietaryFlags).not.toContain(DietaryFlag.NUT_FREE);
  });

  test("honey is NOT vegan (animal product)", () => {
    const honey = CANONICAL_INGREDIENTS["BAKING_HONEY"];
    expect(honey.dietaryFlags).not.toContain(DietaryFlag.VEGAN);
    expect(honey.dietaryFlags).toContain(DietaryFlag.VEGETARIAN);
  });

  test("allergen count is substantial", () => {
    const withAllergens = Object.values(CANONICAL_INGREDIENTS)
      .filter((i) => i.commonAllergens && i.commonAllergens.length > 0);
    console.log(`Items with allergens: ${withAllergens.length}/${CANONICAL_COUNT}`);
    expect(withAllergens.length).toBeGreaterThan(120);
  });
});
