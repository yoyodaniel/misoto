/**
 * Export ingredient data as JSON bundles for the iOS app.
 *
 * Merges:
 *   - Curated canonical data (canonical.ts, aliases.ts, allergens.ts)
 *   - Expansion data (expansion.ts, expansion2.ts, expansion3.ts, expansion4.ts)
 *
 * Outputs:
 *   - CanonicalIngredients.json  (id, name, category, defaultUnitHint)
 *   - IngredientAliases.json     (alias → canonicalId flat lookup)
 *   - IngredientAllergens.json   (canonicalId → allergens[], dietaryFlags[])
 *
 * Usage:  npx ts-node scripts/export-json.ts
 */

import * as fs from "fs";
import * as path from "path";
import { CANONICAL_INGREDIENTS } from "../src/data/canonical";
import { ALIAS_DATA } from "../src/data/aliases";
import { ALLERGEN_MAP, computeDietaryFlags } from "../src/data/allergens";
import { Category, Allergen } from "../src/types";
import { EXPANSION } from "../src/data/expansion";
import { EXPANSION2 } from "../src/data/expansion2";
import { EXPANSION3 } from "../src/data/expansion3";
import { EXPANSION4 } from "../src/data/expansion4";

const OUTPUT_DIR = path.resolve(__dirname, "../../Misoto");

// ── Helpers ─────────────────────────────────────────────────

const CATEGORY_MAP: Record<string, Category> = {
  produce: Category.PRODUCE,  meat: Category.MEAT,      poultry: Category.POULTRY,
  seafood: Category.SEAFOOD,  dairy: Category.DAIRY,     grain: Category.GRAIN,
  legume: Category.LEGUME,    spice: Category.SPICE,     herb: Category.HERB,
  oil: Category.OIL,          vinegar: Category.VINEGAR, sauce: Category.SAUCE,
  condiment: Category.CONDIMENT, baking: Category.BAKING, nut: Category.NUT,
  beverage: Category.BEVERAGE, misc: Category.MISC,
  egg: Category.DAIRY,        sweetener: Category.BAKING,
  seafood_extra: Category.SEAFOOD, meat_extra: Category.MEAT,
  produce_extra: Category.PRODUCE,
};

function nameToId(name: string): string {
  return name
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/['']/g, "")
    .replace(/[^a-zA-Z0-9\s]/g, " ")
    .trim()
    .replace(/\s+/g, "_")
    .toUpperCase();
}

function generateAliases(name: string): string[] {
  const lower = name.toLowerCase();
  const aliases = new Set<string>();
  aliases.add(lower);

  if (lower.endsWith("y") && !lower.endsWith("ey") && !lower.endsWith("oy")) {
    aliases.add(lower.slice(0, -1) + "ies");
  } else if (lower.endsWith("sh") || lower.endsWith("ch") || lower.endsWith("x") || lower.endsWith("s")) {
    aliases.add(lower + "es");
  } else if (lower.endsWith("f")) {
    aliases.add(lower.slice(0, -1) + "ves");
  } else if (lower.endsWith("fe")) {
    aliases.add(lower.slice(0, -2) + "ves");
  } else if (!lower.endsWith("s")) {
    aliases.add(lower + "s");
  }

  const stripped = lower.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  if (stripped !== lower) aliases.add(stripped);

  return Array.from(aliases);
}

function inferAllergens(id: string, category: Category, name: string): Allergen[] {
  const lname = name.toLowerCase();
  const allergens: Allergen[] = [];

  if (category === Category.DAIRY) {
    if (lname.includes("coconut") || lname.includes("almond") ||
        lname.includes("soy") || lname.includes("oat") ||
        lname.includes("cashew") || lname.includes("hemp") ||
        lname.includes("rice milk") || lname.includes("vegan") ||
        lname.includes("plant-based") || lname.includes("pea milk") ||
        lname.includes("flax milk") || lname.includes("hazelnut milk") ||
        lname.includes("walnut milk") || lname.includes("pecan milk") ||
        lname.includes("pistachio milk") || lname.includes("tiger nut") ||
        lname.includes("potato milk") || lname.includes("banana milk")) {
      if (lname.includes("soy")) allergens.push(Allergen.SOY);
      if (lname.includes("almond")) allergens.push(Allergen.TREE_NUTS);
      if (lname.includes("cashew")) allergens.push(Allergen.TREE_NUTS);
      if (lname.includes("hazelnut")) allergens.push(Allergen.TREE_NUTS);
      if (lname.includes("walnut")) allergens.push(Allergen.TREE_NUTS);
      if (lname.includes("pecan")) allergens.push(Allergen.TREE_NUTS);
      if (lname.includes("pistachio")) allergens.push(Allergen.TREE_NUTS);
      if (lname.includes("macadamia")) allergens.push(Allergen.TREE_NUTS);
    } else if (lname.includes("egg")) {
      allergens.push(Allergen.EGGS);
    } else {
      allergens.push(Allergen.DAIRY);
    }
  }

  if (category === Category.SEAFOOD) {
    const shellfish = ["shrimp","prawn","crab","lobster","crayfish","crawfish","langoustine",
      "scampi","clam","mussel","oyster","scallop","squid","calamari","cuttlefish",
      "octopus","abalone","whelk","conch","periwinkle","escargot","sea urchin","uni",
      "sea cucumber","jellyfish","mantis shrimp","geoduck","cockle","surimi",
      "imitation crab","barnacle","limpet","sea squirt","ebi","hotate","tako",
      "ika","shako","kuruma"];
    if (shellfish.some(s => lname.includes(s))) {
      allergens.push(Allergen.SHELLFISH);
    } else {
      allergens.push(Allergen.FISH);
    }
  }

  if (category === Category.NUT) {
    const peanutTerms = ["peanut"];
    const seedTerms = ["sesame","sunflower seed","pumpkin seed","pepita","flax","chia",
      "hemp seed","hemp heart","poppy seed","nigella","watermelon seed","lotus seed",
      "fennel seed","caraway seed","cumin seed","coriander seed","mustard seed",
      "celery seed","dill seed","anise seed","fenugreek seed","basil seed","sabja",
      "perilla seed","egusi","melon seed","charoli","makhana","fox nut","amaranth seed"];
    const isPeanut = peanutTerms.some(t => lname.includes(t));
    const isSeed = seedTerms.some(t => lname.includes(t));

    if (isPeanut) {
      allergens.push(Allergen.PEANUTS);
    } else if (lname.includes("sesame") || lname.includes("tahini") || lname.includes("halva") || lname.includes("gomashio")) {
      allergens.push(Allergen.SESAME);
    } else if (lname.includes("coconut")) {
      // skip
    } else if (!isSeed) {
      allergens.push(Allergen.TREE_NUTS);
    }
  }

  if (category === Category.GRAIN) {
    const glutenFree = ["rice","corn","quinoa","millet","buckwheat","teff","sorghum",
      "amaranth","polenta","grits","hominy","tapioca","arrowroot","potato","gluten-free",
      "shirataki","konnyaku","glass noodle","cellophane","bean thread","mung bean",
      "sweet potato noodle","kelp","fonio","job's tears","hato mugi","adlay","coix",
      "idli","dosa","appam","uttapam","pesarattu","puttu","masa","nixtamalized",
      "cheung fun","bánh cuốn"];
    const hasGluten = !glutenFree.some(g => lname.includes(g));
    if (hasGluten) allergens.push(Allergen.GLUTEN);
  }

  if (category === Category.BAKING) {
    const glutenFlours = ["all-purpose","bread flour","cake flour","pastry flour",
      "self-rising","whole wheat","rye","pumpernickel","spelt","semolina","tipo 00",
      "durum","vital wheat gluten","seitan","einkorn","kamut","triticale","wheat",
      "french t4","french t5","french t6","german type","japanese bread flour",
      "chapati flour","atta flour","maida flour","tempura flour","takoyaki flour",
      "okonomiyaki flour"];
    if (glutenFlours.some(g => lname.includes(g))) allergens.push(Allergen.GLUTEN);
    if (lname.includes("almond flour") || lname.includes("almond meal") ||
        lname.includes("hazelnut") || lname.includes("pistachio") ||
        lname.includes("almond paste") || lname.includes("marzipan") ||
        lname.includes("almond extract") || lname.includes("nutella") ||
        lname.includes("frangelico") || lname.includes("praline") ||
        lname.includes("gianduja")) {
      allergens.push(Allergen.TREE_NUTS);
    }
    if (lname.includes("peanut")) allergens.push(Allergen.PEANUTS);
    if (lname.includes("milk chocolate") || lname.includes("butter")) allergens.push(Allergen.DAIRY);
    if (lname.includes("sesame")) allergens.push(Allergen.SESAME);
  }

  if (category === Category.SAUCE) {
    if (lname.includes("soy") || lname.includes("shoyu") || lname.includes("tamari") ||
        lname.includes("teriyaki") || lname.includes("hoisin") || lname.includes("miso") ||
        lname.includes("doenjang") || lname.includes("gochujang") ||
        lname.includes("doubanjiang") || lname.includes("bean paste") ||
        lname.includes("kecap") || lname.includes("jjajang") || lname.includes("chunjang")) {
      allergens.push(Allergen.SOY);
    }
    if (lname.includes("fish sauce") || lname.includes("nam pla") || lname.includes("nuoc mam") ||
        lname.includes("patis") || lname.includes("anchovy") || lname.includes("garum") ||
        lname.includes("colatura") || lname.includes("bonito") ||
        lname.includes("worcestershire") || lname.includes("ponzu") ||
        lname.includes("katsuobushi") || lname.includes("dashi") ||
        lname.includes("jeotgal") || lname.includes("myeolchi") || lname.includes("tuk trey")) {
      allergens.push(Allergen.FISH);
    }
    if (lname.includes("oyster sauce")) allergens.push(Allergen.SHELLFISH);
    if (lname.includes("shrimp") || lname.includes("belacan") ||
        lname.includes("kapi") || lname.includes("bagoong") || lname.includes("xo sauce") ||
        lname.includes("saeujeot")) {
      allergens.push(Allergen.SHELLFISH);
    }
    if (lname.includes("peanut") || lname.includes("satay")) allergens.push(Allergen.PEANUTS);
    if (lname.includes("alfredo") || lname.includes("béchamel") || lname.includes("mornay") ||
        lname.includes("cream sauce") || lname.includes("hollandaise") || lname.includes("béarnaise") ||
        lname.includes("carbonara") || lname.includes("cacio e pepe") || lname.includes("cheese sauce") ||
        lname.includes("huancaina")) {
      allergens.push(Allergen.DAIRY);
    }
    if (lname.includes("sesame") || lname.includes("goma")) allergens.push(Allergen.SESAME);
    if (lname.includes("walnut") || lname.includes("pistachio pesto") || lname.includes("noci")) {
      allergens.push(Allergen.TREE_NUTS);
    }
    if (lname.includes("mayo") || lname.includes("aioli")) allergens.push(Allergen.EGGS);
  }

  if (category === Category.CONDIMENT) {
    if (lname.includes("soy") || lname.includes("miso") || lname.includes("fermented black bean") ||
        lname.includes("douchi") || lname.includes("chunjang") || lname.includes("doenjang")) {
      allergens.push(Allergen.SOY);
    }
    if (lname.includes("tahini") || lname.includes("sesame") || lname.includes("gomashio") || lname.includes("goma")) {
      allergens.push(Allergen.SESAME);
    }
    if (lname.includes("fish") || lname.includes("anchovy") || lname.includes("bonito") ||
        lname.includes("katsuobushi") || lname.includes("niboshi") || lname.includes("jeotgal")) {
      allergens.push(Allergen.FISH);
    }
    if (lname.includes("shrimp") || lname.includes("belacan") || lname.includes("saeujeot")) {
      allergens.push(Allergen.SHELLFISH);
    }
    if (lname.includes("mayo") || lname.includes("aioli")) allergens.push(Allergen.EGGS);
    if (lname.includes("peanut") || lname.includes("chili crisp peanut")) allergens.push(Allergen.PEANUTS);
    if ((lname.includes("nut") && !lname.includes("nutri") && !lname.includes("nutmeg") &&
         !lname.includes("coconut")) || lname.includes("dukkah") || lname.includes("walnut")) {
      allergens.push(Allergen.TREE_NUTS);
    }
    if (lname.includes("furikake")) {
      allergens.push(Allergen.FISH);
      allergens.push(Allergen.SESAME);
    }
  }

  if (category === Category.LEGUME) {
    if (lname.includes("soy") || lname.includes("tofu") || lname.includes("tempeh") ||
        lname.includes("natto") || lname.includes("miso") || lname.includes("edamame") ||
        lname.includes("yuba") || lname.includes("bean curd") || lname.includes("douhua") ||
        lname.includes("taho") || lname.includes("tau foo")) {
      allergens.push(Allergen.SOY);
    }
  }

  if (category === Category.SPICE) {
    if (lname.includes("sesame")) allergens.push(Allergen.SESAME);
    if (lname.includes("furikake")) {
      allergens.push(Allergen.FISH);
      allergens.push(Allergen.SESAME);
    }
    if (lname.includes("dashi") || lname.includes("bonito")) allergens.push(Allergen.FISH);
    if (lname.includes("shrimp")) allergens.push(Allergen.SHELLFISH);
    if (lname.includes("peanut")) allergens.push(Allergen.PEANUTS);
  }

  if (category === Category.OIL) {
    if (lname.includes("sesame")) allergens.push(Allergen.SESAME);
    if (lname.includes("peanut")) allergens.push(Allergen.PEANUTS);
    if (lname.includes("walnut") || lname.includes("almond") || lname.includes("hazelnut") ||
        lname.includes("pistachio") || lname.includes("macadamia") || lname.includes("pecan") ||
        lname.includes("pine nut") || lname.includes("cashew") || lname.includes("brazil nut")) {
      allergens.push(Allergen.TREE_NUTS);
    }
    if (lname.includes("soybean")) allergens.push(Allergen.SOY);
  }

  if (category === Category.POULTRY) {
    if (lname.includes("egg")) allergens.push(Allergen.EGGS);
  }

  if (category === Category.MISC) {
    if (lname.includes("soy") || lname.includes("tofu") || lname.includes("tempeh") ||
        lname.includes("bean curd")) {
      allergens.push(Allergen.SOY);
    }
    if (lname.includes("gluten") || lname.includes("seitan") || lname.includes("wheat gluten")) {
      allergens.push(Allergen.GLUTEN);
    }
    if (lname.includes("shrimp") || lname.includes("prawn") || lname.includes("shellfish")) {
      allergens.push(Allergen.SHELLFISH);
    }
    if (lname.includes("fish") || lname.includes("anchovy") || lname.includes("bonito") ||
        lname.includes("dashi") || lname.includes("niboshi")) {
      allergens.push(Allergen.FISH);
    }
    if (lname.includes("egg roll wrapper") || lname.includes("egg wash") || lname.includes("egg noodle")) {
      allergens.push(Allergen.EGGS);
    }
    if (lname.includes("wonton") || lname.includes("dumpling") || lname.includes("mandu") ||
        lname.includes("gyoza") || lname.includes("panko") || lname.includes("breadcrumb") ||
        lname.includes("tempura") || lname.includes("frying flour") || lname.includes("ramen") ||
        lname.includes("udon") || lname.includes("curry roux") || lname.includes("curry block") ||
        lname.includes("noodle soup base") || lname.includes("stuffing") || lname.includes("crouton") ||
        lname.includes("grissini") || lname.includes("rusk") || lname.includes("biscuit") ||
        lname.includes("cracker") || lname.includes("pretzel")) {
      allergens.push(Allergen.GLUTEN);
    }
    if (lname.includes("peanut")) allergens.push(Allergen.PEANUTS);
    if (lname.includes("sesame")) allergens.push(Allergen.SESAME);
  }

  if (category === Category.BEVERAGE) {
    if (lname.includes("beer") || lname.includes("ale") || lname.includes("stout") ||
        lname.includes("porter") || lname.includes("pilsner") || lname.includes("lager") ||
        lname.includes("wheat beer")) {
      allergens.push(Allergen.GLUTEN);
    }
    if (lname.includes("soy milk")) allergens.push(Allergen.SOY);
    if (lname.includes("almond milk")) allergens.push(Allergen.TREE_NUTS);
    if (lname.includes("anchovy") || lname.includes("dashi") || lname.includes("bonito") || lname.includes("niboshi")) {
      allergens.push(Allergen.FISH);
    }
    if (lname.includes("clam")) allergens.push(Allergen.SHELLFISH);
  }

  return [...new Set(allergens)];
}

// ── Build Merged Data ───────────────────────────────────────

interface CanonicalJSON { id: string; name: string; category: string; defaultUnitHint?: string; }
interface AllergenEntry { id: string; allergens: string[]; dietaryFlags: string[]; }

const allCanonicals: CanonicalJSON[] = [];
const allAliases: Record<string, string> = {};
const allAllergenEntries: AllergenEntry[] = [];
const existingIds = new Set<string>();
const existingNames = new Set<string>();

// ── 1. Load curated canonicals ──
for (const item of Object.values(CANONICAL_INGREDIENTS)) {
  allCanonicals.push({
    id: item.id, name: item.name, category: item.category,
    ...(item.defaultUnitHint ? { defaultUnitHint: item.defaultUnitHint } : {}),
  });
  existingIds.add(item.id);
  existingNames.add(item.name.toLowerCase());
}
console.log(`📌 Curated canonicals: ${allCanonicals.length}`);

// ── 2. Load curated aliases ──
for (const [canonicalId, aliases] of Object.entries(ALIAS_DATA)) {
  for (const alias of aliases) {
    const key = alias.toLowerCase().trim();
    if (!allAliases[key]) allAliases[key] = canonicalId;
  }
}
for (const item of Object.values(CANONICAL_INGREDIENTS)) {
  const key = item.name.toLowerCase().trim();
  if (!allAliases[key]) allAliases[key] = item.id;
}
console.log(`📌 Curated aliases: ${Object.keys(allAliases).length}`);

// ── 3. Load curated allergens ──
for (const item of Object.values(CANONICAL_INGREDIENTS)) {
  const allergens = ALLERGEN_MAP[item.id] ?? [];
  const flags = computeDietaryFlags(item.id, item.category, allergens);
  allAllergenEntries.push({
    id: item.id,
    allergens: allergens.map(a => a.toString()),
    dietaryFlags: flags.map(f => f.toString()),
  });
}

// ── 4. Process ALL expansion datasets ──
const expansionSets: [string, Record<string, string[]>][] = [
  ["Expansion 1", EXPANSION],
  ["Expansion 2", EXPANSION2],
  ["Expansion 3", EXPANSION3],
  ["Expansion 4", EXPANSION4],
];

for (const [label, dataset] of expansionSets) {
  let added = 0;
  let skipped = 0;

  for (const [categoryKey, names] of Object.entries(dataset)) {
    const category = CATEGORY_MAP[categoryKey];
    if (!category) { console.warn(`⚠️ Unknown category "${categoryKey}" in ${label}`); continue; }
    const prefix = categoryKey.replace(/_extra$/i, "").toUpperCase();

    for (const name of names) {
      const fullId = `${prefix}_${nameToId(name)}`;
      if (existingIds.has(fullId) || existingNames.has(name.toLowerCase())) { skipped++; continue; }

      allCanonicals.push({ id: fullId, name, category });
      existingIds.add(fullId);
      existingNames.add(name.toLowerCase());
      added++;

      for (const alias of generateAliases(name)) {
        const key = alias.toLowerCase().trim();
        if (!allAliases[key]) allAliases[key] = fullId;
      }

      const allergens = inferAllergens(fullId, category, name);
      const flags = computeDietaryFlags(fullId, category, allergens);
      allAllergenEntries.push({
        id: fullId,
        allergens: allergens.map(a => a.toString()),
        dietaryFlags: flags.map(f => f.toString()),
      });
    }
  }
  console.log(`➕ ${label}: ${added} added (${skipped} skipped)`);
}

// ── 5. Write JSON files ─────────────────────────────────────
fs.writeFileSync(path.join(OUTPUT_DIR, "CanonicalIngredients.json"), JSON.stringify(allCanonicals, null, 2), "utf-8");
console.log(`✅ CanonicalIngredients.json — ${allCanonicals.length} items`);

fs.writeFileSync(path.join(OUTPUT_DIR, "IngredientAliases.json"), JSON.stringify(allAliases, null, 2), "utf-8");
console.log(`✅ IngredientAliases.json — ${Object.keys(allAliases).length} aliases`);

fs.writeFileSync(path.join(OUTPUT_DIR, "IngredientAllergens.json"), JSON.stringify(allAllergenEntries, null, 2), "utf-8");
console.log(`✅ IngredientAllergens.json — ${allAllergenEntries.length} items`);

console.log(`\n📦 Total canonical ingredients: ${allCanonicals.length}`);
console.log(`📦 All files written to ${OUTPUT_DIR}`);
