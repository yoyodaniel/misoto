// ─────────────────────────────────────────────────────────────
// Allergen & Dietary Data
//
// FDA "Big 9" allergen annotations for every relevant canonical
// ingredient. Only ingredients WITH allergens appear here —
// absence means the ingredient has no common allergens.
//
// IMPORTANT: This is a safety-relevant dataset. When extending,
// always verify against official allergen databases.
// ─────────────────────────────────────────────────────────────

import { Allergen, DietaryFlag, Category } from "../types";

const A = Allergen;

// ── Explicit Allergen Map ──────────────────────────────────────
// Every ingredient that carries one or more FDA Big 9 allergens.
// Format: CANONICAL_ID → [Allergen, ...]

export const ALLERGEN_MAP: Record<string, Allergen[]> = {

  // ─── DAIRY & EGGS ────────────────────────────────────────────
  DAIRY_MILK:             [A.DAIRY],
  DAIRY_WHOLE_MILK:       [A.DAIRY],
  DAIRY_BUTTERMILK:       [A.DAIRY],
  DAIRY_EVAPORATED_MILK:  [A.DAIRY],
  DAIRY_CONDENSED_MILK:   [A.DAIRY],
  DAIRY_CREAM:            [A.DAIRY],
  DAIRY_HEAVY_CREAM:      [A.DAIRY],
  DAIRY_HALF_AND_HALF:    [A.DAIRY],
  DAIRY_SOUR_CREAM:       [A.DAIRY],
  DAIRY_WHIPPING_CREAM:   [A.DAIRY],
  DAIRY_CREAM_CHEESE:     [A.DAIRY],
  DAIRY_BUTTER:           [A.DAIRY],
  DAIRY_GHEE:             [A.DAIRY],
  DAIRY_MARGARINE:        [A.DAIRY],
  DAIRY_YOGURT:           [A.DAIRY],
  DAIRY_GREEK_YOGURT:     [A.DAIRY],
  DAIRY_CHEDDAR:          [A.DAIRY],
  DAIRY_MOZZARELLA:       [A.DAIRY],
  DAIRY_PARMESAN:         [A.DAIRY],
  DAIRY_FETA:             [A.DAIRY],
  DAIRY_GOUDA:            [A.DAIRY],
  DAIRY_BRIE:             [A.DAIRY],
  DAIRY_SWISS_CHEESE:     [A.DAIRY],
  DAIRY_GOAT_CHEESE:      [A.DAIRY],
  DAIRY_RICOTTA:          [A.DAIRY],
  DAIRY_MASCARPONE:       [A.DAIRY],
  DAIRY_GRUYERE:          [A.DAIRY],
  DAIRY_BLUE_CHEESE:      [A.DAIRY],
  DAIRY_MONTEREY_JACK:    [A.DAIRY],
  DAIRY_COTIJA:           [A.DAIRY],
  DAIRY_PECORINO:         [A.DAIRY],
  DAIRY_PANEER:           [A.DAIRY],
  DAIRY_EGG:              [A.EGGS],
  DAIRY_EGG_WHITE:        [A.EGGS],
  DAIRY_EGG_YOLK:         [A.EGGS],
  DAIRY_QUAIL_EGG:        [A.EGGS],
  DAIRY_DUCK_EGG:         [A.EGGS],
  // Plant milks: no allergens from this list
  // DAIRY_COCONUT_MILK: none (coconut is not FDA tree nut)
  DAIRY_SOY_MILK:         [A.SOY],
  DAIRY_ALMOND_MILK:      [A.TREE_NUTS],
  // DAIRY_OAT_MILK: may contain gluten (depends on processing, not inherent)

  // ─── SEAFOOD ─────────────────────────────────────────────────
  // Fish
  SEAFOOD_SALMON:         [A.FISH],
  SEAFOOD_TUNA:           [A.FISH],
  SEAFOOD_COD:            [A.FISH],
  SEAFOOD_TILAPIA:        [A.FISH],
  SEAFOOD_SEA_BASS:       [A.FISH],
  SEAFOOD_HALIBUT:        [A.FISH],
  SEAFOOD_MAHI_MAHI:      [A.FISH],
  SEAFOOD_SWORDFISH:      [A.FISH],
  SEAFOOD_TROUT:          [A.FISH],
  SEAFOOD_SARDINE:        [A.FISH],
  SEAFOOD_MACKEREL:       [A.FISH],
  SEAFOOD_ANCHOVY:        [A.FISH],
  SEAFOOD_CATFISH:        [A.FISH],
  SEAFOOD_RED_SNAPPER:    [A.FISH],
  SEAFOOD_GROUPER:        [A.FISH],
  SEAFOOD_SOLE:           [A.FISH],
  SEAFOOD_FLOUNDER:       [A.FISH],
  SEAFOOD_HADDOCK:        [A.FISH],
  SEAFOOD_HERRING:        [A.FISH],
  SEAFOOD_CARP:           [A.FISH],
  SEAFOOD_MILKFISH:       [A.FISH],
  SEAFOOD_POMFRET:        [A.FISH],
  SEAFOOD_BARRAMUNDI:     [A.FISH],
  SEAFOOD_SMOKED_SALMON:  [A.FISH],
  SEAFOOD_FISH_CAKE:      [A.FISH],
  SEAFOOD_FISH_BALL:      [A.FISH],
  SEAFOOD_DRIED_ANCHOVY:  [A.FISH],

  // Shellfish (crustaceans & mollusks)
  SEAFOOD_SHRIMP:         [A.SHELLFISH],
  SEAFOOD_PRAWN:          [A.SHELLFISH],
  SEAFOOD_CRAB:           [A.SHELLFISH],
  SEAFOOD_LOBSTER:        [A.SHELLFISH],
  SEAFOOD_CRAWFISH:       [A.SHELLFISH],
  SEAFOOD_MUSSEL:         [A.SHELLFISH],
  SEAFOOD_CLAM:           [A.SHELLFISH],
  SEAFOOD_OYSTER:         [A.SHELLFISH],
  SEAFOOD_SCALLOP:        [A.SHELLFISH],
  SEAFOOD_SQUID:          [A.SHELLFISH],
  SEAFOOD_OCTOPUS:        [A.SHELLFISH],
  SEAFOOD_CUTTLEFISH:     [A.SHELLFISH],
  SEAFOOD_IMITATION_CRAB: [A.SHELLFISH, A.FISH],
  SEAFOOD_DRIED_SHRIMP:   [A.SHELLFISH],
  SEAFOOD_SHRIMP_PASTE:   [A.SHELLFISH],
  SEAFOOD_ABALONE:        [A.SHELLFISH],
  SEAFOOD_SEA_URCHIN:     [A.SHELLFISH],

  // ─── GRAINS (gluten-containing) ──────────────────────────────
  // Wheat-based pasta & noodles
  GRAIN_SPAGHETTI:        [A.GLUTEN],
  GRAIN_PENNE:            [A.GLUTEN],
  GRAIN_FETTUCCINE:       [A.GLUTEN],
  GRAIN_LINGUINE:         [A.GLUTEN],
  GRAIN_MACARONI:         [A.GLUTEN],
  GRAIN_RIGATONI:         [A.GLUTEN],
  GRAIN_ORZO:             [A.GLUTEN],
  GRAIN_LASAGNA:          [A.GLUTEN],
  GRAIN_PAPPARDELLE:      [A.GLUTEN],
  GRAIN_ANGEL_HAIR:       [A.GLUTEN],
  GRAIN_FARFALLE:         [A.GLUTEN],
  GRAIN_TORTELLINI:       [A.GLUTEN, A.EGGS],
  GRAIN_GNOCCHI:          [A.GLUTEN],
  GRAIN_EGG_NOODLE:       [A.GLUTEN, A.EGGS],
  GRAIN_RAMEN_NOODLE:     [A.GLUTEN],
  GRAIN_LO_MEIN:          [A.GLUTEN],
  GRAIN_UDON:             [A.GLUTEN],
  GRAIN_SOBA:             [A.GLUTEN],  // typically also has wheat

  // Wrappers
  GRAIN_WONTON_WRAPPER:   [A.GLUTEN],
  GRAIN_SPRING_ROLL_WRAPPER: [A.GLUTEN],
  GRAIN_DUMPLING_WRAPPER: [A.GLUTEN],
  GRAIN_PHYLLO_DOUGH:     [A.GLUTEN],

  // Bread
  GRAIN_BREAD:            [A.GLUTEN],
  GRAIN_PITA:             [A.GLUTEN],
  GRAIN_NAAN:             [A.GLUTEN, A.DAIRY],
  GRAIN_TORTILLA:         [A.GLUTEN],  // flour tortillas; corn tortillas are GF
  GRAIN_BAGUETTE:         [A.GLUTEN],
  GRAIN_CIABATTA:         [A.GLUTEN],
  GRAIN_FOCACCIA:         [A.GLUTEN],
  GRAIN_SOURDOUGH:        [A.GLUTEN],
  GRAIN_BREADCRUMBS:      [A.GLUTEN],
  GRAIN_PANKO:            [A.GLUTEN],

  // Grains with gluten
  GRAIN_BARLEY:           [A.GLUTEN],
  GRAIN_BULGUR:           [A.GLUTEN],
  GRAIN_COUSCOUS:         [A.GLUTEN],
  GRAIN_SEMOLINA:         [A.GLUTEN],
  GRAIN_FARRO:            [A.GLUTEN],
  // Note: oats are technically GF but often cross-contaminated

  // ─── LEGUMES ─────────────────────────────────────────────────
  LEGUME_SOYBEAN:         [A.SOY],
  LEGUME_MUNG_BEAN:       [],  // no Big 9

  NUT_PEANUT:             [A.PEANUTS],

  // ─── NUTS & SEEDS ────────────────────────────────────────────
  NUT_ALMOND:             [A.TREE_NUTS],
  NUT_WALNUT:             [A.TREE_NUTS],
  NUT_CASHEW:             [A.TREE_NUTS],
  NUT_PISTACHIO:          [A.TREE_NUTS],
  NUT_PECAN:              [A.TREE_NUTS],
  NUT_MACADAMIA:          [A.TREE_NUTS],
  NUT_HAZELNUT:           [A.TREE_NUTS],
  NUT_PINE_NUT:           [A.TREE_NUTS],
  NUT_CHESTNUT:           [A.TREE_NUTS],
  NUT_BRAZIL_NUT:         [A.TREE_NUTS],
  NUT_SESAME_SEED:        [A.SESAME],
  NUT_BLACK_SESAME_SEED:  [A.SESAME],
  // Sunflower, pumpkin, flax, chia, hemp, poppy: no Big 9

  // ─── OILS ────────────────────────────────────────────────────
  OIL_PEANUT:             [A.PEANUTS],
  OIL_SESAME:             [A.SESAME],
  // Note: highly refined peanut oil is often exempt, but we flag conservatively

  // ─── SAUCES & CONDIMENTS ─────────────────────────────────────
  SAUCE_SOY:              [A.SOY, A.GLUTEN],
  SAUCE_LIGHT_SOY:        [A.SOY, A.GLUTEN],
  SAUCE_DARK_SOY:         [A.SOY, A.GLUTEN],
  SAUCE_FISH:             [A.FISH],
  SAUCE_OYSTER:           [A.SHELLFISH],
  SAUCE_HOISIN:           [A.SOY, A.GLUTEN],
  SAUCE_TERIYAKI:         [A.SOY, A.GLUTEN],
  SAUCE_WORCESTERSHIRE:   [A.FISH],  // contains anchovies
  SAUCE_TAMARI:           [A.SOY],   // typically gluten-free soy sauce
  SAUCE_PONZU:            [A.SOY, A.FISH],
  SAUCE_GOCHUJANG:        [A.SOY, A.GLUTEN],
  SAUCE_DOENJANG:         [A.SOY],
  SAUCE_MISO_WHITE:       [A.SOY],
  SAUCE_MISO_RED:         [A.SOY],
  SAUCE_COCONUT_AMINOS:   [],  // soy-free alternative
  SAUCE_TAHINI:           [A.SESAME],
  SAUCE_BLACK_BEAN:       [A.SOY, A.GLUTEN],
  SAUCE_XO:               [A.SHELLFISH, A.FISH],
  SAUCE_PESTO:            [A.DAIRY, A.TREE_NUTS],  // traditional: parmesan + pine nuts
  SAUCE_MIRIN:            [A.GLUTEN],
  SAUCE_SAKE:             [],  // rice-based, no Big 9
  SAUCE_SHAOXING_WINE:    [A.GLUTEN],
  SAUCE_CHILI_GARLIC:     [],

  CONDIMENT_MAYONNAISE:   [A.EGGS],
  CONDIMENT_KIMCHI:       [A.FISH],  // traditionally contains fish sauce/shrimp paste
  CONDIMENT_ANCHOVY_PASTE:[A.FISH],

  // ─── BAKING ──────────────────────────────────────────────────
  // Wheat flours
  BAKING_ALL_PURPOSE_FLOUR:    [A.GLUTEN],
  BAKING_BREAD_FLOUR:          [A.GLUTEN],
  BAKING_CAKE_FLOUR:           [A.GLUTEN],
  BAKING_WHOLE_WHEAT_FLOUR:    [A.GLUTEN],
  BAKING_SELF_RISING_FLOUR:    [A.GLUTEN],
  // GRAIN_SEMOLINA already in grain section above
  // Gluten-free flours: rice, almond, coconut, chickpea — no gluten
  BAKING_ALMOND_FLOUR:         [A.TREE_NUTS],
  // Corn starch, tapioca starch, potato starch, arrowroot: no Big 9

  // ─── MISC ────────────────────────────────────────────────────
  MISC_TOFU:              [A.SOY],
  MISC_SILKEN_TOFU:       [A.SOY],
  MISC_FIRM_TOFU:         [A.SOY],
  MISC_EXTRA_FIRM_TOFU:   [A.SOY],
  MISC_TEMPEH:            [A.SOY],
  MISC_SEITAN:            [A.GLUTEN],
  MISC_BONITO_FLAKES:     [A.FISH],
  MISC_BELACAN:           [A.SHELLFISH],
  MISC_PEANUT_BUTTER:     [A.PEANUTS],
  MISC_ALMOND_BUTTER:     [A.TREE_NUTS],
  MISC_TAHINI_PASTE:      [A.SESAME],

  // ─── EXPANSION: New Allergens ──────────────────────────────

  // Seafood — Fish (new)
  SEAFOOD_EEL:            [A.FISH],
  SEAFOOD_CONGER_EEL:     [A.FISH],
  SEAFOOD_SEA_BREAM:      [A.FISH],
  SEAFOOD_YELLOWTAIL:     [A.FISH],
  SEAFOOD_WHITEBAIT:      [A.FISH],
  SEAFOOD_TOBIKO:         [A.FISH],
  SEAFOOD_SALMON_ROE:     [A.FISH],
  SEAFOOD_MENTAIKO:       [A.FISH],
  SEAFOOD_SKIPJACK_TUNA:  [A.FISH],
  SEAFOOD_BONITO:         [A.FISH],
  SEAFOOD_FISH_MAW:       [A.FISH],
  SEAFOOD_TURBOT:         [A.FISH],
  SEAFOOD_MONKFISH:       [A.FISH],
  SEAFOOD_PERCH:          [A.FISH],
  SEAFOOD_SMELT:          [A.FISH],
  SEAFOOD_BASA:           [A.FISH],
  SEAFOOD_SKATE:          [A.FISH],
  MISC_FISH_TOFU:         [A.FISH],  // made from fish

  // Seafood — Shellfish (new)
  SEAFOOD_DRIED_SCALLOP:  [A.SHELLFISH],
  SEAFOOD_SEA_CUCUMBER:   [A.SHELLFISH],
  SEAFOOD_JELLYFISH:      [],    // no Big 9 (cnidarian)
  SEAFOOD_DRIED_SQUID:    [A.SHELLFISH],
  SEAFOOD_RAZOR_CLAM:     [A.SHELLFISH],
  SEAFOOD_COCKLE:         [A.SHELLFISH],
  SEAFOOD_MANTIS_SHRIMP:  [A.SHELLFISH],
  SEAFOOD_WHELK:          [A.SHELLFISH],
  SEAFOOD_GEODUCK:        [A.SHELLFISH],
  SEAFOOD_SNOW_CRAB:      [A.SHELLFISH],
  SEAFOOD_KING_CRAB:      [A.SHELLFISH],
  SEAFOOD_SOFT_SHELL_CRAB:[A.SHELLFISH],
  SEAFOOD_LANGOUSTINE:    [A.SHELLFISH],

  // Dairy (new)
  DAIRY_CENTURY_EGG:      [A.EGGS],
  DAIRY_SALTED_EGG:       [A.EGGS],
  DAIRY_LABNEH:           [A.DAIRY],
  DAIRY_CLOTTED_CREAM:    [A.DAIRY],
  DAIRY_PROVOLONE:        [A.DAIRY],
  DAIRY_HAVARTI:          [A.DAIRY],
  DAIRY_HALLOUMI:         [A.DAIRY],
  DAIRY_BURRATA:          [A.DAIRY],
  DAIRY_CAMEMBERT:        [A.DAIRY],
  DAIRY_MANCHEGO:         [A.DAIRY],
  DAIRY_QUESO_FRESCO:     [A.DAIRY],
  DAIRY_CREME_FRAICHE:    [A.DAIRY],
  DAIRY_KEFIR:            [A.DAIRY],
  DAIRY_FROMAGE_BLANC:    [A.DAIRY],

  // Grains — Gluten (new)
  GRAIN_SOMEN:            [A.GLUTEN],
  GRAIN_FLAT_WHEAT_NOODLE:[A.GLUTEN],
  GRAIN_KALGUKSU:         [A.GLUTEN],
  GRAIN_MISUA:            [A.GLUTEN],
  GRAIN_INSTANT_NOODLE:   [A.GLUTEN],
  GRAIN_PUFF_PASTRY:      [A.GLUTEN, A.DAIRY],
  GRAIN_MANTOU:           [A.GLUTEN],
  GRAIN_BAO_BUN:          [A.GLUTEN],
  GRAIN_CHAPATI:          [A.GLUTEN],
  GRAIN_PARATHA:          [A.GLUTEN],
  GRAIN_LAVASH:           [A.GLUTEN],
  GRAIN_INJERA:           [],  // teff-based, typically GF
  GRAIN_PRAWN_CRACKER:    [A.SHELLFISH],
  GRAIN_IDLI:             [],  // rice + urad dal, GF
  GRAIN_DOSA:             [],  // rice + urad dal, GF
  GRAIN_CROISSANT:        [A.GLUTEN, A.DAIRY],
  GRAIN_BRIOCHE:          [A.GLUTEN, A.DAIRY, A.EGGS],
  GRAIN_ENGLISH_MUFFIN:   [A.GLUTEN],
  GRAIN_BAGEL:            [A.GLUTEN],
  GRAIN_NAENGMYEON:       [A.GLUTEN],  // typically buckwheat + wheat

  // Sauces (new)
  SAUCE_DOUBANJIANG:      [A.SOY, A.GLUTEN],
  SAUCE_TIAN_MIAN_JIANG:  [A.SOY, A.GLUTEN],
  SAUCE_FERMENTED_BEAN_CURD: [A.SOY],
  SAUCE_KECAP_MANIS:      [A.SOY, A.GLUTEN],
  SAUCE_SSAMJANG:         [A.SOY, A.GLUTEN],
  SAUCE_CHOGOCHUJANG:     [A.SOY, A.GLUTEN],
  SAUCE_KOREAN_BBQ_SAUCE: [A.SOY, A.GLUTEN],
  SAUCE_TONKATSU_SAUCE:   [A.SOY],
  SAUCE_MENTSUYU:         [A.SOY, A.FISH, A.GLUTEN],
  SAUCE_UNAGI_SAUCE:      [A.SOY, A.GLUTEN],
  SAUCE_TARE:             [A.SOY],
  SAUCE_YELLOW_BEAN_SAUCE:[A.SOY],
  SAUCE_SATAY_SAUCE:      [A.PEANUTS],
  SAUCE_ALFREDO:          [A.DAIRY, A.GLUTEN],
  SAUCE_NUOC_CHAM:        [A.FISH],
  SAUCE_NAM_JIM:          [A.FISH],
  SAUCE_PRIK_NAM_PLA:     [A.FISH],

  // Baking (new)
  BAKING_WHEAT_STARCH:    [],  // refined, typically GF
  BAKING_KINAKO:          [A.SOY],
  BAKING_BLACK_SESAME_POWDER: [A.SESAME],

  // Nuts (new)
  NUT_GINKGO:             [],  // no Big 9
  NUT_CANDIED_WALNUT:     [A.TREE_NUTS],
  NUT_ROASTED_PEANUT:     [A.PEANUTS],

  // Oils (new)
  OIL_PERILLA:            [],  // perilla is not a Big 9 allergen

  // Misc (new)
  MISC_NATTO:             [A.SOY],
  MISC_TOFU_SKIN:         [A.SOY],
  MISC_FRIED_TOFU:        [A.SOY],
  MISC_TOFU_PUFF:         [A.SOY],
  MISC_KOJI:              [],  // rice-based
  MISC_BLACK_SESAME_PASTE:[A.SESAME],
  MISC_SAKE_KASU:         [],
  MISC_COCONUT_CREAM_POWDER: [],
  MISC_YEAST_EXTRACT:     [],

  // Condiments (new)
  CONDIMENT_FERMENTED_BLACK_BEAN: [A.SOY],
  CONDIMENT_SAMBAL_MATAH: [],
  CONDIMENT_MENMA:        [],

  // Spices (new)
  SPICE_FURIKAKE:         [A.FISH, A.SESAME],  // typically contains bonito + sesame
  SPICE_DASHI_POWDER:     [A.FISH],
  SPICE_DRIED_SHRIMP_POWDER: [A.SHELLFISH],

  // Beverages (new)
  BEVERAGE_ANCHOVY_BROTH: [A.FISH],
  BEVERAGE_CLAM_JUICE:    [A.SHELLFISH],
  BEVERAGE_BONE_BROTH:    [],
  BEVERAGE_KELP_BROTH:    [],
  BEVERAGE_SOJU:          [],

  // Final fill
  DAIRY_COTTAGE_CHEESE:   [A.DAIRY],
  SAUCE_HOLLANDAISE:      [A.DAIRY, A.EGGS],
  SAUCE_TZATZIKI:         [A.DAIRY],
  SAUCE_BELACHAN_PASTE:   [A.SHELLFISH],
  CONDIMENT_SAMBAL_TERASI:[A.SHELLFISH],
  SAUCE_MAKGEOLLI:        [],
  SAUCE_DOUFU_RU:         [A.SOY],
};

// ── Dietary Flag Computation ───────────────────────────────────
// Instead of manually maintaining dietary flags for 626 items,
// we compute them from category + allergens.

/** Categories that are NEVER vegan */
const NON_VEGAN_CATEGORIES = new Set([
  Category.MEAT, Category.POULTRY, Category.SEAFOOD,
]);

/** Categories that are NEVER vegetarian */
const NON_VEGETARIAN_CATEGORIES = new Set([
  Category.MEAT, Category.POULTRY,
]);

/**
 * Compute dietary compatibility flags for a given ingredient.
 * This is the single source of truth — never hardcode dietary flags.
 */
export function computeDietaryFlags(
  id: string,
  category: Category,
  allergens: Allergen[],
): DietaryFlag[] {
  const flags: DietaryFlag[] = [];
  const allergenSet = new Set(allergens);

  // Gluten-free: no gluten allergen
  if (!allergenSet.has(A.GLUTEN)) {
    flags.push(DietaryFlag.GLUTEN_FREE);
  }

  // Dairy-free: no dairy allergen
  if (!allergenSet.has(A.DAIRY)) {
    flags.push(DietaryFlag.DAIRY_FREE);
  }

  // Nut-free: no tree nuts and no peanuts
  if (!allergenSet.has(A.TREE_NUTS) && !allergenSet.has(A.PEANUTS)) {
    flags.push(DietaryFlag.NUT_FREE);
  }

  // Vegetarian: not meat or poultry, and no fish/shellfish allergen
  // (seafood category items are not vegetarian, but some sauces with fish are also not)
  const isVegetarian =
    !NON_VEGETARIAN_CATEGORIES.has(category) &&
    !allergenSet.has(A.FISH) &&
    !allergenSet.has(A.SHELLFISH) &&
    category !== Category.SEAFOOD;
  if (isVegetarian) {
    flags.push(DietaryFlag.VEGETARIAN);
  }

  // Vegan: vegetarian + no dairy + no eggs + honey exception (we don't track honey separately)
  const isVegan =
    isVegetarian &&
    !NON_VEGAN_CATEGORIES.has(category) &&
    !allergenSet.has(A.DAIRY) &&
    !allergenSet.has(A.EGGS) &&
    !id.includes("HONEY") &&
    !id.includes("EGG");
  if (isVegan) {
    flags.push(DietaryFlag.VEGAN);
  }

  return flags;
}

/**
 * Look up allergens for a canonical ingredient ID.
 * Returns empty array if no allergens known.
 */
export function getAllergens(id: string): Allergen[] {
  return ALLERGEN_MAP[id] ?? [];
}

/**
 * Check if an ingredient contains a specific allergen.
 */
export function containsAllergen(id: string, allergen: Allergen): boolean {
  return (ALLERGEN_MAP[id] ?? []).includes(allergen);
}

/**
 * Find all ingredient IDs that contain a given allergen.
 * Useful for building exclusion lists.
 */
export function findByAllergen(allergen: Allergen): string[] {
  return Object.entries(ALLERGEN_MAP)
    .filter(([, allergens]) => allergens.includes(allergen))
    .map(([id]) => id);
}
