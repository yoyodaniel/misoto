// ─────────────────────────────────────────────────────────────
// Canonical Ingredient Seed List
// ~650 items covering 95%+ of global recipe ingredients
//
// ID convention: CATEGORY_INGREDIENT_NAME (UPPER_SNAKE_CASE)
// Extend by adding entries — IDs are stable once assigned.
// ─────────────────────────────────────────────────────────────

import { Category, CanonicalIngredient } from "../types";

// Category shorthand
const P  = Category.PRODUCE;
const M  = Category.MEAT;
const PO = Category.POULTRY;
const SF = Category.SEAFOOD;
const D  = Category.DAIRY;
const G  = Category.GRAIN;
const L  = Category.LEGUME;
const SP = Category.SPICE;
const H  = Category.HERB;
const O  = Category.OIL;
const V  = Category.VINEGAR;
const SA = Category.SAUCE;
const CO = Category.CONDIMENT;
const B  = Category.BAKING;
const N  = Category.NUT;
const BV = Category.BEVERAGE;
const MI = Category.MISC;

// Compact data: [name, category, defaultUnitHint?]
type Def = [string, Category, string?];

const DATA: Record<string, Def> = {

  // ════════════════════════════════════════════════════════════
  // PRODUCE — Vegetables
  // ════════════════════════════════════════════════════════════

  // Nightshades
  PRODUCE_TOMATO:              ["Tomato", P, "piece"],
  PRODUCE_CHERRY_TOMATO:       ["Cherry Tomato", P, "cup"],
  PRODUCE_GRAPE_TOMATO:        ["Grape Tomato", P, "cup"],
  PRODUCE_POTATO:              ["Potato", P, "piece"],
  PRODUCE_SWEET_POTATO:        ["Sweet Potato", P, "piece"],
  PRODUCE_EGGPLANT:            ["Eggplant", P, "piece"],
  PRODUCE_CHINESE_EGGPLANT:    ["Chinese Eggplant", P, "piece"],
  PRODUCE_THAI_EGGPLANT:       ["Thai Eggplant", P, "piece"],
  PRODUCE_BELL_PEPPER:         ["Bell Pepper", P, "piece"],
  PRODUCE_RED_BELL_PEPPER:     ["Red Bell Pepper", P, "piece"],
  PRODUCE_GREEN_BELL_PEPPER:   ["Green Bell Pepper", P, "piece"],
  PRODUCE_YELLOW_BELL_PEPPER:  ["Yellow Bell Pepper", P, "piece"],
  PRODUCE_CHILI_PEPPER:        ["Chili Pepper", P, "piece"],
  PRODUCE_JALAPENO:            ["Jalapeño", P, "piece"],
  PRODUCE_SERRANO:             ["Serrano Pepper", P, "piece"],
  PRODUCE_HABANERO:            ["Habanero Pepper", P, "piece"],
  PRODUCE_THAI_CHILI:          ["Thai Chili", P, "piece"],
  PRODUCE_POBLANO:             ["Poblano Pepper", P, "piece"],
  PRODUCE_ANAHEIM_PEPPER:      ["Anaheim Pepper", P, "piece"],
  PRODUCE_SCOTCH_BONNET:       ["Scotch Bonnet", P, "piece"],
  PRODUCE_BIRDS_EYE_CHILI:     ["Bird's Eye Chili", P, "piece"],

  // Alliums
  PRODUCE_ONION:               ["Onion", P, "piece"],
  PRODUCE_RED_ONION:           ["Red Onion", P, "piece"],
  PRODUCE_WHITE_ONION:         ["White Onion", P, "piece"],
  PRODUCE_SHALLOT:             ["Shallot", P, "piece"],
  PRODUCE_SCALLION:            ["Scallion", P, "bunch"],
  PRODUCE_LEEK:                ["Leek", P, "stalk"],
  PRODUCE_GARLIC:              ["Garlic", P, "clove"],
  PRODUCE_PEARL_ONION:         ["Pearl Onion", P, "piece"],

  // Roots & Tubers
  PRODUCE_CARROT:              ["Carrot", P, "piece"],
  PRODUCE_GINGER:              ["Ginger", P, "inch"],
  PRODUCE_GALANGAL:            ["Galangal", P, "inch"],
  PRODUCE_TURMERIC_ROOT:       ["Fresh Turmeric", P, "inch"],
  PRODUCE_DAIKON:              ["Daikon", P, "piece"],
  PRODUCE_RADISH:              ["Radish", P, "piece"],
  PRODUCE_TURNIP:              ["Turnip", P, "piece"],
  PRODUCE_BEET:                ["Beet", P, "piece"],
  PRODUCE_PARSNIP:             ["Parsnip", P, "piece"],
  PRODUCE_RUTABAGA:            ["Rutabaga", P, "piece"],
  PRODUCE_CELERIAC:            ["Celeriac", P, "piece"],
  PRODUCE_JICAMA:              ["Jicama", P, "piece"],
  PRODUCE_HORSERADISH:         ["Horseradish Root", P, "piece"],
  PRODUCE_TARO:                ["Taro", P, "piece"],
  PRODUCE_YAM:                 ["Yam", P, "piece"],
  PRODUCE_CASSAVA:             ["Cassava", P, "piece"],
  PRODUCE_LOTUS_ROOT:          ["Lotus Root", P, "piece"],
  PRODUCE_WATER_CHESTNUT:      ["Water Chestnut", P, "piece"],
  PRODUCE_KOHLRABI:            ["Kohlrabi", P, "piece"],

  // Cucurbits
  PRODUCE_CUCUMBER:            ["Cucumber", P, "piece"],
  PRODUCE_ZUCCHINI:            ["Zucchini", P, "piece"],
  PRODUCE_YELLOW_SQUASH:       ["Yellow Squash", P, "piece"],
  PRODUCE_BUTTERNUT_SQUASH:    ["Butternut Squash", P, "piece"],
  PRODUCE_ACORN_SQUASH:        ["Acorn Squash", P, "piece"],
  PRODUCE_KABOCHA:             ["Kabocha Squash", P, "piece"],
  PRODUCE_SPAGHETTI_SQUASH:    ["Spaghetti Squash", P, "piece"],
  PRODUCE_PUMPKIN:             ["Pumpkin", P, "piece"],
  PRODUCE_BITTER_MELON:        ["Bitter Melon", P, "piece"],
  PRODUCE_CHAYOTE:             ["Chayote", P, "piece"],
  PRODUCE_WINTER_MELON:        ["Winter Melon", P, "piece"],
  PRODUCE_LOOFAH:              ["Loofah Gourd", P, "piece"],

  // Brassicas
  PRODUCE_BROCCOLI:            ["Broccoli", P, "head"],
  PRODUCE_BROCCOLI_RABE:       ["Broccoli Rabe", P, "bunch"],
  PRODUCE_CAULIFLOWER:         ["Cauliflower", P, "head"],
  PRODUCE_CABBAGE:             ["Cabbage", P, "head"],
  PRODUCE_RED_CABBAGE:         ["Red Cabbage", P, "head"],
  PRODUCE_NAPA_CABBAGE:        ["Napa Cabbage", P, "head"],
  PRODUCE_BOK_CHOY:            ["Bok Choy", P, "bunch"],
  PRODUCE_BRUSSELS_SPROUT:     ["Brussels Sprout", P, "cup"],
  PRODUCE_KALE:                ["Kale", P, "bunch"],
  PRODUCE_CHINESE_BROCCOLI:    ["Chinese Broccoli", P, "bunch"],

  // Leafy Greens
  PRODUCE_SPINACH:             ["Spinach", P, "cup"],
  PRODUCE_LETTUCE:             ["Lettuce", P, "head"],
  PRODUCE_ROMAINE_LETTUCE:     ["Romaine Lettuce", P, "head"],
  PRODUCE_ICEBERG_LETTUCE:     ["Iceberg Lettuce", P, "head"],
  PRODUCE_ARUGULA:             ["Arugula", P, "cup"],
  PRODUCE_WATERCRESS:          ["Watercress", P, "bunch"],
  PRODUCE_SWISS_CHARD:         ["Swiss Chard", P, "bunch"],
  PRODUCE_COLLARD_GREENS:      ["Collard Greens", P, "bunch"],
  PRODUCE_MUSTARD_GREENS:      ["Mustard Greens", P, "bunch"],
  PRODUCE_ENDIVE:              ["Endive", P, "head"],
  PRODUCE_RADICCHIO:           ["Radicchio", P, "head"],

  // Stalks & Stems
  PRODUCE_CELERY:              ["Celery", P, "stalk"],
  PRODUCE_FENNEL:              ["Fennel", P, "bulb"],
  PRODUCE_ASPARAGUS:           ["Asparagus", P, "bunch"],
  PRODUCE_ARTICHOKE:           ["Artichoke", P, "piece"],
  PRODUCE_HEARTS_OF_PALM:      ["Hearts of Palm", P, "can"],
  PRODUCE_RHUBARB:             ["Rhubarb", P, "stalk"],

  // Pods & Green Vegetables
  PRODUCE_GREEN_BEAN:          ["Green Bean", P, "cup"],
  PRODUCE_LONG_BEAN:           ["Long Bean", P, "bunch"],
  PRODUCE_PEA:                 ["Pea", P, "cup"],
  PRODUCE_SNAP_PEA:            ["Snap Pea", P, "cup"],
  PRODUCE_SNOW_PEA:            ["Snow Pea", P, "cup"],
  PRODUCE_EDAMAME:             ["Edamame", P, "cup"],
  PRODUCE_OKRA:                ["Okra", P, "cup"],
  PRODUCE_CORN:                ["Corn", P, "ear"],
  PRODUCE_BABY_CORN:           ["Baby Corn", P, "piece"],

  // Asian Vegetables
  PRODUCE_BAMBOO_SHOOT:        ["Bamboo Shoot", P, "cup"],
  PRODUCE_BEAN_SPROUT:         ["Bean Sprout", P, "cup"],
  PRODUCE_MORNING_GLORY:       ["Morning Glory", P, "bunch"],
  PRODUCE_CHINESE_CELERY:      ["Chinese Celery", P, "bunch"],
  PRODUCE_BANANA_BLOSSOM:      ["Banana Blossom", P, "piece"],
  PRODUCE_CORIANDER_ROOT:      ["Coriander Root", P, "piece"],

  // Mushrooms
  PRODUCE_MUSHROOM:            ["Mushroom", P, "cup"],
  PRODUCE_WHITE_MUSHROOM:      ["White Mushroom", P, "cup"],
  PRODUCE_CREMINI:             ["Cremini Mushroom", P, "cup"],
  PRODUCE_PORTOBELLO:          ["Portobello Mushroom", P, "piece"],
  PRODUCE_SHIITAKE:            ["Shiitake Mushroom", P, "piece"],
  PRODUCE_OYSTER_MUSHROOM:     ["Oyster Mushroom", P, "cup"],
  PRODUCE_ENOKI:               ["Enoki Mushroom", P, "package"],
  PRODUCE_KING_OYSTER_MUSHROOM:["King Oyster Mushroom", P, "piece"],
  PRODUCE_CHANTERELLE:         ["Chanterelle", P, "cup"],
  PRODUCE_WOOD_EAR:            ["Wood Ear Mushroom", P, "cup"],
  PRODUCE_MAITAKE:             ["Maitake Mushroom", P, "cup"],

  // ════════════════════════════════════════════════════════════
  // PRODUCE — Fruits
  // ════════════════════════════════════════════════════════════

  PRODUCE_AVOCADO:             ["Avocado", P, "piece"],
  PRODUCE_LEMON:               ["Lemon", P, "piece"],
  PRODUCE_LIME:                ["Lime", P, "piece"],
  PRODUCE_ORANGE:              ["Orange", P, "piece"],
  PRODUCE_GRAPEFRUIT:          ["Grapefruit", P, "piece"],
  PRODUCE_TANGERINE:           ["Tangerine", P, "piece"],
  PRODUCE_YUZU:                ["Yuzu", P, "piece"],
  PRODUCE_CALAMANSI:           ["Calamansi", P, "piece"],
  PRODUCE_KUMQUAT:             ["Kumquat", P, "piece"],
  PRODUCE_MANGO:               ["Mango", P, "piece"],
  PRODUCE_PINEAPPLE:           ["Pineapple", P, "piece"],
  PRODUCE_BANANA:              ["Banana", P, "piece"],
  PRODUCE_PLANTAIN:            ["Plantain", P, "piece"],
  PRODUCE_COCONUT:             ["Coconut", P, "piece"],
  PRODUCE_APPLE:               ["Apple", P, "piece"],
  PRODUCE_PEAR:                ["Pear", P, "piece"],
  PRODUCE_PEACH:               ["Peach", P, "piece"],
  PRODUCE_PLUM:                ["Plum", P, "piece"],
  PRODUCE_NECTARINE:           ["Nectarine", P, "piece"],
  PRODUCE_APRICOT:             ["Apricot", P, "piece"],
  PRODUCE_CHERRY:              ["Cherry", P, "cup"],
  PRODUCE_GRAPE:               ["Grape", P, "cup"],
  PRODUCE_STRAWBERRY:          ["Strawberry", P, "cup"],
  PRODUCE_BLUEBERRY:           ["Blueberry", P, "cup"],
  PRODUCE_RASPBERRY:           ["Raspberry", P, "cup"],
  PRODUCE_BLACKBERRY:          ["Blackberry", P, "cup"],
  PRODUCE_CRANBERRY:           ["Cranberry", P, "cup"],
  PRODUCE_POMEGRANATE:         ["Pomegranate", P, "piece"],
  PRODUCE_FIG:                 ["Fig", P, "piece"],
  PRODUCE_DATE:                ["Date", P, "piece"],
  PRODUCE_PAPAYA:              ["Papaya", P, "piece"],
  PRODUCE_GUAVA:               ["Guava", P, "piece"],
  PRODUCE_PASSION_FRUIT:       ["Passion Fruit", P, "piece"],
  PRODUCE_LYCHEE:              ["Lychee", P, "piece"],
  PRODUCE_DRAGON_FRUIT:        ["Dragon Fruit", P, "piece"],
  PRODUCE_JACKFRUIT:           ["Jackfruit", P, "cup"],
  PRODUCE_DURIAN:              ["Durian", P, "piece"],
  PRODUCE_TAMARIND:            ["Tamarind", P, "tbsp"],
  PRODUCE_WATERMELON:          ["Watermelon", P, "cup"],
  PRODUCE_CANTALOUPE:          ["Cantaloupe", P, "cup"],
  PRODUCE_HONEYDEW:            ["Honeydew Melon", P, "cup"],
  PRODUCE_PERSIMMON:           ["Persimmon", P, "piece"],
  PRODUCE_STARFRUIT:           ["Starfruit", P, "piece"],
  PRODUCE_KIWI:                ["Kiwi", P, "piece"],

  // Dried Fruits
  PRODUCE_RAISIN:              ["Raisin", P, "cup"],
  PRODUCE_DRIED_CRANBERRY:     ["Dried Cranberry", P, "cup"],
  PRODUCE_DRIED_APRICOT:       ["Dried Apricot", P, "piece"],
  PRODUCE_PRUNE:               ["Prune", P, "piece"],
  PRODUCE_DRIED_FIG:           ["Dried Fig", P, "piece"],

  // ════════════════════════════════════════════════════════════
  // MEAT (Red Meat & Processed)
  // ════════════════════════════════════════════════════════════

  MEAT_BEEF:                   ["Beef", M, "lb"],
  MEAT_BEEF_STEAK:             ["Beef Steak", M, "piece"],
  MEAT_GROUND_BEEF:            ["Ground Beef", M, "lb"],
  MEAT_BEEF_BRISKET:           ["Beef Brisket", M, "lb"],
  MEAT_BEEF_SHORT_RIB:         ["Beef Short Rib", M, "lb"],
  MEAT_BEEF_CHUCK:             ["Beef Chuck", M, "lb"],
  MEAT_BEEF_TENDERLOIN:        ["Beef Tenderloin", M, "lb"],
  MEAT_BEEF_SIRLOIN:           ["Beef Sirloin", M, "lb"],
  MEAT_STEW_BEEF:              ["Stew Beef", M, "lb"],
  MEAT_CORNED_BEEF:            ["Corned Beef", M, "lb"],
  MEAT_PORK:                   ["Pork", M, "lb"],
  MEAT_PORK_BELLY:             ["Pork Belly", M, "lb"],
  MEAT_PORK_CHOP:              ["Pork Chop", M, "piece"],
  MEAT_GROUND_PORK:            ["Ground Pork", M, "lb"],
  MEAT_PORK_LOIN:              ["Pork Loin", M, "lb"],
  MEAT_PORK_SHOULDER:          ["Pork Shoulder", M, "lb"],
  MEAT_PORK_RIB:               ["Pork Rib", M, "lb"],
  MEAT_PORK_TENDERLOIN:        ["Pork Tenderloin", M, "lb"],
  MEAT_LAMB:                   ["Lamb", M, "lb"],
  MEAT_LAMB_CHOP:              ["Lamb Chop", M, "piece"],
  MEAT_GROUND_LAMB:            ["Ground Lamb", M, "lb"],
  MEAT_LAMB_LEG:               ["Lamb Leg", M, "lb"],
  MEAT_LAMB_SHANK:             ["Lamb Shank", M, "piece"],
  MEAT_VEAL:                   ["Veal", M, "lb"],
  MEAT_GOAT:                   ["Goat", M, "lb"],
  MEAT_VENISON:                ["Venison", M, "lb"],
  MEAT_RABBIT:                 ["Rabbit", M, "lb"],
  MEAT_BACON:                  ["Bacon", M, "slice"],
  MEAT_HAM:                    ["Ham", M, "lb"],
  MEAT_PROSCIUTTO:             ["Prosciutto", M, "slice"],
  MEAT_PANCETTA:               ["Pancetta", M, "oz"],
  MEAT_SAUSAGE:                ["Sausage", M, "piece"],
  MEAT_CHORIZO:                ["Chorizo", M, "piece"],
  MEAT_SALAMI:                 ["Salami", M, "slice"],
  MEAT_SPAM:                   ["Spam", M, "can"],
  MEAT_JERKY:                  ["Beef Jerky", M, "oz"],

  // ════════════════════════════════════════════════════════════
  // POULTRY
  // ════════════════════════════════════════════════════════════

  POULTRY_CHICKEN:             ["Chicken", PO, "lb"],
  POULTRY_CHICKEN_BREAST:      ["Chicken Breast", PO, "piece"],
  POULTRY_CHICKEN_THIGH:       ["Chicken Thigh", PO, "piece"],
  POULTRY_CHICKEN_WING:        ["Chicken Wing", PO, "piece"],
  POULTRY_CHICKEN_DRUMSTICK:   ["Chicken Drumstick", PO, "piece"],
  POULTRY_GROUND_CHICKEN:      ["Ground Chicken", PO, "lb"],
  POULTRY_CHICKEN_LIVER:       ["Chicken Liver", PO, "lb"],
  POULTRY_DUCK:                ["Duck", PO, "lb"],
  POULTRY_DUCK_BREAST:         ["Duck Breast", PO, "piece"],
  POULTRY_TURKEY:              ["Turkey", PO, "lb"],
  POULTRY_GROUND_TURKEY:       ["Ground Turkey", PO, "lb"],
  POULTRY_QUAIL:               ["Quail", PO, "piece"],
  POULTRY_GOOSE:               ["Goose", PO, "lb"],
  POULTRY_CORNISH_HEN:         ["Cornish Hen", PO, "piece"],

  // ════════════════════════════════════════════════════════════
  // SEAFOOD
  // ════════════════════════════════════════════════════════════

  // Fish
  SEAFOOD_SALMON:              ["Salmon", SF, "piece"],
  SEAFOOD_TUNA:                ["Tuna", SF, "piece"],
  SEAFOOD_COD:                 ["Cod", SF, "piece"],
  SEAFOOD_TILAPIA:             ["Tilapia", SF, "piece"],
  SEAFOOD_SEA_BASS:            ["Sea Bass", SF, "piece"],
  SEAFOOD_HALIBUT:             ["Halibut", SF, "piece"],
  SEAFOOD_MAHI_MAHI:           ["Mahi Mahi", SF, "piece"],
  SEAFOOD_SWORDFISH:           ["Swordfish", SF, "piece"],
  SEAFOOD_TROUT:               ["Trout", SF, "piece"],
  SEAFOOD_SARDINE:             ["Sardine", SF, "can"],
  SEAFOOD_MACKEREL:            ["Mackerel", SF, "piece"],
  SEAFOOD_ANCHOVY:             ["Anchovy", SF, "piece"],
  SEAFOOD_CATFISH:             ["Catfish", SF, "piece"],
  SEAFOOD_RED_SNAPPER:         ["Red Snapper", SF, "piece"],
  SEAFOOD_GROUPER:             ["Grouper", SF, "piece"],
  SEAFOOD_SOLE:                ["Sole", SF, "piece"],
  SEAFOOD_FLOUNDER:            ["Flounder", SF, "piece"],
  SEAFOOD_HADDOCK:             ["Haddock", SF, "piece"],
  SEAFOOD_HERRING:             ["Herring", SF, "piece"],
  SEAFOOD_CARP:                ["Carp", SF, "piece"],
  SEAFOOD_MILKFISH:            ["Milkfish", SF, "piece"],
  SEAFOOD_POMFRET:             ["Pomfret", SF, "piece"],
  SEAFOOD_BARRAMUNDI:          ["Barramundi", SF, "piece"],
  SEAFOOD_SMOKED_SALMON:       ["Smoked Salmon", SF, "oz"],

  // Shellfish & Crustaceans
  SEAFOOD_SHRIMP:              ["Shrimp", SF, "lb"],
  SEAFOOD_PRAWN:               ["Prawn", SF, "lb"],
  SEAFOOD_CRAB:                ["Crab", SF, "lb"],
  SEAFOOD_LOBSTER:             ["Lobster", SF, "piece"],
  SEAFOOD_CRAWFISH:            ["Crawfish", SF, "lb"],
  SEAFOOD_MUSSEL:              ["Mussel", SF, "lb"],
  SEAFOOD_CLAM:                ["Clam", SF, "lb"],
  SEAFOOD_OYSTER:              ["Oyster", SF, "piece"],
  SEAFOOD_SCALLOP:             ["Scallop", SF, "piece"],

  // Cephalopods
  SEAFOOD_SQUID:               ["Squid", SF, "lb"],
  SEAFOOD_OCTOPUS:             ["Octopus", SF, "lb"],
  SEAFOOD_CUTTLEFISH:          ["Cuttlefish", SF, "lb"],

  // Processed Seafood
  SEAFOOD_FISH_CAKE:           ["Fish Cake", SF, "piece"],
  SEAFOOD_IMITATION_CRAB:      ["Imitation Crab", SF, "oz"],
  SEAFOOD_DRIED_SHRIMP:        ["Dried Shrimp", SF, "tbsp"],
  SEAFOOD_FISH_BALL:           ["Fish Ball", SF, "piece"],
  SEAFOOD_SHRIMP_PASTE:        ["Shrimp Paste", SF, "tsp"],
  SEAFOOD_DRIED_ANCHOVY:       ["Dried Anchovy", SF, "cup"],
  SEAFOOD_ABALONE:             ["Abalone", SF, "piece"],
  SEAFOOD_SEA_URCHIN:          ["Sea Urchin", SF, "piece"],

  // ════════════════════════════════════════════════════════════
  // DAIRY & EGGS
  // ════════════════════════════════════════════════════════════

  DAIRY_MILK:                  ["Milk", D, "cup"],
  DAIRY_WHOLE_MILK:            ["Whole Milk", D, "cup"],
  DAIRY_BUTTERMILK:            ["Buttermilk", D, "cup"],
  DAIRY_EVAPORATED_MILK:       ["Evaporated Milk", D, "can"],
  DAIRY_CONDENSED_MILK:        ["Condensed Milk", D, "can"],
  DAIRY_CREAM:                 ["Cream", D, "cup"],
  DAIRY_HEAVY_CREAM:           ["Heavy Cream", D, "cup"],
  DAIRY_HALF_AND_HALF:         ["Half and Half", D, "cup"],
  DAIRY_SOUR_CREAM:            ["Sour Cream", D, "cup"],
  DAIRY_WHIPPING_CREAM:        ["Whipping Cream", D, "cup"],
  DAIRY_CREAM_CHEESE:          ["Cream Cheese", D, "oz"],
  DAIRY_BUTTER:                ["Butter", D, "tbsp"],
  DAIRY_GHEE:                  ["Ghee", D, "tbsp"],
  DAIRY_MARGARINE:             ["Margarine", D, "tbsp"],
  DAIRY_YOGURT:                ["Yogurt", D, "cup"],
  DAIRY_GREEK_YOGURT:          ["Greek Yogurt", D, "cup"],
  DAIRY_CHEDDAR:               ["Cheddar Cheese", D, "cup"],
  DAIRY_MOZZARELLA:            ["Mozzarella", D, "cup"],
  DAIRY_PARMESAN:              ["Parmesan", D, "cup"],
  DAIRY_FETA:                  ["Feta Cheese", D, "cup"],
  DAIRY_GOUDA:                 ["Gouda", D, "oz"],
  DAIRY_BRIE:                  ["Brie", D, "oz"],
  DAIRY_SWISS_CHEESE:          ["Swiss Cheese", D, "slice"],
  DAIRY_GOAT_CHEESE:           ["Goat Cheese", D, "oz"],
  DAIRY_RICOTTA:               ["Ricotta", D, "cup"],
  DAIRY_MASCARPONE:            ["Mascarpone", D, "cup"],
  DAIRY_GRUYERE:               ["Gruyère", D, "cup"],
  DAIRY_BLUE_CHEESE:           ["Blue Cheese", D, "oz"],
  DAIRY_MONTEREY_JACK:         ["Monterey Jack", D, "cup"],
  DAIRY_COTIJA:                ["Cotija Cheese", D, "cup"],
  DAIRY_PECORINO:              ["Pecorino Romano", D, "cup"],
  DAIRY_PANEER:                ["Paneer", D, "cup"],
  DAIRY_EGG:                   ["Egg", D, "piece"],
  DAIRY_EGG_WHITE:             ["Egg White", D, "piece"],
  DAIRY_EGG_YOLK:              ["Egg Yolk", D, "piece"],
  DAIRY_QUAIL_EGG:             ["Quail Egg", D, "piece"],
  DAIRY_DUCK_EGG:              ["Duck Egg", D, "piece"],
  DAIRY_COCONUT_MILK:          ["Coconut Milk", D, "can"],
  DAIRY_COCONUT_CREAM:         ["Coconut Cream", D, "can"],
  DAIRY_SOY_MILK:              ["Soy Milk", D, "cup"],
  DAIRY_ALMOND_MILK:           ["Almond Milk", D, "cup"],
  DAIRY_OAT_MILK:              ["Oat Milk", D, "cup"],

  // ════════════════════════════════════════════════════════════
  // GRAINS, PASTA, NOODLES, BREAD
  // ════════════════════════════════════════════════════════════

  // Rice
  GRAIN_WHITE_RICE:            ["White Rice", G, "cup"],
  GRAIN_BROWN_RICE:            ["Brown Rice", G, "cup"],
  GRAIN_JASMINE_RICE:          ["Jasmine Rice", G, "cup"],
  GRAIN_BASMATI_RICE:          ["Basmati Rice", G, "cup"],
  GRAIN_SUSHI_RICE:            ["Sushi Rice", G, "cup"],
  GRAIN_STICKY_RICE:           ["Sticky Rice", G, "cup"],
  GRAIN_WILD_RICE:             ["Wild Rice", G, "cup"],
  GRAIN_ARBORIO_RICE:          ["Arborio Rice", G, "cup"],

  // Pasta
  GRAIN_SPAGHETTI:             ["Spaghetti", G, "oz"],
  GRAIN_PENNE:                 ["Penne", G, "oz"],
  GRAIN_FETTUCCINE:            ["Fettuccine", G, "oz"],
  GRAIN_LINGUINE:              ["Linguine", G, "oz"],
  GRAIN_MACARONI:              ["Macaroni", G, "oz"],
  GRAIN_RIGATONI:              ["Rigatoni", G, "oz"],
  GRAIN_ORZO:                  ["Orzo", G, "cup"],
  GRAIN_LASAGNA:               ["Lasagna Sheets", G, "sheet"],
  GRAIN_PAPPARDELLE:           ["Pappardelle", G, "oz"],
  GRAIN_ANGEL_HAIR:            ["Angel Hair Pasta", G, "oz"],
  GRAIN_FARFALLE:              ["Farfalle", G, "oz"],
  GRAIN_TORTELLINI:            ["Tortellini", G, "oz"],
  GRAIN_GNOCCHI:               ["Gnocchi", G, "oz"],

  // Asian Noodles
  GRAIN_EGG_NOODLE:            ["Egg Noodle", G, "oz"],
  GRAIN_RICE_NOODLE:           ["Rice Noodle", G, "oz"],
  GRAIN_GLASS_NOODLE:          ["Glass Noodle", G, "oz"],
  GRAIN_UDON:                  ["Udon Noodle", G, "oz"],
  GRAIN_SOBA:                  ["Soba Noodle", G, "oz"],
  GRAIN_RAMEN_NOODLE:          ["Ramen Noodle", G, "oz"],
  GRAIN_RICE_VERMICELLI:       ["Rice Vermicelli", G, "oz"],
  GRAIN_LO_MEIN:               ["Lo Mein Noodle", G, "oz"],

  // Wrappers
  GRAIN_RICE_PAPER:            ["Rice Paper", G, "sheet"],
  GRAIN_WONTON_WRAPPER:        ["Wonton Wrapper", G, "sheet"],
  GRAIN_SPRING_ROLL_WRAPPER:   ["Spring Roll Wrapper", G, "sheet"],
  GRAIN_DUMPLING_WRAPPER:      ["Dumpling Wrapper", G, "sheet"],
  GRAIN_PHYLLO_DOUGH:          ["Phyllo Dough", G, "sheet"],

  // Bread
  GRAIN_BREAD:                 ["Bread", G, "slice"],
  GRAIN_PITA:                  ["Pita Bread", G, "piece"],
  GRAIN_NAAN:                  ["Naan", G, "piece"],
  GRAIN_TORTILLA:              ["Tortilla", G, "piece"],
  GRAIN_BAGUETTE:              ["Baguette", G, "piece"],
  GRAIN_CIABATTA:              ["Ciabatta", G, "piece"],
  GRAIN_FOCACCIA:              ["Focaccia", G, "piece"],
  GRAIN_SOURDOUGH:             ["Sourdough Bread", G, "slice"],
  GRAIN_BREADCRUMBS:           ["Breadcrumbs", G, "cup"],
  GRAIN_PANKO:                 ["Panko Breadcrumbs", G, "cup"],

  // Other Grains
  GRAIN_OATS:                  ["Oats", G, "cup"],
  GRAIN_QUINOA:                ["Quinoa", G, "cup"],
  GRAIN_BARLEY:                ["Barley", G, "cup"],
  GRAIN_MILLET:                ["Millet", G, "cup"],
  GRAIN_BUCKWHEAT:             ["Buckwheat", G, "cup"],
  GRAIN_CORNMEAL:              ["Cornmeal", G, "cup"],
  GRAIN_POLENTA:               ["Polenta", G, "cup"],
  GRAIN_COUSCOUS:              ["Couscous", G, "cup"],
  GRAIN_BULGUR:                ["Bulgur Wheat", G, "cup"],
  GRAIN_SEMOLINA:              ["Semolina", G, "cup"],
  GRAIN_GRITS:                 ["Grits", G, "cup"],
  GRAIN_WHEAT_GERM:            ["Wheat Germ", G, "tbsp"],
  GRAIN_FARRO:                 ["Farro", G, "cup"],

  // ════════════════════════════════════════════════════════════
  // LEGUMES
  // ════════════════════════════════════════════════════════════

  LEGUME_CHICKPEA:             ["Chickpea", L, "cup"],
  LEGUME_LENTIL:               ["Lentil", L, "cup"],
  LEGUME_RED_LENTIL:           ["Red Lentil", L, "cup"],
  LEGUME_GREEN_LENTIL:         ["Green Lentil", L, "cup"],
  LEGUME_BLACK_BEAN:           ["Black Bean", L, "cup"],
  LEGUME_KIDNEY_BEAN:          ["Kidney Bean", L, "cup"],
  LEGUME_PINTO_BEAN:           ["Pinto Bean", L, "cup"],
  LEGUME_NAVY_BEAN:            ["Navy Bean", L, "cup"],
  LEGUME_CANNELLINI_BEAN:      ["Cannellini Bean", L, "cup"],
  LEGUME_LIMA_BEAN:            ["Lima Bean", L, "cup"],
  LEGUME_MUNG_BEAN:            ["Mung Bean", L, "cup"],
  LEGUME_SOYBEAN:              ["Soybean", L, "cup"],
  LEGUME_BLACK_EYED_PEA:       ["Black-Eyed Pea", L, "cup"],
  LEGUME_FAVA_BEAN:            ["Fava Bean", L, "cup"],
  LEGUME_SPLIT_PEA:            ["Split Pea", L, "cup"],
  LEGUME_ADZUKI_BEAN:          ["Adzuki Bean", L, "cup"],
  LEGUME_WHITE_BEAN:           ["White Bean", L, "cup"],
  LEGUME_GREAT_NORTHERN_BEAN:  ["Great Northern Bean", L, "cup"],

  // ════════════════════════════════════════════════════════════
  // SPICES
  // ════════════════════════════════════════════════════════════

  SPICE_SALT:                  ["Salt", SP, "tsp"],
  SPICE_SEA_SALT:              ["Sea Salt", SP, "tsp"],
  SPICE_KOSHER_SALT:           ["Kosher Salt", SP, "tsp"],
  SPICE_BLACK_PEPPER:          ["Black Pepper", SP, "tsp"],
  SPICE_WHITE_PEPPER:          ["White Pepper", SP, "tsp"],
  SPICE_CUMIN:                 ["Cumin", SP, "tsp"],
  SPICE_CORIANDER_SEED:        ["Coriander Seed", SP, "tsp"],
  SPICE_TURMERIC:              ["Turmeric", SP, "tsp"],
  SPICE_PAPRIKA:               ["Paprika", SP, "tsp"],
  SPICE_SMOKED_PAPRIKA:        ["Smoked Paprika", SP, "tsp"],
  SPICE_CHILI_POWDER:          ["Chili Powder", SP, "tsp"],
  SPICE_CAYENNE:               ["Cayenne Pepper", SP, "tsp"],
  SPICE_RED_PEPPER_FLAKES:     ["Red Pepper Flakes", SP, "tsp"],
  SPICE_CINNAMON:              ["Cinnamon", SP, "tsp"],
  SPICE_NUTMEG:                ["Nutmeg", SP, "tsp"],
  SPICE_CLOVE:                 ["Clove", SP, "piece"],
  SPICE_ALLSPICE:              ["Allspice", SP, "tsp"],
  SPICE_CARDAMOM:              ["Cardamom", SP, "tsp"],
  SPICE_STAR_ANISE:            ["Star Anise", SP, "piece"],
  SPICE_FENNEL_SEED:           ["Fennel Seed", SP, "tsp"],
  SPICE_MUSTARD_SEED:          ["Mustard Seed", SP, "tsp"],
  SPICE_GARAM_MASALA:          ["Garam Masala", SP, "tsp"],
  SPICE_CURRY_POWDER:          ["Curry Powder", SP, "tsp"],
  SPICE_FIVE_SPICE:            ["Five Spice Powder", SP, "tsp"],
  SPICE_SAFFRON:               ["Saffron", SP, "pinch"],
  SPICE_SUMAC:                 ["Sumac", SP, "tsp"],
  SPICE_ZAATAR:                ["Za'atar", SP, "tsp"],
  SPICE_SZECHUAN_PEPPERCORN:   ["Szechuan Peppercorn", SP, "tsp"],
  SPICE_FENUGREEK:             ["Fenugreek", SP, "tsp"],
  SPICE_MSG:                   ["MSG", SP, "tsp"],
  SPICE_CARAWAY:               ["Caraway Seed", SP, "tsp"],
  SPICE_ANISE_SEED:            ["Anise Seed", SP, "tsp"],
  SPICE_JUNIPER_BERRY:         ["Juniper Berry", SP, "tsp"],
  SPICE_CELERY_SEED:           ["Celery Seed", SP, "tsp"],
  SPICE_ONION_POWDER:          ["Onion Powder", SP, "tsp"],
  SPICE_GARLIC_POWDER:         ["Garlic Powder", SP, "tsp"],
  SPICE_GINGER_POWDER:         ["Ground Ginger", SP, "tsp"],
  SPICE_CHIPOTLE_POWDER:       ["Chipotle Powder", SP, "tsp"],
  SPICE_WASABI:                ["Wasabi", SP, "tsp"],
  SPICE_MACE:                  ["Mace", SP, "tsp"],
  SPICE_ASAFOETIDA:            ["Asafoetida", SP, "pinch"],
  SPICE_ACHIOTE:               ["Achiote", SP, "tsp"],
  SPICE_VANILLA_BEAN:          ["Vanilla Bean", SP, "piece"],
  SPICE_ITALIAN_SEASONING:     ["Italian Seasoning", SP, "tsp"],
  SPICE_HERBS_DE_PROVENCE:     ["Herbes de Provence", SP, "tsp"],
  SPICE_CAJUN_SEASONING:       ["Cajun Seasoning", SP, "tsp"],
  SPICE_TACO_SEASONING:        ["Taco Seasoning", SP, "tbsp"],
  SPICE_TOGARASHI:             ["Togarashi", SP, "tsp"],
  SPICE_DUKKAH:                ["Dukkah", SP, "tbsp"],
  SPICE_RAS_EL_HANOUT:         ["Ras el Hanout", SP, "tsp"],
  SPICE_OLD_BAY:               ["Old Bay Seasoning", SP, "tsp"],
  SPICE_BERBERE:               ["Berbere", SP, "tsp"],

  // ════════════════════════════════════════════════════════════
  // HERBS
  // ════════════════════════════════════════════════════════════

  HERB_BASIL:                  ["Basil", H, "cup"],
  HERB_THAI_BASIL:             ["Thai Basil", H, "cup"],
  HERB_CILANTRO:               ["Cilantro", H, "bunch"],
  HERB_PARSLEY:                ["Parsley", H, "bunch"],
  HERB_FLAT_LEAF_PARSLEY:      ["Flat-Leaf Parsley", H, "bunch"],
  HERB_MINT:                   ["Mint", H, "bunch"],
  HERB_ROSEMARY:               ["Rosemary", H, "sprig"],
  HERB_THYME:                  ["Thyme", H, "sprig"],
  HERB_OREGANO:                ["Oregano", H, "tsp"],
  HERB_DILL:                   ["Dill", H, "bunch"],
  HERB_CHIVE:                  ["Chive", H, "bunch"],
  HERB_SAGE:                   ["Sage", H, "leaf"],
  HERB_TARRAGON:               ["Tarragon", H, "sprig"],
  HERB_BAY_LEAF:               ["Bay Leaf", H, "leaf"],
  HERB_LEMONGRASS:             ["Lemongrass", H, "stalk"],
  HERB_CURRY_LEAF:             ["Curry Leaf", H, "sprig"],
  HERB_KAFFIR_LIME_LEAF:       ["Kaffir Lime Leaf", H, "leaf"],
  HERB_PANDAN_LEAF:            ["Pandan Leaf", H, "leaf"],
  HERB_MARJORAM:               ["Marjoram", H, "tsp"],
  HERB_LAVENDER:               ["Lavender", H, "tsp"],
  HERB_SHISO:                  ["Shiso", H, "leaf"],
  HERB_PERILLA:                ["Perilla Leaf", H, "leaf"],
  HERB_VIETNAMESE_CORIANDER:   ["Vietnamese Coriander", H, "bunch"],
  HERB_SAVORY:                 ["Savory", H, "tsp"],
  HERB_EPAZOTE:                ["Epazote", H, "sprig"],

  // ════════════════════════════════════════════════════════════
  // OILS & FATS
  // ════════════════════════════════════════════════════════════

  OIL_OLIVE:                   ["Olive Oil", O, "tbsp"],
  OIL_VEGETABLE:               ["Vegetable Oil", O, "tbsp"],
  OIL_CANOLA:                  ["Canola Oil", O, "tbsp"],
  OIL_SUNFLOWER:               ["Sunflower Oil", O, "tbsp"],
  OIL_PEANUT:                  ["Peanut Oil", O, "tbsp"],
  OIL_SESAME:                  ["Sesame Oil", O, "tsp"],
  OIL_COCONUT:                 ["Coconut Oil", O, "tbsp"],
  OIL_AVOCADO:                 ["Avocado Oil", O, "tbsp"],
  OIL_GRAPESEED:               ["Grapeseed Oil", O, "tbsp"],
  OIL_CHILI:                   ["Chili Oil", O, "tsp"],
  OIL_TRUFFLE:                 ["Truffle Oil", O, "tsp"],
  OIL_LARD:                    ["Lard", O, "tbsp"],
  OIL_SHORTENING:              ["Shortening", O, "cup"],

  // ════════════════════════════════════════════════════════════
  // VINEGARS
  // ════════════════════════════════════════════════════════════

  VINEGAR_WHITE:               ["White Vinegar", V, "tbsp"],
  VINEGAR_APPLE_CIDER:         ["Apple Cider Vinegar", V, "tbsp"],
  VINEGAR_RICE:                ["Rice Vinegar", V, "tbsp"],
  VINEGAR_BALSAMIC:            ["Balsamic Vinegar", V, "tbsp"],
  VINEGAR_RED_WINE:            ["Red Wine Vinegar", V, "tbsp"],
  VINEGAR_WHITE_WINE:          ["White Wine Vinegar", V, "tbsp"],
  VINEGAR_SHERRY:              ["Sherry Vinegar", V, "tbsp"],
  VINEGAR_MALT:                ["Malt Vinegar", V, "tbsp"],
  VINEGAR_BLACK:               ["Black Vinegar", V, "tbsp"],

  // ════════════════════════════════════════════════════════════
  // SAUCES & PASTES
  // ════════════════════════════════════════════════════════════

  SAUCE_SOY:                   ["Soy Sauce", SA, "tbsp"],
  SAUCE_LIGHT_SOY:             ["Light Soy Sauce", SA, "tbsp"],
  SAUCE_DARK_SOY:              ["Dark Soy Sauce", SA, "tbsp"],
  SAUCE_FISH:                  ["Fish Sauce", SA, "tbsp"],
  SAUCE_OYSTER:                ["Oyster Sauce", SA, "tbsp"],
  SAUCE_HOISIN:                ["Hoisin Sauce", SA, "tbsp"],
  SAUCE_TERIYAKI:              ["Teriyaki Sauce", SA, "tbsp"],
  SAUCE_WORCESTERSHIRE:        ["Worcestershire Sauce", SA, "tbsp"],
  SAUCE_HOT:                   ["Hot Sauce", SA, "tsp"],
  SAUCE_SRIRACHA:              ["Sriracha", SA, "tsp"],
  SAUCE_TABASCO:               ["Tabasco", SA, "dash"],
  SAUCE_SAMBAL_OELEK:          ["Sambal Oelek", SA, "tbsp"],
  SAUCE_SWEET_CHILI:           ["Sweet Chili Sauce", SA, "tbsp"],
  SAUCE_TOMATO:                ["Tomato Sauce", SA, "cup"],
  SAUCE_MARINARA:              ["Marinara Sauce", SA, "cup"],
  SAUCE_BBQ:                   ["BBQ Sauce", SA, "tbsp"],
  SAUCE_TAHINI:                ["Tahini", SA, "tbsp"],
  SAUCE_PESTO:                 ["Pesto", SA, "tbsp"],
  SAUCE_MIRIN:                 ["Mirin", SA, "tbsp"],
  SAUCE_SAKE:                  ["Cooking Sake", SA, "tbsp"],
  SAUCE_SHAOXING_WINE:         ["Shaoxing Wine", SA, "tbsp"],
  SAUCE_COCONUT_AMINOS:        ["Coconut Aminos", SA, "tbsp"],
  SAUCE_TAMARI:                ["Tamari", SA, "tbsp"],
  SAUCE_PONZU:                 ["Ponzu", SA, "tbsp"],
  SAUCE_GOCHUJANG:             ["Gochujang", SA, "tbsp"],
  SAUCE_DOENJANG:              ["Doenjang", SA, "tbsp"],
  SAUCE_MISO_WHITE:            ["White Miso", SA, "tbsp"],
  SAUCE_MISO_RED:              ["Red Miso", SA, "tbsp"],
  SAUCE_XO:                    ["XO Sauce", SA, "tbsp"],
  SAUCE_BLACK_BEAN:            ["Black Bean Sauce", SA, "tbsp"],
  SAUCE_PLUM:                  ["Plum Sauce", SA, "tbsp"],
  SAUCE_ENCHILADA:             ["Enchilada Sauce", SA, "cup"],
  SAUCE_CURRY_PASTE_RED:       ["Red Curry Paste", SA, "tbsp"],
  SAUCE_CURRY_PASTE_GREEN:     ["Green Curry Paste", SA, "tbsp"],
  SAUCE_CURRY_PASTE_YELLOW:    ["Yellow Curry Paste", SA, "tbsp"],
  SAUCE_TOM_YUM_PASTE:         ["Tom Yum Paste", SA, "tbsp"],
  SAUCE_CHILI_GARLIC:          ["Chili Garlic Sauce", SA, "tbsp"],
  SAUCE_SALSA:                 ["Salsa", SA, "cup"],

  // ════════════════════════════════════════════════════════════
  // CONDIMENTS
  // ════════════════════════════════════════════════════════════

  CONDIMENT_KETCHUP:           ["Ketchup", CO, "tbsp"],
  CONDIMENT_MUSTARD:           ["Mustard", CO, "tbsp"],
  CONDIMENT_DIJON_MUSTARD:     ["Dijon Mustard", CO, "tbsp"],
  CONDIMENT_YELLOW_MUSTARD:    ["Yellow Mustard", CO, "tbsp"],
  CONDIMENT_MAYONNAISE:        ["Mayonnaise", CO, "tbsp"],
  CONDIMENT_RELISH:            ["Relish", CO, "tbsp"],
  CONDIMENT_PICKLE:            ["Pickle", CO, "piece"],
  CONDIMENT_CAPER:             ["Caper", CO, "tbsp"],
  CONDIMENT_BLACK_OLIVE:       ["Black Olive", CO, "cup"],
  CONDIMENT_GREEN_OLIVE:       ["Green Olive", CO, "cup"],
  CONDIMENT_KIMCHI:            ["Kimchi", CO, "cup"],
  CONDIMENT_SAUERKRAUT:        ["Sauerkraut", CO, "cup"],
  CONDIMENT_HARISSA:           ["Harissa", CO, "tbsp"],
  CONDIMENT_TOMATO_PASTE:      ["Tomato Paste", CO, "tbsp"],
  CONDIMENT_TOMATO_PUREE:      ["Tomato Purée", CO, "cup"],
  CONDIMENT_SUN_DRIED_TOMATO:  ["Sun-Dried Tomato", CO, "cup"],
  CONDIMENT_MANGO_CHUTNEY:     ["Mango Chutney", CO, "tbsp"],
  CONDIMENT_CHILI_PASTE:       ["Chili Paste", CO, "tbsp"],
  CONDIMENT_GARLIC_PASTE:      ["Garlic Paste", CO, "tbsp"],
  CONDIMENT_GINGER_PASTE:      ["Ginger Paste", CO, "tbsp"],
  CONDIMENT_ANCHOVY_PASTE:     ["Anchovy Paste", CO, "tsp"],

  // ════════════════════════════════════════════════════════════
  // BAKING
  // ════════════════════════════════════════════════════════════

  // Flours
  BAKING_ALL_PURPOSE_FLOUR:    ["All-Purpose Flour", B, "cup"],
  BAKING_BREAD_FLOUR:          ["Bread Flour", B, "cup"],
  BAKING_CAKE_FLOUR:           ["Cake Flour", B, "cup"],
  BAKING_WHOLE_WHEAT_FLOUR:    ["Whole Wheat Flour", B, "cup"],
  BAKING_SELF_RISING_FLOUR:    ["Self-Rising Flour", B, "cup"],
  BAKING_RICE_FLOUR:           ["Rice Flour", B, "cup"],
  BAKING_GLUTINOUS_RICE_FLOUR: ["Glutinous Rice Flour", B, "cup"],
  BAKING_ALMOND_FLOUR:         ["Almond Flour", B, "cup"],
  BAKING_COCONUT_FLOUR:        ["Coconut Flour", B, "cup"],
  BAKING_CHICKPEA_FLOUR:       ["Chickpea Flour", B, "cup"],

  // Starches
  BAKING_CORN_STARCH:          ["Corn Starch", B, "tbsp"],
  BAKING_TAPIOCA_STARCH:       ["Tapioca Starch", B, "tbsp"],
  BAKING_POTATO_STARCH:        ["Potato Starch", B, "tbsp"],
  BAKING_ARROWROOT:            ["Arrowroot Powder", B, "tbsp"],

  // Sweeteners
  BAKING_SUGAR:                ["Sugar", B, "cup"],
  BAKING_BROWN_SUGAR:          ["Brown Sugar", B, "cup"],
  BAKING_POWDERED_SUGAR:       ["Powdered Sugar", B, "cup"],
  BAKING_COCONUT_SUGAR:        ["Coconut Sugar", B, "cup"],
  BAKING_PALM_SUGAR:           ["Palm Sugar", B, "tbsp"],
  BAKING_HONEY:                ["Honey", B, "tbsp"],
  BAKING_MAPLE_SYRUP:          ["Maple Syrup", B, "tbsp"],
  BAKING_MOLASSES:             ["Molasses", B, "tbsp"],
  BAKING_AGAVE:                ["Agave Nectar", B, "tbsp"],
  BAKING_CORN_SYRUP:           ["Corn Syrup", B, "tbsp"],

  // Leavening & Thickening
  BAKING_BAKING_POWDER:        ["Baking Powder", B, "tsp"],
  BAKING_BAKING_SODA:          ["Baking Soda", B, "tsp"],
  BAKING_YEAST:                ["Yeast", B, "tsp"],
  BAKING_CREAM_OF_TARTAR:      ["Cream of Tartar", B, "tsp"],
  BAKING_GELATIN:              ["Gelatin", B, "packet"],
  BAKING_AGAR_AGAR:            ["Agar Agar", B, "tsp"],

  // Extracts & Flavorings
  BAKING_VANILLA_EXTRACT:      ["Vanilla Extract", B, "tsp"],
  BAKING_ALMOND_EXTRACT:       ["Almond Extract", B, "tsp"],
  BAKING_PANDAN_EXTRACT:       ["Pandan Extract", B, "tsp"],
  BAKING_ROSE_WATER:           ["Rose Water", B, "tsp"],
  BAKING_ORANGE_BLOSSOM_WATER: ["Orange Blossom Water", B, "tsp"],

  // Chocolate & Cocoa
  BAKING_COCOA_POWDER:         ["Cocoa Powder", B, "tbsp"],
  BAKING_DARK_CHOCOLATE:       ["Dark Chocolate", B, "oz"],
  BAKING_MILK_CHOCOLATE:       ["Milk Chocolate", B, "oz"],
  BAKING_WHITE_CHOCOLATE:      ["White Chocolate", B, "oz"],
  BAKING_CHOCOLATE_CHIPS:      ["Chocolate Chips", B, "cup"],
  BAKING_COCONUT_FLAKES:       ["Coconut Flakes", B, "cup"],

  // ════════════════════════════════════════════════════════════
  // NUTS & SEEDS
  // ════════════════════════════════════════════════════════════

  NUT_ALMOND:                  ["Almond", N, "cup"],
  NUT_WALNUT:                  ["Walnut", N, "cup"],
  NUT_CASHEW:                  ["Cashew", N, "cup"],
  NUT_PISTACHIO:               ["Pistachio", N, "cup"],
  NUT_PECAN:                   ["Pecan", N, "cup"],
  NUT_MACADAMIA:               ["Macadamia Nut", N, "cup"],
  NUT_HAZELNUT:                ["Hazelnut", N, "cup"],
  NUT_PINE_NUT:                ["Pine Nut", N, "tbsp"],
  NUT_CHESTNUT:                ["Chestnut", N, "cup"],
  NUT_BRAZIL_NUT:              ["Brazil Nut", N, "cup"],
  NUT_PEANUT:                  ["Peanut", N, "cup"],
  NUT_SUNFLOWER_SEED:          ["Sunflower Seed", N, "tbsp"],
  NUT_PUMPKIN_SEED:            ["Pumpkin Seed", N, "tbsp"],
  NUT_SESAME_SEED:             ["Sesame Seed", N, "tbsp"],
  NUT_BLACK_SESAME_SEED:       ["Black Sesame Seed", N, "tbsp"],
  NUT_FLAX_SEED:               ["Flax Seed", N, "tbsp"],
  NUT_CHIA_SEED:               ["Chia Seed", N, "tbsp"],
  NUT_HEMP_SEED:               ["Hemp Seed", N, "tbsp"],
  NUT_POPPY_SEED:              ["Poppy Seed", N, "tsp"],
  NUT_COCONUT_SHREDDED:        ["Shredded Coconut", N, "cup"],

  // ════════════════════════════════════════════════════════════
  // BEVERAGES & LIQUIDS
  // ════════════════════════════════════════════════════════════

  BEVERAGE_WATER:              ["Water", BV, "cup"],
  BEVERAGE_ICE:                ["Ice", BV, "cup"],
  BEVERAGE_COFFEE:             ["Coffee", BV, "cup"],
  BEVERAGE_TEA:                ["Tea", BV, "cup"],
  BEVERAGE_GREEN_TEA:          ["Green Tea", BV, "cup"],
  BEVERAGE_MATCHA:             ["Matcha", BV, "tsp"],
  BEVERAGE_RED_WINE:           ["Red Wine", BV, "cup"],
  BEVERAGE_WHITE_WINE:         ["White Wine", BV, "cup"],
  BEVERAGE_BEER:               ["Beer", BV, "cup"],
  BEVERAGE_CHICKEN_BROTH:      ["Chicken Broth", BV, "cup"],
  BEVERAGE_BEEF_BROTH:         ["Beef Broth", BV, "cup"],
  BEVERAGE_VEGETABLE_BROTH:    ["Vegetable Broth", BV, "cup"],
  BEVERAGE_DASHI:              ["Dashi", BV, "cup"],
  BEVERAGE_COCONUT_WATER:      ["Coconut Water", BV, "cup"],
  BEVERAGE_RICE_WINE:          ["Rice Wine", BV, "tbsp"],

  // ════════════════════════════════════════════════════════════
  // MISCELLANEOUS
  // ════════════════════════════════════════════════════════════

  MISC_TOFU:                   ["Tofu", MI, "oz"],
  MISC_SILKEN_TOFU:            ["Silken Tofu", MI, "oz"],
  MISC_FIRM_TOFU:              ["Firm Tofu", MI, "oz"],
  MISC_EXTRA_FIRM_TOFU:        ["Extra-Firm Tofu", MI, "oz"],
  MISC_TEMPEH:                 ["Tempeh", MI, "oz"],
  MISC_SEITAN:                 ["Seitan", MI, "oz"],
  MISC_NORI:                   ["Nori", MI, "sheet"],
  MISC_KOMBU:                  ["Kombu", MI, "piece"],
  MISC_WAKAME:                 ["Wakame", MI, "tbsp"],
  MISC_DRIED_SEAWEED:          ["Dried Seaweed", MI, "sheet"],
  MISC_BONITO_FLAKES:          ["Bonito Flakes", MI, "cup"],
  MISC_TAMARIND_PASTE:         ["Tamarind Paste", MI, "tbsp"],
  MISC_NUTRITIONAL_YEAST:      ["Nutritional Yeast", MI, "tbsp"],
  MISC_LIQUID_SMOKE:           ["Liquid Smoke", MI, "tsp"],
  MISC_BELACAN:                ["Belacan", MI, "tsp"],
  MISC_PEANUT_BUTTER:          ["Peanut Butter", MI, "tbsp"],
  MISC_ALMOND_BUTTER:          ["Almond Butter", MI, "tbsp"],
  MISC_TAHINI_PASTE:           ["Tahini Paste", MI, "tbsp"],
  MISC_BANANA_LEAF:            ["Banana Leaf", MI, "piece"],

  // ════════════════════════════════════════════════════════════
  // EXPANSION — Asian Cuisine Focus + Global Coverage
  // ════════════════════════════════════════════════════════════

  // ── PRODUCE: Asian Greens & Vegetables ─────────────────────
  PRODUCE_GARLIC_CHIVES:       ["Garlic Chives", P, "bunch"],
  PRODUCE_CHOY_SUM:            ["Choy Sum", P, "bunch"],
  PRODUCE_YU_CHOY:             ["Yu Choy", P, "bunch"],
  PRODUCE_TATSOI:              ["Tatsoi", P, "bunch"],
  PRODUCE_CHRYSANTHEMUM_GREENS:["Chrysanthemum Greens", P, "bunch"],
  PRODUCE_PEA_SHOOT:           ["Pea Shoots", P, "cup"],
  PRODUCE_CHINESE_SPINACH:     ["Chinese Spinach", P, "bunch"],
  PRODUCE_SAVOY_CABBAGE:       ["Savoy Cabbage", P, "head"],
  PRODUCE_ROMANESCO:           ["Romanesco", P, "head"],
  PRODUCE_TURNIP_GREENS:       ["Turnip Greens", P, "bunch"],
  PRODUCE_RADISH_GREENS:       ["Radish Greens", P, "bunch"],
  PRODUCE_BEET_GREENS:         ["Beet Greens", P, "bunch"],
  PRODUCE_CELERY_LEAF:         ["Celery Leaf", P, "bunch"],
  PRODUCE_MICROGREENS:         ["Microgreens", P, "cup"],

  // ── PRODUCE: Asian Roots & Tubers ──────────────────────────
  PRODUCE_BURDOCK_ROOT:        ["Burdock Root", P, "piece"],
  PRODUCE_CHINESE_YAM:         ["Chinese Yam", P, "piece"],
  PRODUCE_PURPLE_YAM:          ["Purple Yam", P, "piece"],
  PRODUCE_KOREAN_RADISH:       ["Korean Radish", P, "piece"],
  PRODUCE_JERUSALEM_ARTICHOKE: ["Jerusalem Artichoke", P, "piece"],
  PRODUCE_LOTUS_STEM:          ["Lotus Stem", P, "piece"],
  PRODUCE_BANANA_STEM:         ["Banana Stem", P, "piece"],

  // ── PRODUCE: Asian Alliums ─────────────────────────────────
  PRODUCE_NEGI:                ["Negi", P, "stalk"],
  PRODUCE_MYOGA:               ["Myoga Ginger", P, "piece"],
  PRODUCE_RAMP:                ["Ramp", P, "bunch"],

  // ── PRODUCE: Peppers (Asian & Latin) ───────────────────────
  PRODUCE_SHISHITO:            ["Shishito Pepper", P, "piece"],
  PRODUCE_DRIED_CHILI:         ["Dried Chili", P, "piece"],
  PRODUCE_BANANA_PEPPER:       ["Banana Pepper", P, "piece"],
  PRODUCE_FRESNO_PEPPER:       ["Fresno Pepper", P, "piece"],

  // ── PRODUCE: Mushrooms (Asian) ─────────────────────────────
  PRODUCE_DRIED_SHIITAKE:      ["Dried Shiitake", P, "piece"],
  PRODUCE_SHIMEJI:             ["Shimeji Mushroom", P, "package"],
  PRODUCE_NAMEKO:              ["Nameko Mushroom", P, "package"],
  PRODUCE_MATSUTAKE:           ["Matsutake Mushroom", P, "piece"],
  PRODUCE_SNOW_FUNGUS:         ["Snow Fungus", P, "piece"],
  PRODUCE_STRAW_MUSHROOM:      ["Straw Mushroom", P, "can"],
  PRODUCE_DRIED_LILY_BUD:      ["Dried Lily Bud", P, "cup"],
  PRODUCE_MOREL:               ["Morel Mushroom", P, "cup"],
  PRODUCE_PORCINI:             ["Porcini Mushroom", P, "oz"],
  PRODUCE_TRUFFLE:             ["Truffle", P, "piece"],

  // ── PRODUCE: Gourds & Beans (Asian) ────────────────────────
  PRODUCE_WINGED_BEAN:         ["Winged Bean", P, "cup"],
  PRODUCE_RIDGE_GOURD:         ["Ridge Gourd", P, "piece"],
  PRODUCE_BOTTLE_GOURD:        ["Bottle Gourd", P, "piece"],
  PRODUCE_IVY_GOURD:           ["Ivy Gourd", P, "cup"],
  PRODUCE_SNAKE_GOURD:         ["Snake Gourd", P, "piece"],
  PRODUCE_POINTED_GOURD:       ["Pointed Gourd", P, "piece"],
  PRODUCE_CLUSTER_BEAN:        ["Cluster Bean", P, "cup"],
  PRODUCE_DRUMSTICK_VEGETABLE: ["Drumstick", P, "piece"],
  PRODUCE_PENNYWORT:           ["Pennywort", P, "bunch"],
  PRODUCE_GREEN_PAPAYA:        ["Green Papaya", P, "piece"],
  PRODUCE_WATER_DROPWORT:      ["Water Dropwort", P, "bunch"],
  PRODUCE_FIDDLEHEAD_FERN:     ["Fiddlehead Fern", P, "cup"],
  PRODUCE_MORINGA_LEAF:        ["Moringa Leaf", P, "cup"],
  PRODUCE_TOMATILLO:           ["Tomatillo", P, "piece"],
  PRODUCE_NOPAL:               ["Nopal Cactus", P, "piece"],

  // ── PRODUCE: Asian & Tropical Fruits ───────────────────────
  PRODUCE_RAMBUTAN:            ["Rambutan", P, "piece"],
  PRODUCE_MANGOSTEEN:          ["Mangosteen", P, "piece"],
  PRODUCE_LONGAN:              ["Longan", P, "piece"],
  PRODUCE_SOURSOP:             ["Soursop", P, "piece"],
  PRODUCE_BREADFRUIT:          ["Breadfruit", P, "piece"],
  PRODUCE_JUJUBE:              ["Jujube", P, "piece"],
  PRODUCE_GOJI_BERRY:          ["Goji Berry", P, "tbsp"],
  PRODUCE_ASIAN_PEAR:          ["Asian Pear", P, "piece"],
  PRODUCE_SAPODILLA:           ["Sapodilla", P, "piece"],
  PRODUCE_CUSTARD_APPLE:       ["Custard Apple", P, "piece"],
  PRODUCE_SUGARCANE:           ["Sugarcane", P, "stalk"],

  // ── MEAT: Offal & Asian Cuts ───────────────────────────────
  MEAT_BEEF_FLANK:             ["Flank Steak", M, "lb"],
  MEAT_BEEF_SHANK:             ["Beef Shank", M, "lb"],
  MEAT_OXTAIL:                 ["Oxtail", M, "lb"],
  MEAT_BEEF_TONGUE:            ["Beef Tongue", M, "lb"],
  MEAT_BEEF_RIB:               ["Beef Rib", M, "lb"],
  MEAT_TRIPE:                  ["Tripe", M, "lb"],
  MEAT_PORK_LIVER:             ["Pork Liver", M, "lb"],
  MEAT_PORK_HOCK:              ["Pork Hock", M, "piece"],
  MEAT_PORK_EAR:               ["Pork Ear", M, "piece"],
  MEAT_CHINESE_SAUSAGE:        ["Chinese Sausage", M, "piece"],
  MEAT_CURED_PORK_BELLY:       ["Cured Pork Belly", M, "oz"],
  MEAT_BLOOD_SAUSAGE:          ["Blood Sausage", M, "piece"],
  MEAT_GROUND_VEAL:            ["Ground Veal", M, "lb"],
  MEAT_HOTDOG:                 ["Hot Dog", M, "piece"],
  MEAT_ANDOUILLE:              ["Andouille Sausage", M, "piece"],
  MEAT_KIELBASA:               ["Kielbasa", M, "piece"],
  MEAT_MORTADELLA:             ["Mortadella", M, "slice"],
  MEAT_PEPPERONI:              ["Pepperoni", M, "slice"],
  MEAT_BRESAOLA:               ["Bresaola", M, "slice"],

  // ── POULTRY: Asian Cuts ────────────────────────────────────
  POULTRY_CHICKEN_FEET:        ["Chicken Feet", PO, "lb"],
  POULTRY_CHICKEN_GIZZARD:     ["Chicken Gizzard", PO, "lb"],
  POULTRY_CHICKEN_HEART:       ["Chicken Heart", PO, "lb"],
  POULTRY_DUCK_LEG:            ["Duck Leg", PO, "piece"],
  POULTRY_TURKEY_BREAST:       ["Turkey Breast", PO, "lb"],
  POULTRY_CHICKEN_SKIN:        ["Chicken Skin", PO, "oz"],
  POULTRY_CHICKEN_LEG_QUARTER: ["Chicken Leg Quarter", PO, "piece"],
  POULTRY_DUCK_CONFIT:         ["Duck Confit", PO, "piece"],

  // ── SEAFOOD: Japanese Fish ─────────────────────────────────
  SEAFOOD_EEL:                 ["Eel", SF, "piece"],
  SEAFOOD_CONGER_EEL:          ["Conger Eel", SF, "piece"],
  SEAFOOD_SEA_BREAM:           ["Sea Bream", SF, "piece"],
  SEAFOOD_YELLOWTAIL:          ["Yellowtail", SF, "piece"],
  SEAFOOD_WHITEBAIT:           ["Whitebait", SF, "cup"],
  SEAFOOD_TOBIKO:              ["Tobiko", SF, "tbsp"],
  SEAFOOD_SALMON_ROE:          ["Salmon Roe", SF, "tbsp"],
  SEAFOOD_MENTAIKO:            ["Mentaiko", SF, "piece"],
  SEAFOOD_SKIPJACK_TUNA:       ["Skipjack Tuna", SF, "piece"],
  SEAFOOD_BONITO:              ["Bonito", SF, "piece"],

  // ── SEAFOOD: Chinese / Korean / SE Asian ───────────────────
  SEAFOOD_DRIED_SCALLOP:       ["Dried Scallop", SF, "piece"],
  SEAFOOD_SEA_CUCUMBER:        ["Sea Cucumber", SF, "piece"],
  SEAFOOD_JELLYFISH:           ["Jellyfish", SF, "oz"],
  SEAFOOD_FISH_MAW:            ["Fish Maw", SF, "piece"],
  SEAFOOD_DRIED_SQUID:         ["Dried Squid", SF, "piece"],
  SEAFOOD_RAZOR_CLAM:          ["Razor Clam", SF, "piece"],
  SEAFOOD_COCKLE:              ["Cockle", SF, "cup"],
  SEAFOOD_MANTIS_SHRIMP:       ["Mantis Shrimp", SF, "piece"],
  SEAFOOD_WHELK:               ["Whelk", SF, "piece"],

  // ── SEAFOOD: Additional Global ─────────────────────────────
  SEAFOOD_TURBOT:              ["Turbot", SF, "piece"],
  SEAFOOD_MONKFISH:            ["Monkfish", SF, "piece"],
  SEAFOOD_PERCH:               ["Perch", SF, "piece"],
  SEAFOOD_SMELT:               ["Smelt", SF, "piece"],
  SEAFOOD_BASA:                ["Basa", SF, "piece"],
  SEAFOOD_GEODUCK:             ["Geoduck", SF, "piece"],
  SEAFOOD_SNOW_CRAB:           ["Snow Crab", SF, "lb"],
  SEAFOOD_KING_CRAB:           ["King Crab", SF, "lb"],
  SEAFOOD_SOFT_SHELL_CRAB:     ["Soft-Shell Crab", SF, "piece"],
  SEAFOOD_LANGOUSTINE:         ["Langoustine", SF, "piece"],
  SEAFOOD_SKATE:               ["Skate", SF, "piece"],

  // ── DAIRY: Asian Eggs & Global Cheese ──────────────────────
  DAIRY_CENTURY_EGG:           ["Century Egg", D, "piece"],
  DAIRY_SALTED_EGG:            ["Salted Egg", D, "piece"],
  DAIRY_COCONUT_YOGURT:        ["Coconut Yogurt", D, "cup"],
  DAIRY_LABNEH:                ["Labneh", D, "cup"],
  DAIRY_CLOTTED_CREAM:         ["Clotted Cream", D, "tbsp"],
  DAIRY_PROVOLONE:             ["Provolone", D, "slice"],
  DAIRY_HAVARTI:               ["Havarti", D, "slice"],
  DAIRY_HALLOUMI:              ["Halloumi", D, "oz"],
  DAIRY_BURRATA:               ["Burrata", D, "piece"],
  DAIRY_CAMEMBERT:             ["Camembert", D, "oz"],
  DAIRY_MANCHEGO:              ["Manchego", D, "oz"],
  DAIRY_QUESO_FRESCO:          ["Queso Fresco", D, "cup"],
  DAIRY_CREME_FRAICHE:         ["Crème Fraîche", D, "tbsp"],
  DAIRY_KEFIR:                 ["Kefir", D, "cup"],
  DAIRY_FROMAGE_BLANC:         ["Fromage Blanc", D, "cup"],

  // ── GRAINS: Asian Noodles ──────────────────────────────────
  GRAIN_SOMEN:                 ["Somen Noodle", G, "oz"],
  GRAIN_SHIRATAKI:             ["Shirataki Noodle", G, "package"],
  GRAIN_SWEET_POTATO_NOODLE:   ["Sweet Potato Noodle", G, "oz"],
  GRAIN_NAENGMYEON:            ["Naengmyeon Noodle", G, "oz"],
  GRAIN_MISUA:                 ["Misua", G, "oz"],
  GRAIN_LAKSA_NOODLE:          ["Laksa Noodle", G, "oz"],
  GRAIN_FLAT_WHEAT_NOODLE:     ["Flat Wheat Noodle", G, "oz"],
  GRAIN_KALGUKSU:              ["Kalguksu Noodle", G, "oz"],
  GRAIN_INSTANT_NOODLE:        ["Instant Noodle", G, "package"],
  GRAIN_RICE_CAKE_SHEET:       ["Fresh Rice Noodle Sheet", G, "sheet"],

  // ── GRAINS: Asian Rice Products ────────────────────────────
  GRAIN_MOCHI:                 ["Mochi", G, "piece"],
  GRAIN_TTEOK:                 ["Tteok", G, "cup"],
  GRAIN_BLACK_RICE:            ["Black Rice", G, "cup"],
  GRAIN_RED_RICE:              ["Red Rice", G, "cup"],

  // ── GRAINS: Bread & Dough (Asian & Global) ─────────────────
  GRAIN_PUFF_PASTRY:           ["Puff Pastry", G, "sheet"],
  GRAIN_ROTI:                  ["Roti", G, "piece"],
  GRAIN_MANTOU:                ["Mantou", G, "piece"],
  GRAIN_BAO_BUN:               ["Bao Bun", G, "piece"],
  GRAIN_CHAPATI:               ["Chapati", G, "piece"],
  GRAIN_PARATHA:               ["Paratha", G, "piece"],
  GRAIN_LAVASH:                ["Lavash", G, "piece"],
  GRAIN_PAPPADAM:              ["Papadum", G, "piece"],
  GRAIN_INJERA:                ["Injera", G, "piece"],
  GRAIN_PRAWN_CRACKER:         ["Prawn Cracker", G, "piece"],
  GRAIN_CORN_TORTILLA:         ["Corn Tortilla", G, "piece"],
  GRAIN_TACO_SHELL:            ["Taco Shell", G, "piece"],
  GRAIN_IDLI:                  ["Idli", G, "piece"],
  GRAIN_DOSA:                  ["Dosa", G, "piece"],
  GRAIN_CROISSANT:             ["Croissant", G, "piece"],
  GRAIN_BRIOCHE:               ["Brioche", G, "piece"],
  GRAIN_ENGLISH_MUFFIN:        ["English Muffin", G, "piece"],
  GRAIN_BAGEL:                 ["Bagel", G, "piece"],

  // ── GRAINS: Other ──────────────────────────────────────────
  GRAIN_AMARANTH:              ["Amaranth", G, "cup"],
  GRAIN_TEFF:                  ["Teff", G, "cup"],

  // ── LEGUMES: South & East Asian ────────────────────────────
  LEGUME_URAD_DAL:             ["Urad Dal", L, "cup"],
  LEGUME_TOOR_DAL:             ["Toor Dal", L, "cup"],
  LEGUME_CHANA_DAL:            ["Chana Dal", L, "cup"],
  LEGUME_PIGEON_PEA:           ["Pigeon Pea", L, "cup"],
  LEGUME_RED_BEAN_PASTE:       ["Red Bean Paste", L, "tbsp"],
  LEGUME_YELLOW_LENTIL:        ["Yellow Lentil", L, "cup"],
  LEGUME_BLACK_LENTIL:         ["Black Lentil", L, "cup"],
  LEGUME_DAL:                  ["Dal", L, "cup"],

  // ── SPICES: Korean ─────────────────────────────────────────
  SPICE_GOCHUGARU:             ["Gochugaru", SP, "tbsp"],
  SPICE_KOREAN_CHILI_POWDER:   ["Korean Chili Powder", SP, "tbsp"],

  // ── SPICES: Japanese ───────────────────────────────────────
  SPICE_SANSHO:                ["Sansho Pepper", SP, "tsp"],
  SPICE_FURIKAKE:              ["Furikake", SP, "tbsp"],
  SPICE_DASHI_POWDER:          ["Dashi Powder", SP, "tsp"],

  // ── SPICES: Chinese ────────────────────────────────────────
  SPICE_DRIED_TANGERINE_PEEL:  ["Dried Tangerine Peel", SP, "piece"],
  SPICE_DRIED_RED_CHILI:       ["Dried Red Chili", SP, "piece"],
  SPICE_BLACK_CARDAMOM:        ["Black Cardamom", SP, "piece"],
  SPICE_LONG_PEPPER:           ["Long Pepper", SP, "tsp"],

  // ── SPICES: Southeast Asian ────────────────────────────────
  SPICE_GALANGAL_POWDER:       ["Galangal Powder", SP, "tsp"],
  SPICE_LEMONGRASS_POWDER:     ["Lemongrass Powder", SP, "tsp"],
  SPICE_TOASTED_RICE_POWDER:   ["Toasted Rice Powder", SP, "tbsp"],
  SPICE_CANDLENUT:             ["Candlenut", SP, "piece"],
  SPICE_KENCUR:                ["Kencur", SP, "piece"],
  SPICE_PANDAN_POWDER:         ["Pandan Powder", SP, "tsp"],
  SPICE_DRIED_SHRIMP_POWDER:   ["Dried Shrimp Powder", SP, "tbsp"],

  // ── SPICES: South Asian ────────────────────────────────────
  SPICE_NIGELLA_SEED:          ["Nigella Seed", SP, "tsp"],
  SPICE_AJWAIN:                ["Ajwain", SP, "tsp"],
  SPICE_AMCHUR:                ["Amchur", SP, "tsp"],
  SPICE_CHAT_MASALA:           ["Chaat Masala", SP, "tsp"],
  SPICE_TAMARIND_POWDER:       ["Tamarind Powder", SP, "tsp"],

  // ── SPICES: Global ─────────────────────────────────────────
  SPICE_GRAINS_OF_PARADISE:    ["Grains of Paradise", SP, "tsp"],
  SPICE_PINK_PEPPER:           ["Pink Pepper", SP, "tsp"],
  SPICE_DRIED_BASIL:           ["Dried Basil", SP, "tsp"],
  SPICE_DRIED_THYME:           ["Dried Thyme", SP, "tsp"],
  SPICE_DRIED_ROSEMARY:        ["Dried Rosemary", SP, "tsp"],
  SPICE_DRIED_PARSLEY:         ["Dried Parsley", SP, "tsp"],
  SPICE_CHILI_DE_ARBOL:        ["Chile de Árbol", SP, "piece"],
  SPICE_ANCHO_CHILI:           ["Ancho Chili", SP, "piece"],
  SPICE_GUAJILLO_CHILI:        ["Guajillo Chili", SP, "piece"],
  SPICE_PASILLA_CHILI:         ["Pasilla Chili", SP, "piece"],

  // ── HERBS: Asian ───────────────────────────────────────────
  HERB_HOLY_BASIL:             ["Holy Basil", H, "cup"],
  HERB_LEMON_BASIL:            ["Lemon Basil", H, "cup"],
  HERB_SAWTOOTH_CORIANDER:     ["Sawtooth Coriander", H, "bunch"],
  HERB_BETEL_LEAF:             ["Betel Leaf", H, "leaf"],
  HERB_MITSUBA:                ["Mitsuba", H, "bunch"],
  HERB_KINOME:                 ["Kinome", H, "sprig"],
  HERB_RICE_PADDY_HERB:        ["Rice Paddy Herb", H, "bunch"],
  HERB_VIETNAMESE_BALM:        ["Vietnamese Balm", H, "bunch"],
  HERB_INDONESIAN_BAY_LEAF:    ["Indonesian Bay Leaf", H, "leaf"],
  HERB_TURMERIC_LEAF:          ["Turmeric Leaf", H, "leaf"],
  HERB_MUGWORT:                ["Mugwort", H, "bunch"],

  // ── HERBS: Global ──────────────────────────────────────────
  HERB_CHERVIL:                ["Chervil", H, "bunch"],
  HERB_SORREL:                 ["Sorrel", H, "bunch"],
  HERB_LEMON_VERBENA:          ["Lemon Verbena", H, "sprig"],

  // ── OILS: Asian ────────────────────────────────────────────
  OIL_PERILLA:                 ["Perilla Oil", O, "tsp"],
  OIL_RICE_BRAN:               ["Rice Bran Oil", O, "tbsp"],
  OIL_SICHUAN_PEPPERCORN:      ["Sichuan Peppercorn Oil", O, "tsp"],
  OIL_SCALLION:                ["Scallion Oil", O, "tbsp"],
  OIL_GARLIC:                  ["Garlic Oil", O, "tbsp"],
  OIL_CORN:                    ["Corn Oil", O, "tbsp"],
  OIL_SAFFLOWER:               ["Safflower Oil", O, "tbsp"],

  // ── VINEGARS ───────────────────────────────────────────────
  VINEGAR_COCONUT:             ["Coconut Vinegar", V, "tbsp"],
  VINEGAR_SUSHI:               ["Sushi Vinegar", V, "tbsp"],
  VINEGAR_PALM:                ["Palm Vinegar", V, "tbsp"],

  // ── SAUCES: Chinese ────────────────────────────────────────
  SAUCE_DOUBANJIANG:           ["Doubanjiang", SA, "tbsp"],
  SAUCE_TIAN_MIAN_JIANG:      ["Sweet Bean Sauce", SA, "tbsp"],
  SAUCE_CHAR_SIU:              ["Char Siu Sauce", SA, "tbsp"],
  SAUCE_SHA_CHA:               ["Sha Cha Sauce", SA, "tbsp"],
  SAUCE_CHU_HOU_PASTE:         ["Chu Hou Paste", SA, "tbsp"],
  SAUCE_FERMENTED_BEAN_CURD:   ["Fermented Bean Curd", SA, "piece"],
  SAUCE_CHILI_CRISP:           ["Chili Crisp", SA, "tbsp"],
  SAUCE_YELLOW_BEAN_SAUCE:     ["Yellow Bean Sauce", SA, "tbsp"],
  SAUCE_SCALLION_OIL:          ["Scallion Oil Sauce", SA, "tbsp"],

  // ── SAUCES: Japanese ───────────────────────────────────────
  SAUCE_KECAP_MANIS:           ["Kecap Manis", SA, "tbsp"],
  SAUCE_YUZU_KOSHO:            ["Yuzu Kosho", SA, "tsp"],
  SAUCE_TONKATSU_SAUCE:        ["Tonkatsu Sauce", SA, "tbsp"],
  SAUCE_OKONOMIYAKI_SAUCE:     ["Okonomiyaki Sauce", SA, "tbsp"],
  SAUCE_MENTSUYU:              ["Mentsuyu", SA, "tbsp"],
  SAUCE_UNAGI_SAUCE:           ["Unagi Sauce", SA, "tbsp"],
  SAUCE_JAPANESE_CURRY_ROUX:   ["Japanese Curry Roux", SA, "piece"],
  SAUCE_TARE:                  ["Tare", SA, "tbsp"],

  // ── SAUCES: Korean ─────────────────────────────────────────
  SAUCE_SSAMJANG:              ["Ssamjang", SA, "tbsp"],
  SAUCE_CHOGOCHUJANG:          ["Chogochujang", SA, "tbsp"],
  SAUCE_KOREAN_BBQ_SAUCE:      ["Korean BBQ Sauce", SA, "tbsp"],

  // ── SAUCES: Thai / Vietnamese / SE Asian ───────────────────
  SAUCE_NUOC_CHAM:             ["Nuoc Cham", SA, "tbsp"],
  SAUCE_NAM_JIM:               ["Nam Jim", SA, "tbsp"],
  SAUCE_PRIK_NAM_PLA:          ["Prik Nam Pla", SA, "tbsp"],
  SAUCE_THAI_CHILI_JAM:        ["Thai Chili Jam", SA, "tbsp"],
  SAUCE_LAKSA_PASTE:           ["Laksa Paste", SA, "tbsp"],
  SAUCE_RENDANG_PASTE:         ["Rendang Paste", SA, "tbsp"],
  SAUCE_SATAY_SAUCE:           ["Satay Sauce", SA, "tbsp"],
  SAUCE_MASSAMAN_PASTE:        ["Massaman Curry Paste", SA, "tbsp"],
  SAUCE_PANANG_PASTE:          ["Panang Curry Paste", SA, "tbsp"],
  SAUCE_PAD_THAI_SAUCE:        ["Pad Thai Sauce", SA, "tbsp"],
  SAUCE_NAM_PRIK:              ["Nam Prik", SA, "tbsp"],

  // ── SAUCES: Global ─────────────────────────────────────────
  SAUCE_SOFRITO:               ["Sofrito", SA, "tbsp"],
  SAUCE_ALFREDO:               ["Alfredo Sauce", SA, "cup"],
  SAUCE_ADOBO_SAUCE:           ["Adobo Sauce", SA, "tbsp"],
  SAUCE_GRAVY:                 ["Gravy", SA, "cup"],
  SAUCE_CRANBERRY_SAUCE:       ["Cranberry Sauce", SA, "cup"],
  SAUCE_APPLE_SAUCE:           ["Apple Sauce", SA, "cup"],
  SAUCE_MINT_SAUCE:            ["Mint Sauce", SA, "tbsp"],
  SAUCE_GREEN_SAUCE:           ["Green Sauce", SA, "tbsp"],

  // ── CONDIMENTS: Japanese ───────────────────────────────────
  CONDIMENT_PICKLED_GINGER:    ["Pickled Ginger", CO, "tbsp"],
  CONDIMENT_UMEBOSHI:          ["Umeboshi", CO, "piece"],
  CONDIMENT_FUKUJINZUKE:       ["Fukujinzuke", CO, "tbsp"],
  CONDIMENT_TAKUAN:            ["Takuan", CO, "slice"],
  CONDIMENT_BENI_SHOGA:        ["Beni Shoga", CO, "tbsp"],
  CONDIMENT_RAKKYO:            ["Rakkyo", CO, "piece"],
  CONDIMENT_NORI_FLAKES:       ["Nori Flakes", CO, "tbsp"],
  CONDIMENT_MENMA:             ["Menma", CO, "tbsp"],

  // ── CONDIMENTS: Chinese ────────────────────────────────────
  CONDIMENT_FERMENTED_BLACK_BEAN: ["Fermented Black Bean", CO, "tbsp"],
  CONDIMENT_PRESERVED_MUSTARD: ["Preserved Mustard Greens", CO, "tbsp"],
  CONDIMENT_PICKLED_MUSTARD_GREEN: ["Pickled Mustard Green", CO, "tbsp"],
  CONDIMENT_PICKLED_GARLIC:    ["Pickled Garlic", CO, "piece"],
  CONDIMENT_PICKLED_CABBAGE:   ["Pickled Cabbage", CO, "cup"],
  CONDIMENT_CRISPY_SHALLOT:    ["Crispy Fried Shallots", CO, "tbsp"],
  CONDIMENT_CRISPY_GARLIC:     ["Crispy Fried Garlic", CO, "tbsp"],

  // ── CONDIMENTS: Korean ─────────────────────────────────────
  CONDIMENT_DANMUJI:           ["Danmuji", CO, "slice"],

  // ── CONDIMENTS: SE Asian / Global ──────────────────────────
  CONDIMENT_ACHAR:             ["Achar", CO, "tbsp"],
  CONDIMENT_SAMBAL_MATAH:      ["Sambal Matah", CO, "tbsp"],
  CONDIMENT_AJVAR:             ["Ajvar", CO, "tbsp"],
  CONDIMENT_PICKLED_JALAPENO:  ["Pickled Jalapeño", CO, "tbsp"],
  CONDIMENT_PICKLED_RED_ONION: ["Pickled Red Onion", CO, "tbsp"],
  CONDIMENT_ROASTED_RED_PEPPER:["Roasted Red Pepper", CO, "piece"],

  // ── BAKING: Asian ──────────────────────────────────────────
  BAKING_ROCK_SUGAR:           ["Rock Sugar", B, "piece"],
  BAKING_MALTOSE:              ["Maltose", B, "tbsp"],
  BAKING_RICE_SYRUP:           ["Rice Syrup", B, "tbsp"],
  BAKING_KINAKO:               ["Kinako", B, "tbsp"],
  BAKING_SWEET_POTATO_STARCH:  ["Sweet Potato Starch", B, "tbsp"],
  BAKING_MUNG_BEAN_STARCH:     ["Mung Bean Starch", B, "tbsp"],
  BAKING_WHEAT_STARCH:         ["Wheat Starch", B, "tbsp"],
  BAKING_GOLDEN_SYRUP:         ["Golden Syrup", B, "tbsp"],
  BAKING_BLACK_SESAME_POWDER:  ["Black Sesame Powder", B, "tbsp"],

  // ── NUTS & SEEDS: Asian ────────────────────────────────────
  NUT_GINKGO:                  ["Ginkgo Nut", N, "piece"],
  NUT_LOTUS_SEED:              ["Lotus Seed", N, "cup"],
  NUT_CANDIED_WALNUT:          ["Candied Walnut", N, "cup"],
  NUT_ROASTED_PEANUT:          ["Roasted Peanut", N, "cup"],
  NUT_WATERMELON_SEED:         ["Watermelon Seed", N, "cup"],

  // ── BEVERAGES: Asian ───────────────────────────────────────
  BEVERAGE_BARLEY_TEA:         ["Barley Tea", BV, "cup"],
  BEVERAGE_CORN_TEA:           ["Corn Tea", BV, "cup"],
  BEVERAGE_HOJICHA:            ["Hojicha", BV, "cup"],
  BEVERAGE_OOLONG_TEA:         ["Oolong Tea", BV, "cup"],
  BEVERAGE_JASMINE_TEA:        ["Jasmine Tea", BV, "cup"],
  BEVERAGE_CHAI:               ["Chai", BV, "cup"],
  BEVERAGE_SOJU:               ["Soju", BV, "tbsp"],
  BEVERAGE_SHOCHU:             ["Shochu", BV, "tbsp"],
  BEVERAGE_AMAZAKE:            ["Amazake", BV, "cup"],
  BEVERAGE_BONE_BROTH:         ["Bone Broth", BV, "cup"],
  BEVERAGE_PORK_BROTH:         ["Pork Broth", BV, "cup"],
  BEVERAGE_MUSHROOM_BROTH:     ["Mushroom Broth", BV, "cup"],
  BEVERAGE_KELP_BROTH:         ["Kelp Broth", BV, "cup"],
  BEVERAGE_ANCHOVY_BROTH:      ["Anchovy Broth", BV, "cup"],
  BEVERAGE_SPARKLING_WATER:    ["Sparkling Water", BV, "cup"],
  BEVERAGE_CLAM_JUICE:         ["Clam Juice", BV, "cup"],

  // ── MISC: Japanese ─────────────────────────────────────────
  MISC_NATTO:                  ["Natto", MI, "package"],
  MISC_TOFU_SKIN:              ["Tofu Skin", MI, "sheet"],
  MISC_FRIED_TOFU:             ["Fried Tofu", MI, "piece"],
  MISC_TOFU_PUFF:              ["Tofu Puff", MI, "piece"],
  MISC_KONJAC:                 ["Konjac", MI, "piece"],
  MISC_KOJI:                   ["Koji", MI, "tbsp"],
  MISC_TENKASU:                ["Tenkasu", MI, "tbsp"],
  MISC_SAKE_KASU:              ["Sake Kasu", MI, "tbsp"],

  // ── MISC: Chinese ──────────────────────────────────────────
  MISC_BLACK_SESAME_PASTE:     ["Black Sesame Paste", MI, "tbsp"],
  MISC_FISH_TOFU:              ["Fish Tofu", MI, "piece"],
  MISC_BLACK_MOSS:             ["Black Moss", MI, "oz"],
  MISC_DRIED_PERSIMMON:        ["Dried Persimmon", MI, "piece"],
  MISC_DRIED_LONGAN:           ["Dried Longan", MI, "cup"],
  MISC_TAPIOCA_PEARL:          ["Tapioca Pearl", MI, "cup"],
  MISC_FRIED_ONION:            ["Crispy Fried Onions", MI, "tbsp"],
  MISC_COCONUT_CREAM_POWDER:   ["Coconut Cream Powder", MI, "tbsp"],
  MISC_MALT_EXTRACT:           ["Malt Extract", MI, "tbsp"],
  MISC_YEAST_EXTRACT:          ["Yeast Extract", MI, "tsp"],

  // ── Final fill to 1,000 ────────────────────────────────────

  // More Asian Produce
  PRODUCE_KANGKONG:            ["Kangkong", P, "bunch"],
  PRODUCE_BANANA_LEAF_FRESH:   ["Fresh Banana Leaf", P, "piece"],
  PRODUCE_YOUNG_COCONUT:       ["Young Coconut", P, "piece"],
  PRODUCE_TORCH_GINGER:        ["Torch Ginger Flower", P, "piece"],
  PRODUCE_TURMERIC_FLOWER:     ["Turmeric Flower", P, "piece"],
  PRODUCE_LONG_EGGPLANT:       ["Long Eggplant", P, "piece"],
  PRODUCE_BABY_BOK_CHOY:       ["Baby Bok Choy", P, "piece"],
  PRODUCE_ENOKI_FRESH:         ["Fresh Enoki", P, "package"],
  PRODUCE_DAIKON_SPROUT:       ["Daikon Sprout", P, "cup"],

  // More Korean
  CONDIMENT_SSAM_LETTUCE:      ["Ssam Lettuce", CO, "head"],
  SPICE_PERILLA_POWDER:        ["Perilla Powder", SP, "tsp"],
  SAUCE_MAKGEOLLI:             ["Makgeolli", SA, "cup"],

  // More Japanese
  MISC_UMEBOSHI_PASTE:         ["Umeboshi Paste", MI, "tsp"],
  MISC_DASHI_PACK:             ["Dashi Pack", MI, "pack"],
  MISC_YUZU_JUICE:             ["Yuzu Juice", MI, "tsp"],
  MISC_YUZU_ZEST:              ["Yuzu Zest", MI, "tsp"],

  // More Chinese
  SAUCE_DOUFU_RU:              ["Red Fermented Bean Curd", SA, "piece"],
  PRODUCE_CHILI_OIL_CRISP:     ["Chili Oil with Crisp", P, "tbsp"],
  SAUCE_OYSTER_FLAVORED:       ["Vegetarian Oyster Sauce", SA, "tbsp"],

  // More SE Asian
  HERB_LAKSA_LEAF:             ["Laksa Leaf", H, "bunch"],
  HERB_KEMANGI:                ["Kemangi", H, "bunch"],
  SAUCE_BELACHAN_PASTE:        ["Belachan Paste", SA, "tsp"],
  BAKING_SAGO_PEARL:           ["Sago Pearl", B, "cup"],
  PRODUCE_PETAI:               ["Petai", P, "cup"],
  PRODUCE_KECOMBRANG:          ["Kecombrang", P, "piece"],
  CONDIMENT_SAMBAL_TERASI:     ["Sambal Terasi", CO, "tbsp"],

  // More Global
  DAIRY_COTTAGE_CHEESE:        ["Cottage Cheese", D, "cup"],
  SAUCE_CHIMICHURRI:           ["Chimichurri", SA, "tbsp"],
  SAUCE_ROMESCO:               ["Romesco Sauce", SA, "tbsp"],
  SAUCE_TZATZIKI:              ["Tzatziki", SA, "cup"],
  SAUCE_HOLLANDAISE:           ["Hollandaise Sauce", SA, "cup"],
};

// ── Build the exported canonical map ───────────────────────────

import { ALLERGEN_MAP, computeDietaryFlags } from "./allergens";

export const CANONICAL_INGREDIENTS: Record<string, CanonicalIngredient> = {};

for (const [id, [name, category, defaultUnitHint]] of Object.entries(DATA)) {
  const allergens = ALLERGEN_MAP[id] ?? [];
  const dietaryFlags = computeDietaryFlags(id, category, allergens);
  CANONICAL_INGREDIENTS[id] = {
    id,
    name,
    category,
    defaultUnitHint,
    commonAllergens: allergens.length > 0 ? allergens : undefined,
    dietaryFlags: dietaryFlags.length > 0 ? dietaryFlags : undefined,
  };
}

/** Total count for quick reference. */
export const CANONICAL_COUNT = Object.keys(CANONICAL_INGREDIENTS).length;
