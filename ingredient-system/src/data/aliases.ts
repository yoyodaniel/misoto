// ─────────────────────────────────────────────────────────────
// Alias Data — Maps messy recipe text to canonical IDs
//
// Each canonical ID maps to an array of lowercase English aliases.
// Includes: base name, plurals, synonyms, regional variants,
// common recipe phrases, and shorthand.
//
// RULES:
// - All aliases are lowercase
// - No duplicate aliases across different canonicals (except ambiguous)
// - "ground beef" is an alias for MEAT_GROUND_BEEF, NOT an attribute
// - "extra virgin olive oil" is an alias for OIL_OLIVE (attribute: extra-virgin)
// ─────────────────────────────────────────────────────────────

import { IngredientAlias, AmbiguousAlias } from "../types";

/**
 * Compact alias data: canonical ID → array of English aliases.
 * The IngredientMatcher builds O(1) lookups from this at construction time.
 */
export const ALIAS_DATA: Record<string, string[]> = {

  // ════════════════════════════════════════════════════════════
  // PRODUCE — Vegetables
  // ════════════════════════════════════════════════════════════

  PRODUCE_TOMATO: ["tomato", "tomatoes", "roma tomato", "roma tomatoes", "plum tomato", "plum tomatoes", "beefsteak tomato", "vine tomato", "vine tomatoes", "heirloom tomato", "campari tomato", "san marzano tomato", "san marzano tomatoes", "garden tomato", "globe tomato"],
  PRODUCE_CHERRY_TOMATO: ["cherry tomato", "cherry tomatoes", "baby tomato", "baby tomatoes"],
  PRODUCE_GRAPE_TOMATO: ["grape tomato", "grape tomatoes"],
  PRODUCE_POTATO: ["potato", "potatoes", "russet potato", "russet potatoes", "yukon gold potato", "yukon gold", "red potato", "red potatoes", "fingerling potato", "fingerling potatoes", "baking potato", "new potato", "new potatoes", "baby potato", "baby potatoes"],
  PRODUCE_SWEET_POTATO: ["sweet potato", "sweet potatoes", "kumara", "boniato"],
  PRODUCE_EGGPLANT: ["eggplant", "eggplants", "aubergine", "aubergines", "brinjal"],
  PRODUCE_CHINESE_EGGPLANT: ["chinese eggplant", "asian eggplant", "japanese eggplant"],
  PRODUCE_THAI_EGGPLANT: ["thai eggplant", "thai eggplants", "round eggplant"],
  PRODUCE_BELL_PEPPER: ["bell pepper", "bell peppers", "capsicum", "sweet pepper", "sweet peppers"],
  PRODUCE_RED_BELL_PEPPER: ["red bell pepper", "red bell peppers", "red capsicum", "red pepper", "red sweet pepper"],
  PRODUCE_GREEN_BELL_PEPPER: ["green bell pepper", "green bell peppers", "green capsicum", "green pepper"],
  PRODUCE_YELLOW_BELL_PEPPER: ["yellow bell pepper", "yellow bell peppers", "yellow capsicum"],
  PRODUCE_CHILI_PEPPER: ["chili pepper", "chili peppers", "chilli pepper", "chilli peppers", "chili", "chilli", "chilies", "chillies", "hot pepper", "hot peppers"],
  PRODUCE_JALAPENO: ["jalapeno", "jalapeño", "jalapenos", "jalapeños", "jalapeno pepper"],
  PRODUCE_SERRANO: ["serrano pepper", "serrano peppers", "serrano", "serrano chili"],
  PRODUCE_HABANERO: ["habanero", "habanero pepper", "habaneros"],
  PRODUCE_THAI_CHILI: ["thai chili", "thai chili pepper", "thai chilies", "thai bird chili"],
  PRODUCE_POBLANO: ["poblano", "poblano pepper", "poblanos"],
  PRODUCE_ANAHEIM_PEPPER: ["anaheim pepper", "anaheim peppers", "anaheim chili", "california chili"],
  PRODUCE_SCOTCH_BONNET: ["scotch bonnet", "scotch bonnet pepper", "scotch bonnets"],
  PRODUCE_BIRDS_EYE_CHILI: ["birds eye chili", "bird's eye chili", "birds eye chilies", "cili padi"],

  // Alliums
  PRODUCE_ONION: ["onion", "onions", "yellow onion", "yellow onions", "brown onion", "brown onions", "sweet onion", "sweet onions", "vidalia onion", "spanish onion"],
  PRODUCE_RED_ONION: ["red onion", "red onions", "purple onion"],
  PRODUCE_WHITE_ONION: ["white onion", "white onions"],
  PRODUCE_SHALLOT: ["shallot", "shallots", "eschalot", "eschalots"],
  PRODUCE_SCALLION: ["scallion", "scallions", "green onion", "green onions", "spring onion", "spring onions", "salad onion"],
  PRODUCE_LEEK: ["leek", "leeks"],
  PRODUCE_GARLIC: ["garlic", "garlic clove", "garlic cloves", "fresh garlic"],
  PRODUCE_PEARL_ONION: ["pearl onion", "pearl onions", "cipollini", "cocktail onion"],

  // Roots & Tubers
  PRODUCE_CARROT: ["carrot", "carrots", "baby carrot", "baby carrots"],
  PRODUCE_GINGER: ["ginger", "ginger root", "fresh ginger", "ginger knob"],
  PRODUCE_GALANGAL: ["galangal", "galanga", "blue ginger", "thai ginger"],
  PRODUCE_TURMERIC_ROOT: ["fresh turmeric", "turmeric root", "fresh turmeric root"],
  PRODUCE_DAIKON: ["daikon", "daikon radish", "white radish", "mooli", "chinese radish", "lo bak"],
  PRODUCE_RADISH: ["radish", "radishes", "red radish"],
  PRODUCE_TURNIP: ["turnip", "turnips"],
  PRODUCE_BEET: ["beet", "beets", "beetroot", "beetroots", "red beet"],
  PRODUCE_PARSNIP: ["parsnip", "parsnips"],
  PRODUCE_RUTABAGA: ["rutabaga", "rutabagas", "swede", "swedes", "neep"],
  PRODUCE_CELERIAC: ["celeriac", "celery root", "celery knob"],
  PRODUCE_JICAMA: ["jicama", "mexican turnip", "yam bean"],
  PRODUCE_HORSERADISH: ["horseradish", "horseradish root", "fresh horseradish"],
  PRODUCE_TARO: ["taro", "taro root", "dasheen", "eddoe"],
  PRODUCE_YAM: ["yam", "yams", "true yam"],
  PRODUCE_CASSAVA: ["cassava", "yuca", "manioc", "tapioca root"],
  PRODUCE_LOTUS_ROOT: ["lotus root", "lotus roots", "renkon"],
  PRODUCE_WATER_CHESTNUT: ["water chestnut", "water chestnuts"],
  PRODUCE_KOHLRABI: ["kohlrabi", "german turnip"],

  // Cucurbits
  PRODUCE_CUCUMBER: ["cucumber", "cucumbers", "english cucumber", "persian cucumber", "persian cucumbers", "kirby cucumber", "hothouse cucumber"],
  PRODUCE_ZUCCHINI: ["zucchini", "zucchinis", "courgette", "courgettes"],
  PRODUCE_YELLOW_SQUASH: ["yellow squash", "yellow summer squash", "crookneck squash"],
  PRODUCE_BUTTERNUT_SQUASH: ["butternut squash", "butternut"],
  PRODUCE_ACORN_SQUASH: ["acorn squash"],
  PRODUCE_KABOCHA: ["kabocha", "kabocha squash", "japanese pumpkin"],
  PRODUCE_SPAGHETTI_SQUASH: ["spaghetti squash"],
  PRODUCE_PUMPKIN: ["pumpkin", "pumpkins", "pie pumpkin", "sugar pumpkin"],
  PRODUCE_BITTER_MELON: ["bitter melon", "bitter gourd", "karela", "ampalaya"],
  PRODUCE_CHAYOTE: ["chayote", "chayote squash", "mirliton"],
  PRODUCE_WINTER_MELON: ["winter melon", "ash gourd", "wax gourd"],
  PRODUCE_LOOFAH: ["loofah", "loofah gourd", "luffa", "sponge gourd", "silk gourd"],

  // Brassicas
  PRODUCE_BROCCOLI: ["broccoli", "broccoli florets", "broccoli floret"],
  PRODUCE_BROCCOLI_RABE: ["broccoli rabe", "broccoli raab", "rapini", "broccolini"],
  PRODUCE_CAULIFLOWER: ["cauliflower", "cauliflower florets"],
  PRODUCE_CABBAGE: ["cabbage", "green cabbage"],
  PRODUCE_RED_CABBAGE: ["red cabbage", "purple cabbage"],
  PRODUCE_NAPA_CABBAGE: ["napa cabbage", "chinese cabbage", "wombok"],
  PRODUCE_BOK_CHOY: ["bok choy", "pak choy", "pak choi", "chinese cabbage greens", "baby bok choy"],
  PRODUCE_BRUSSELS_SPROUT: ["brussels sprout", "brussels sprouts", "brussel sprout", "brussel sprouts"],
  PRODUCE_KALE: ["kale", "curly kale", "lacinato kale", "dinosaur kale", "tuscan kale"],
  PRODUCE_CHINESE_BROCCOLI: ["chinese broccoli", "gai lan", "kai lan", "chinese kale"],

  // Leafy Greens
  PRODUCE_SPINACH: ["spinach", "baby spinach", "fresh spinach", "spinach leaves"],
  PRODUCE_LETTUCE: ["lettuce", "lettuce leaves", "salad greens", "mixed greens"],
  PRODUCE_ROMAINE_LETTUCE: ["romaine lettuce", "romaine", "cos lettuce", "romaine hearts"],
  PRODUCE_ICEBERG_LETTUCE: ["iceberg lettuce", "iceberg"],
  PRODUCE_ARUGULA: ["arugula", "rocket", "roquette", "rocket lettuce"],
  PRODUCE_WATERCRESS: ["watercress"],
  PRODUCE_SWISS_CHARD: ["swiss chard", "chard", "rainbow chard", "silverbeet"],
  PRODUCE_COLLARD_GREENS: ["collard greens", "collard", "collards"],
  PRODUCE_MUSTARD_GREENS: ["mustard greens", "mustard green"],
  PRODUCE_ENDIVE: ["endive", "belgian endive", "chicory"],
  PRODUCE_RADICCHIO: ["radicchio"],

  // Stalks & Stems
  PRODUCE_CELERY: ["celery", "celery stalk", "celery stalks", "celery rib", "celery ribs"],
  PRODUCE_FENNEL: ["fennel", "fennel bulb", "fresh fennel", "anise bulb"],
  PRODUCE_ASPARAGUS: ["asparagus", "asparagus spears", "asparagus tips"],
  PRODUCE_ARTICHOKE: ["artichoke", "artichokes", "artichoke heart", "artichoke hearts", "globe artichoke"],
  PRODUCE_HEARTS_OF_PALM: ["hearts of palm", "heart of palm", "palm heart", "palm hearts"],
  PRODUCE_RHUBARB: ["rhubarb", "rhubarb stalk", "rhubarb stalks"],

  // Pods & Greens
  PRODUCE_GREEN_BEAN: ["green bean", "green beans", "string bean", "string beans", "snap bean", "snap beans", "french bean", "french beans", "haricot vert", "haricots verts"],
  PRODUCE_LONG_BEAN: ["long bean", "long beans", "yard-long bean", "yard long bean", "chinese long bean"],
  PRODUCE_PEA: ["pea", "peas", "green pea", "green peas", "garden pea", "english pea"],
  PRODUCE_SNAP_PEA: ["snap pea", "snap peas", "sugar snap pea", "sugar snap peas"],
  PRODUCE_SNOW_PEA: ["snow pea", "snow peas", "mange tout", "mangetout"],
  PRODUCE_EDAMAME: ["edamame", "green soybean", "green soybeans"],
  PRODUCE_OKRA: ["okra", "okras", "lady finger", "ladies finger", "bhindi", "gumbo"],
  PRODUCE_CORN: ["corn", "sweet corn", "corn on the cob", "corn kernels", "corn cob", "maize"],
  PRODUCE_BABY_CORN: ["baby corn", "baby corn cobs"],

  // Asian Vegetables
  PRODUCE_BAMBOO_SHOOT: ["bamboo shoot", "bamboo shoots", "bamboo tips"],
  PRODUCE_BEAN_SPROUT: ["bean sprout", "bean sprouts", "mung bean sprout", "mung bean sprouts", "beansprouts", "sprouts"],
  PRODUCE_MORNING_GLORY: ["morning glory", "water spinach", "kangkung", "kangkong", "ong choy", "water convolvulus"],
  PRODUCE_CHINESE_CELERY: ["chinese celery", "leaf celery"],
  PRODUCE_BANANA_BLOSSOM: ["banana blossom", "banana flower", "banana heart"],
  PRODUCE_CORIANDER_ROOT: ["coriander root", "cilantro root"],

  // Mushrooms
  PRODUCE_MUSHROOM: ["mushroom", "mushrooms", "button mushroom", "button mushrooms"],
  PRODUCE_WHITE_MUSHROOM: ["white mushroom", "white mushrooms", "white button mushroom"],
  PRODUCE_CREMINI: ["cremini mushroom", "cremini mushrooms", "cremini", "baby bella", "baby portobello", "brown mushroom"],
  PRODUCE_PORTOBELLO: ["portobello", "portobello mushroom", "portobello mushrooms", "portabella", "portabello"],
  PRODUCE_SHIITAKE: ["shiitake", "shiitake mushroom", "shiitake mushrooms", "shitake"],
  PRODUCE_OYSTER_MUSHROOM: ["oyster mushroom", "oyster mushrooms"],
  PRODUCE_ENOKI: ["enoki", "enoki mushroom", "enoki mushrooms", "enokitake", "golden needle mushroom"],
  PRODUCE_KING_OYSTER_MUSHROOM: ["king oyster mushroom", "king oyster mushrooms", "king trumpet mushroom", "eryngii"],
  PRODUCE_CHANTERELLE: ["chanterelle", "chanterelle mushroom", "chanterelle mushrooms", "chanterelles"],
  PRODUCE_WOOD_EAR: ["wood ear", "wood ear mushroom", "wood ear mushrooms", "black fungus", "cloud ear", "cloud ear fungus"],
  PRODUCE_MAITAKE: ["maitake", "maitake mushroom", "hen of the woods"],

  // ════════════════════════════════════════════════════════════
  // PRODUCE — Fruits
  // ════════════════════════════════════════════════════════════

  PRODUCE_AVOCADO: ["avocado", "avocados", "hass avocado"],
  PRODUCE_LEMON: ["lemon", "lemons", "lemon juice", "fresh lemon", "lemon wedge"],
  PRODUCE_LIME: ["lime", "limes", "lime juice", "fresh lime", "lime wedge", "key lime"],
  PRODUCE_ORANGE: ["orange", "oranges", "navel orange", "blood orange", "orange juice"],
  PRODUCE_GRAPEFRUIT: ["grapefruit", "grapefruits"],
  PRODUCE_TANGERINE: ["tangerine", "tangerines", "mandarin", "mandarins", "mandarin orange", "clementine", "clementines", "satsuma"],
  PRODUCE_YUZU: ["yuzu", "yuzu juice"],
  PRODUCE_CALAMANSI: ["calamansi", "calamansi lime", "calamondin", "philippine lime"],
  PRODUCE_KUMQUAT: ["kumquat", "kumquats"],
  PRODUCE_MANGO: ["mango", "mangoes", "mangos", "green mango"],
  PRODUCE_PINEAPPLE: ["pineapple", "pineapples", "fresh pineapple", "pineapple chunks"],
  PRODUCE_BANANA: ["banana", "bananas", "ripe banana"],
  PRODUCE_PLANTAIN: ["plantain", "plantains", "cooking banana", "green plantain", "ripe plantain"],
  PRODUCE_COCONUT: ["coconut", "fresh coconut", "coconut meat"],
  PRODUCE_APPLE: ["apple", "apples", "granny smith", "gala apple", "fuji apple", "green apple"],
  PRODUCE_PEAR: ["pear", "pears", "bartlett pear", "bosc pear"],
  PRODUCE_PEACH: ["peach", "peaches"],
  PRODUCE_PLUM: ["plum", "plums"],
  PRODUCE_NECTARINE: ["nectarine", "nectarines"],
  PRODUCE_APRICOT: ["apricot", "apricots", "fresh apricot"],
  PRODUCE_CHERRY: ["cherry", "cherries", "sweet cherry", "sour cherry", "bing cherry", "maraschino cherry"],
  PRODUCE_GRAPE: ["grape", "grapes", "red grape", "green grape", "seedless grape"],
  PRODUCE_STRAWBERRY: ["strawberry", "strawberries", "fresh strawberry"],
  PRODUCE_BLUEBERRY: ["blueberry", "blueberries", "fresh blueberry"],
  PRODUCE_RASPBERRY: ["raspberry", "raspberries"],
  PRODUCE_BLACKBERRY: ["blackberry", "blackberries"],
  PRODUCE_CRANBERRY: ["cranberry", "cranberries", "fresh cranberry"],
  PRODUCE_POMEGRANATE: ["pomegranate", "pomegranates", "pomegranate seeds", "pomegranate arils"],
  PRODUCE_FIG: ["fig", "figs", "fresh fig"],
  PRODUCE_DATE: ["date", "dates", "medjool date", "medjool dates", "deglet noor"],
  PRODUCE_PAPAYA: ["papaya", "papayas", "pawpaw"],
  PRODUCE_GUAVA: ["guava", "guavas"],
  PRODUCE_PASSION_FRUIT: ["passion fruit", "passionfruit", "passion fruits", "maracuja"],
  PRODUCE_LYCHEE: ["lychee", "lychees", "litchi", "lichee"],
  PRODUCE_DRAGON_FRUIT: ["dragon fruit", "dragonfruit", "pitaya", "pitahaya"],
  PRODUCE_JACKFRUIT: ["jackfruit", "jack fruit", "young jackfruit"],
  PRODUCE_DURIAN: ["durian", "durians"],
  PRODUCE_TAMARIND: ["tamarind", "tamarind pulp", "tamarind fruit"],
  PRODUCE_WATERMELON: ["watermelon", "water melon"],
  PRODUCE_CANTALOUPE: ["cantaloupe", "cantaloup", "rockmelon", "muskmelon"],
  PRODUCE_HONEYDEW: ["honeydew", "honeydew melon"],
  PRODUCE_PERSIMMON: ["persimmon", "persimmons", "fuyu persimmon", "hachiya persimmon", "sharon fruit"],
  PRODUCE_STARFRUIT: ["starfruit", "star fruit", "carambola"],
  PRODUCE_KIWI: ["kiwi", "kiwis", "kiwifruit", "kiwi fruit"],

  // Dried Fruits
  PRODUCE_RAISIN: ["raisin", "raisins", "golden raisin", "golden raisins", "sultana", "sultanas", "currant", "currants"],
  PRODUCE_DRIED_CRANBERRY: ["dried cranberry", "dried cranberries", "craisins"],
  PRODUCE_DRIED_APRICOT: ["dried apricot", "dried apricots"],
  PRODUCE_PRUNE: ["prune", "prunes", "dried plum", "dried plums"],
  PRODUCE_DRIED_FIG: ["dried fig", "dried figs"],

  // ════════════════════════════════════════════════════════════
  // MEAT
  // ════════════════════════════════════════════════════════════

  MEAT_BEEF: ["beef", "stewing beef", "beef roast"],
  MEAT_BEEF_STEAK: ["beef steak", "steak", "sirloin steak", "ribeye", "ribeye steak", "rib eye", "new york strip", "t-bone", "strip steak", "filet mignon"],
  MEAT_GROUND_BEEF: ["ground beef", "beef mince", "minced beef", "hamburger meat", "ground chuck"],
  MEAT_BEEF_BRISKET: ["beef brisket", "brisket"],
  MEAT_BEEF_SHORT_RIB: ["beef short rib", "beef short ribs", "short rib", "short ribs"],
  MEAT_BEEF_CHUCK: ["beef chuck", "chuck roast", "chuck steak", "chuck"],
  MEAT_BEEF_TENDERLOIN: ["beef tenderloin", "tenderloin", "filet"],
  MEAT_BEEF_SIRLOIN: ["beef sirloin", "sirloin", "top sirloin"],
  MEAT_STEW_BEEF: ["stew beef", "beef stew meat", "stew meat", "beef cubes"],
  MEAT_CORNED_BEEF: ["corned beef"],
  MEAT_PORK: ["pork", "pork roast"],
  MEAT_PORK_BELLY: ["pork belly", "pork belly slices"],
  MEAT_PORK_CHOP: ["pork chop", "pork chops", "pork cutlet", "pork cutlets"],
  MEAT_GROUND_PORK: ["ground pork", "pork mince", "minced pork"],
  MEAT_PORK_LOIN: ["pork loin", "pork loin roast", "center-cut pork loin"],
  MEAT_PORK_SHOULDER: ["pork shoulder", "pork butt", "boston butt", "pork shoulder roast"],
  MEAT_PORK_RIB: ["pork rib", "pork ribs", "spare ribs", "spareribs", "baby back ribs"],
  MEAT_PORK_TENDERLOIN: ["pork tenderloin"],
  MEAT_LAMB: ["lamb", "lamb meat"],
  MEAT_LAMB_CHOP: ["lamb chop", "lamb chops", "lamb loin chop", "lamb cutlet"],
  MEAT_GROUND_LAMB: ["ground lamb", "lamb mince", "minced lamb"],
  MEAT_LAMB_LEG: ["lamb leg", "leg of lamb"],
  MEAT_LAMB_SHANK: ["lamb shank", "lamb shanks"],
  MEAT_VEAL: ["veal", "veal cutlet"],
  MEAT_GOAT: ["goat", "goat meat", "mutton", "chevon"],
  MEAT_VENISON: ["venison", "deer meat", "deer"],
  MEAT_RABBIT: ["rabbit", "rabbit meat"],
  MEAT_BACON: ["bacon", "bacon strips", "bacon rashers", "streaky bacon", "turkey bacon", "canadian bacon", "back bacon"],
  MEAT_HAM: ["ham", "ham steak", "deli ham", "smoked ham", "gammon"],
  MEAT_PROSCIUTTO: ["prosciutto", "parma ham", "prosciutto di parma"],
  MEAT_PANCETTA: ["pancetta", "italian bacon"],
  MEAT_SAUSAGE: ["sausage", "sausages", "pork sausage", "italian sausage", "breakfast sausage", "sausage link", "sausage links", "bratwurst", "brat"],
  MEAT_CHORIZO: ["chorizo", "spanish chorizo", "mexican chorizo"],
  MEAT_SALAMI: ["salami", "genoa salami", "hard salami"],
  MEAT_SPAM: ["spam", "luncheon meat", "canned meat"],
  MEAT_JERKY: ["jerky", "beef jerky", "dried beef"],

  // ════════════════════════════════════════════════════════════
  // POULTRY
  // ════════════════════════════════════════════════════════════

  POULTRY_CHICKEN: ["chicken", "whole chicken"],
  POULTRY_CHICKEN_BREAST: ["chicken breast", "chicken breasts", "boneless chicken breast", "skinless chicken breast", "boneless skinless chicken breast", "chicken fillet"],
  POULTRY_CHICKEN_THIGH: ["chicken thigh", "chicken thighs", "boneless chicken thigh", "boneless skinless chicken thigh"],
  POULTRY_CHICKEN_WING: ["chicken wing", "chicken wings"],
  POULTRY_CHICKEN_DRUMSTICK: ["chicken drumstick", "chicken drumsticks", "chicken leg", "chicken legs"],
  POULTRY_GROUND_CHICKEN: ["ground chicken", "chicken mince", "minced chicken"],
  POULTRY_CHICKEN_LIVER: ["chicken liver", "chicken livers"],
  POULTRY_DUCK: ["duck", "whole duck"],
  POULTRY_DUCK_BREAST: ["duck breast", "duck breasts", "magret de canard"],
  POULTRY_TURKEY: ["turkey", "whole turkey"],
  POULTRY_GROUND_TURKEY: ["ground turkey", "turkey mince", "minced turkey"],
  POULTRY_QUAIL: ["quail", "quails"],
  POULTRY_GOOSE: ["goose"],
  POULTRY_CORNISH_HEN: ["cornish hen", "cornish game hen", "cornish hens", "poussin"],

  // ════════════════════════════════════════════════════════════
  // SEAFOOD
  // ════════════════════════════════════════════════════════════

  SEAFOOD_SALMON: ["salmon", "salmon fillet", "salmon fillets", "salmon steak", "atlantic salmon", "sockeye salmon", "king salmon", "coho salmon", "wild salmon"],
  SEAFOOD_TUNA: ["tuna", "tuna steak", "tuna fillet", "ahi tuna", "yellowfin tuna", "albacore tuna", "canned tuna", "tuna fish"],
  SEAFOOD_COD: ["cod", "cod fillet", "cod fillets", "atlantic cod", "pacific cod", "codfish"],
  SEAFOOD_TILAPIA: ["tilapia", "tilapia fillet", "tilapia fillets"],
  SEAFOOD_SEA_BASS: ["sea bass", "sea bass fillet", "branzino", "loup de mer", "chilean sea bass"],
  SEAFOOD_HALIBUT: ["halibut", "halibut fillet", "halibut steak"],
  SEAFOOD_MAHI_MAHI: ["mahi mahi", "mahi-mahi", "dorado", "dolphinfish"],
  SEAFOOD_SWORDFISH: ["swordfish", "swordfish steak"],
  SEAFOOD_TROUT: ["trout", "rainbow trout", "steelhead trout"],
  SEAFOOD_SARDINE: ["sardine", "sardines", "canned sardines"],
  SEAFOOD_MACKEREL: ["mackerel", "king mackerel", "spanish mackerel", "canned mackerel"],
  SEAFOOD_ANCHOVY: ["anchovy", "anchovies", "anchovy fillet", "anchovy fillets"],
  SEAFOOD_CATFISH: ["catfish", "catfish fillet"],
  SEAFOOD_RED_SNAPPER: ["red snapper", "snapper"],
  SEAFOOD_GROUPER: ["grouper", "grouper fillet"],
  SEAFOOD_SOLE: ["sole", "sole fillet", "dover sole", "lemon sole"],
  SEAFOOD_FLOUNDER: ["flounder", "flounder fillet"],
  SEAFOOD_HADDOCK: ["haddock", "haddock fillet", "smoked haddock"],
  SEAFOOD_HERRING: ["herring", "kippered herring", "pickled herring"],
  SEAFOOD_CARP: ["carp"],
  SEAFOOD_MILKFISH: ["milkfish", "bangus"],
  SEAFOOD_POMFRET: ["pomfret", "pompano"],
  SEAFOOD_BARRAMUNDI: ["barramundi", "asian sea bass"],
  SEAFOOD_SMOKED_SALMON: ["smoked salmon", "lox", "nova lox", "gravlax"],
  SEAFOOD_SHRIMP: ["shrimp", "shrimps", "raw shrimp", "cooked shrimp", "jumbo shrimp", "medium shrimp", "small shrimp", "tiger shrimp"],
  SEAFOOD_PRAWN: ["prawn", "prawns", "king prawn", "king prawns", "tiger prawn", "tiger prawns", "jumbo prawn"],
  SEAFOOD_CRAB: ["crab", "crab meat", "crabmeat", "lump crab", "blue crab", "dungeness crab"],
  SEAFOOD_LOBSTER: ["lobster", "lobster tail", "lobster tails", "lobster meat"],
  SEAFOOD_CRAWFISH: ["crawfish", "crayfish", "crawdad", "crawdads"],
  SEAFOOD_MUSSEL: ["mussel", "mussels", "blue mussel"],
  SEAFOOD_CLAM: ["clam", "clams", "littleneck clam", "cherrystone clam", "manila clam"],
  SEAFOOD_OYSTER: ["oyster", "oysters", "fresh oyster"],
  SEAFOOD_SCALLOP: ["scallop", "scallops", "sea scallop", "bay scallop", "sea scallops", "bay scallops"],
  SEAFOOD_SQUID: ["squid", "calamari", "squid rings", "baby squid"],
  SEAFOOD_OCTOPUS: ["octopus", "baby octopus", "tako"],
  SEAFOOD_CUTTLEFISH: ["cuttlefish"],
  SEAFOOD_FISH_CAKE: ["fish cake", "fish cakes", "kamaboko"],
  SEAFOOD_IMITATION_CRAB: ["imitation crab", "surimi", "crab stick", "crab sticks", "krab"],
  SEAFOOD_DRIED_SHRIMP: ["dried shrimp", "dried shrimps", "dried prawns"],
  SEAFOOD_FISH_BALL: ["fish ball", "fish balls"],
  SEAFOOD_SHRIMP_PASTE: ["shrimp paste", "prawn paste", "kapi", "belacan paste"],
  SEAFOOD_DRIED_ANCHOVY: ["dried anchovy", "dried anchovies", "ikan bilis"],
  SEAFOOD_ABALONE: ["abalone"],
  SEAFOOD_SEA_URCHIN: ["sea urchin", "uni"],

  // ════════════════════════════════════════════════════════════
  // DAIRY & EGGS
  // ════════════════════════════════════════════════════════════

  DAIRY_MILK: ["milk"],
  DAIRY_WHOLE_MILK: ["whole milk", "full cream milk", "full-fat milk"],
  DAIRY_BUTTERMILK: ["buttermilk"],
  DAIRY_EVAPORATED_MILK: ["evaporated milk"],
  DAIRY_CONDENSED_MILK: ["condensed milk", "sweetened condensed milk"],
  DAIRY_CREAM: ["cream", "light cream", "single cream", "pouring cream"],
  DAIRY_HEAVY_CREAM: ["heavy cream", "heavy whipping cream", "double cream", "thick cream"],
  DAIRY_HALF_AND_HALF: ["half and half", "half-and-half", "half & half"],
  DAIRY_SOUR_CREAM: ["sour cream", "soured cream"],
  DAIRY_WHIPPING_CREAM: ["whipping cream"],
  DAIRY_CREAM_CHEESE: ["cream cheese", "philadelphia"],
  DAIRY_BUTTER: ["butter", "unsalted butter", "salted butter", "sweet cream butter"],
  DAIRY_GHEE: ["ghee", "clarified butter"],
  DAIRY_MARGARINE: ["margarine"],
  DAIRY_YOGURT: ["yogurt", "yoghurt", "plain yogurt", "natural yogurt"],
  DAIRY_GREEK_YOGURT: ["greek yogurt", "greek yoghurt", "strained yogurt"],
  DAIRY_CHEDDAR: ["cheddar", "cheddar cheese", "sharp cheddar", "mild cheddar"],
  DAIRY_MOZZARELLA: ["mozzarella", "mozzarella cheese", "fresh mozzarella", "low-moisture mozzarella"],
  DAIRY_PARMESAN: ["parmesan", "parmesan cheese", "parmigiano", "parmigiano reggiano", "parmigiano-reggiano", "grated parmesan"],
  DAIRY_FETA: ["feta", "feta cheese", "crumbled feta"],
  DAIRY_GOUDA: ["gouda", "gouda cheese"],
  DAIRY_BRIE: ["brie", "brie cheese"],
  DAIRY_SWISS_CHEESE: ["swiss cheese", "swiss", "emmental", "emmentaler"],
  DAIRY_GOAT_CHEESE: ["goat cheese", "chevre", "chèvre", "goat's cheese"],
  DAIRY_RICOTTA: ["ricotta", "ricotta cheese"],
  DAIRY_MASCARPONE: ["mascarpone", "mascarpone cheese"],
  DAIRY_GRUYERE: ["gruyere", "gruyère", "gruyere cheese"],
  DAIRY_BLUE_CHEESE: ["blue cheese", "gorgonzola", "roquefort", "stilton"],
  DAIRY_MONTEREY_JACK: ["monterey jack", "jack cheese", "pepper jack"],
  DAIRY_COTIJA: ["cotija", "cotija cheese"],
  DAIRY_PECORINO: ["pecorino", "pecorino romano"],
  DAIRY_PANEER: ["paneer", "indian cottage cheese"],
  DAIRY_EGG: ["egg", "eggs", "chicken egg", "chicken eggs", "whole egg"],
  DAIRY_EGG_WHITE: ["egg white", "egg whites"],
  DAIRY_EGG_YOLK: ["egg yolk", "egg yolks"],
  DAIRY_QUAIL_EGG: ["quail egg", "quail eggs"],
  DAIRY_DUCK_EGG: ["duck egg", "duck eggs"],
  DAIRY_COCONUT_MILK: ["coconut milk", "canned coconut milk", "full-fat coconut milk", "lite coconut milk", "light coconut milk"],
  DAIRY_COCONUT_CREAM: ["coconut cream", "thick coconut milk", "cream of coconut"],
  DAIRY_SOY_MILK: ["soy milk", "soymilk", "soya milk"],
  DAIRY_ALMOND_MILK: ["almond milk"],
  DAIRY_OAT_MILK: ["oat milk"],

  // ════════════════════════════════════════════════════════════
  // GRAINS, PASTA, NOODLES, BREAD
  // ════════════════════════════════════════════════════════════

  // Rice
  GRAIN_WHITE_RICE: ["white rice", "rice", "long grain rice", "long-grain rice", "medium grain rice"],
  GRAIN_BROWN_RICE: ["brown rice"],
  GRAIN_JASMINE_RICE: ["jasmine rice", "thai jasmine rice"],
  GRAIN_BASMATI_RICE: ["basmati rice", "basmati"],
  GRAIN_SUSHI_RICE: ["sushi rice", "japanese rice", "short grain rice", "calrose rice"],
  GRAIN_STICKY_RICE: ["sticky rice", "glutinous rice", "sweet rice"],
  GRAIN_WILD_RICE: ["wild rice"],
  GRAIN_ARBORIO_RICE: ["arborio rice", "arborio", "risotto rice"],

  // Pasta
  GRAIN_SPAGHETTI: ["spaghetti"],
  GRAIN_PENNE: ["penne", "penne rigate"],
  GRAIN_FETTUCCINE: ["fettuccine", "fettucine", "fettuccini"],
  GRAIN_LINGUINE: ["linguine", "linguini"],
  GRAIN_MACARONI: ["macaroni", "elbow macaroni", "elbow pasta"],
  GRAIN_RIGATONI: ["rigatoni"],
  GRAIN_ORZO: ["orzo", "risoni"],
  GRAIN_LASAGNA: ["lasagna", "lasagne", "lasagna sheets", "lasagne sheets", "lasagna noodles"],
  GRAIN_PAPPARDELLE: ["pappardelle"],
  GRAIN_ANGEL_HAIR: ["angel hair", "angel hair pasta", "capellini"],
  GRAIN_FARFALLE: ["farfalle", "bow tie pasta", "bowtie pasta"],
  GRAIN_TORTELLINI: ["tortellini"],
  GRAIN_GNOCCHI: ["gnocchi", "potato gnocchi"],

  // Asian Noodles
  GRAIN_EGG_NOODLE: ["egg noodle", "egg noodles", "chinese egg noodle", "wonton noodle"],
  GRAIN_RICE_NOODLE: ["rice noodle", "rice noodles", "pad thai noodle", "flat rice noodle", "ho fun", "chow fun", "kway teow", "rice stick noodle"],
  GRAIN_GLASS_NOODLE: ["glass noodle", "glass noodles", "cellophane noodle", "cellophane noodles", "bean thread noodle", "bean thread", "mung bean noodle", "tang hoon"],
  GRAIN_UDON: ["udon", "udon noodle", "udon noodles"],
  GRAIN_SOBA: ["soba", "soba noodle", "soba noodles", "buckwheat noodle"],
  GRAIN_RAMEN_NOODLE: ["ramen noodle", "ramen noodles", "ramen"],
  GRAIN_RICE_VERMICELLI: ["rice vermicelli", "thin rice noodle", "bihon", "bee hoon", "bun", "mi fen"],
  GRAIN_LO_MEIN: ["lo mein noodle", "lo mein noodles", "lo mein", "chow mein noodle", "chow mein noodles"],

  // Wrappers
  GRAIN_RICE_PAPER: ["rice paper", "rice paper wrapper", "rice paper wrappers", "spring roll skin"],
  GRAIN_WONTON_WRAPPER: ["wonton wrapper", "wonton wrappers", "wonton skin", "wonton skins"],
  GRAIN_SPRING_ROLL_WRAPPER: ["spring roll wrapper", "spring roll wrappers", "lumpia wrapper", "egg roll wrapper", "egg roll wrappers"],
  GRAIN_DUMPLING_WRAPPER: ["dumpling wrapper", "dumpling wrappers", "dumpling skin", "gyoza wrapper", "potsticker wrapper"],
  GRAIN_PHYLLO_DOUGH: ["phyllo dough", "filo dough", "phyllo", "filo", "filo pastry", "phyllo pastry"],

  // Bread
  GRAIN_BREAD: ["bread", "white bread", "sandwich bread"],
  GRAIN_PITA: ["pita", "pita bread", "pitta", "pitta bread"],
  GRAIN_NAAN: ["naan", "naan bread", "garlic naan"],
  GRAIN_TORTILLA: ["tortilla", "tortillas", "flour tortilla", "flour tortillas"],
  GRAIN_BAGUETTE: ["baguette", "french bread", "french baguette"],
  GRAIN_CIABATTA: ["ciabatta", "ciabatta bread"],
  GRAIN_FOCACCIA: ["focaccia", "focaccia bread"],
  GRAIN_SOURDOUGH: ["sourdough", "sourdough bread"],
  GRAIN_BREADCRUMBS: ["breadcrumbs", "bread crumbs", "dry breadcrumbs"],
  GRAIN_PANKO: ["panko", "panko breadcrumbs", "panko bread crumbs", "japanese breadcrumbs"],

  // Other Grains
  GRAIN_OATS: ["oats", "rolled oats", "old fashioned oats", "quick oats", "oatmeal", "steel cut oats"],
  GRAIN_QUINOA: ["quinoa", "white quinoa", "red quinoa"],
  GRAIN_BARLEY: ["barley", "pearl barley"],
  GRAIN_MILLET: ["millet"],
  GRAIN_BUCKWHEAT: ["buckwheat", "buckwheat groats", "kasha"],
  GRAIN_CORNMEAL: ["cornmeal", "corn meal", "yellow cornmeal"],
  GRAIN_POLENTA: ["polenta"],
  GRAIN_COUSCOUS: ["couscous", "israeli couscous", "pearl couscous"],
  GRAIN_BULGUR: ["bulgur", "bulgur wheat", "bulghur", "cracked wheat"],
  GRAIN_SEMOLINA: ["semolina", "semolina flour"],
  GRAIN_GRITS: ["grits", "hominy grits"],
  GRAIN_WHEAT_GERM: ["wheat germ"],
  GRAIN_FARRO: ["farro"],

  // ════════════════════════════════════════════════════════════
  // LEGUMES
  // ════════════════════════════════════════════════════════════

  LEGUME_CHICKPEA: ["chickpea", "chickpeas", "garbanzo", "garbanzo bean", "garbanzo beans", "ceci", "chana"],
  LEGUME_LENTIL: ["lentil", "lentils", "brown lentil", "brown lentils"],
  LEGUME_RED_LENTIL: ["red lentil", "red lentils", "masoor dal"],
  LEGUME_GREEN_LENTIL: ["green lentil", "green lentils", "french lentil", "french lentils", "puy lentil"],
  LEGUME_BLACK_BEAN: ["black bean", "black beans", "black turtle bean"],
  LEGUME_KIDNEY_BEAN: ["kidney bean", "kidney beans", "red kidney bean", "red kidney beans"],
  LEGUME_PINTO_BEAN: ["pinto bean", "pinto beans"],
  LEGUME_NAVY_BEAN: ["navy bean", "navy beans"],
  LEGUME_CANNELLINI_BEAN: ["cannellini bean", "cannellini beans", "white kidney bean"],
  LEGUME_LIMA_BEAN: ["lima bean", "lima beans", "butter bean", "butter beans"],
  LEGUME_MUNG_BEAN: ["mung bean", "mung beans", "moong bean", "green gram"],
  LEGUME_SOYBEAN: ["soybean", "soybeans", "soya bean", "soya beans"],
  LEGUME_BLACK_EYED_PEA: ["black-eyed pea", "black eyed pea", "black-eyed peas", "black eyed peas", "cowpea"],
  LEGUME_FAVA_BEAN: ["fava bean", "fava beans", "broad bean", "broad beans"],
  LEGUME_SPLIT_PEA: ["split pea", "split peas", "yellow split pea", "green split pea"],
  LEGUME_ADZUKI_BEAN: ["adzuki bean", "adzuki beans", "azuki bean", "red bean", "red beans"],
  LEGUME_WHITE_BEAN: ["white bean", "white beans"],
  LEGUME_GREAT_NORTHERN_BEAN: ["great northern bean", "great northern beans"],

  // ════════════════════════════════════════════════════════════
  // SPICES
  // ════════════════════════════════════════════════════════════

  SPICE_SALT: ["salt", "table salt", "fine salt", "iodized salt"],
  SPICE_SEA_SALT: ["sea salt", "fleur de sel", "flaky sea salt", "maldon salt"],
  SPICE_KOSHER_SALT: ["kosher salt", "coarse salt", "diamond crystal", "morton kosher"],
  SPICE_BLACK_PEPPER: ["black pepper", "black peppercorn", "black peppercorns", "cracked black pepper", "freshly ground black pepper", "pepper"],
  SPICE_WHITE_PEPPER: ["white pepper", "ground white pepper", "white peppercorn"],
  SPICE_CUMIN: ["cumin", "ground cumin", "cumin seed", "cumin seeds", "jeera"],
  SPICE_CORIANDER_SEED: ["coriander seed", "coriander seeds", "ground coriander", "coriander powder", "dhania"],
  SPICE_TURMERIC: ["turmeric", "ground turmeric", "turmeric powder", "haldi"],
  SPICE_PAPRIKA: ["paprika", "sweet paprika", "hungarian paprika"],
  SPICE_SMOKED_PAPRIKA: ["smoked paprika", "pimenton", "pimentón"],
  SPICE_CHILI_POWDER: ["chili powder", "chilli powder", "chile powder"],
  SPICE_CAYENNE: ["cayenne", "cayenne pepper", "ground cayenne"],
  SPICE_RED_PEPPER_FLAKES: ["red pepper flakes", "crushed red pepper", "crushed red pepper flakes", "chili flakes", "pepper flakes"],
  SPICE_CINNAMON: ["cinnamon", "ground cinnamon", "cinnamon stick", "cinnamon sticks", "cinnamon powder", "cassia"],
  SPICE_NUTMEG: ["nutmeg", "ground nutmeg", "whole nutmeg"],
  SPICE_CLOVE: ["clove", "cloves", "whole clove", "whole cloves", "ground cloves"],
  SPICE_ALLSPICE: ["allspice", "ground allspice", "allspice berry", "allspice berries", "pimento"],
  SPICE_CARDAMOM: ["cardamom", "cardamom pod", "cardamom pods", "green cardamom", "ground cardamom", "elaichi"],
  SPICE_STAR_ANISE: ["star anise", "star anise pod", "whole star anise"],
  SPICE_FENNEL_SEED: ["fennel seed", "fennel seeds"],
  SPICE_MUSTARD_SEED: ["mustard seed", "mustard seeds", "yellow mustard seed", "black mustard seed"],
  SPICE_GARAM_MASALA: ["garam masala"],
  SPICE_CURRY_POWDER: ["curry powder"],
  SPICE_FIVE_SPICE: ["five spice", "five spice powder", "chinese five spice", "5 spice"],
  SPICE_SAFFRON: ["saffron", "saffron threads", "saffron strands"],
  SPICE_SUMAC: ["sumac", "sumach"],
  SPICE_ZAATAR: ["za'atar", "zaatar", "zatar"],
  SPICE_SZECHUAN_PEPPERCORN: ["szechuan peppercorn", "sichuan peppercorn", "szechuan pepper", "sichuan pepper", "chinese prickly ash"],
  SPICE_FENUGREEK: ["fenugreek", "fenugreek seed", "fenugreek seeds", "methi", "fenugreek leaves"],
  SPICE_MSG: ["msg", "monosodium glutamate", "umami seasoning"],
  SPICE_CARAWAY: ["caraway", "caraway seed", "caraway seeds"],
  SPICE_ANISE_SEED: ["anise seed", "anise seeds", "aniseed"],
  SPICE_JUNIPER_BERRY: ["juniper berry", "juniper berries"],
  SPICE_CELERY_SEED: ["celery seed", "celery seeds"],
  SPICE_ONION_POWDER: ["onion powder"],
  SPICE_GARLIC_POWDER: ["garlic powder"],
  SPICE_GINGER_POWDER: ["ginger powder", "ground ginger", "dried ginger"],
  SPICE_CHIPOTLE_POWDER: ["chipotle powder", "chipotle chili powder", "ground chipotle"],
  SPICE_WASABI: ["wasabi", "wasabi powder", "wasabi paste"],
  SPICE_MACE: ["mace", "ground mace"],
  SPICE_ASAFOETIDA: ["asafoetida", "hing", "asafetida"],
  SPICE_ACHIOTE: ["achiote", "achiote paste", "annatto", "annatto seed"],
  SPICE_VANILLA_BEAN: ["vanilla bean", "vanilla pod", "vanilla beans"],
  SPICE_ITALIAN_SEASONING: ["italian seasoning", "italian herbs"],
  SPICE_HERBS_DE_PROVENCE: ["herbes de provence", "herbs de provence"],
  SPICE_CAJUN_SEASONING: ["cajun seasoning", "cajun spice", "creole seasoning"],
  SPICE_TACO_SEASONING: ["taco seasoning", "taco spice mix"],
  SPICE_TOGARASHI: ["togarashi", "shichimi togarashi", "shichimi", "seven spice"],
  SPICE_DUKKAH: ["dukkah", "duqqa"],
  SPICE_RAS_EL_HANOUT: ["ras el hanout"],
  SPICE_OLD_BAY: ["old bay", "old bay seasoning"],
  SPICE_BERBERE: ["berbere", "berbere spice"],

  // ════════════════════════════════════════════════════════════
  // HERBS
  // ════════════════════════════════════════════════════════════

  HERB_BASIL: ["basil", "sweet basil", "fresh basil", "basil leaves"],
  HERB_THAI_BASIL: ["thai basil"],
  HERB_CILANTRO: ["cilantro", "coriander leaf", "coriander leaves", "fresh coriander", "chinese parsley", "cilantro leaves"],
  HERB_PARSLEY: ["parsley", "fresh parsley", "parsley leaves", "curly parsley"],
  HERB_FLAT_LEAF_PARSLEY: ["flat-leaf parsley", "flat leaf parsley", "italian parsley"],
  HERB_MINT: ["mint", "fresh mint", "mint leaves", "spearmint", "peppermint"],
  HERB_ROSEMARY: ["rosemary", "fresh rosemary", "rosemary sprig", "rosemary sprigs"],
  HERB_THYME: ["thyme", "fresh thyme", "thyme sprig", "thyme sprigs", "thyme leaves"],
  HERB_OREGANO: ["oregano", "dried oregano", "fresh oregano", "mexican oregano"],
  HERB_DILL: ["dill", "fresh dill", "dill weed", "dill fronds"],
  HERB_CHIVE: ["chive", "chives", "fresh chives"],
  HERB_SAGE: ["sage", "fresh sage", "sage leaves", "rubbed sage"],
  HERB_TARRAGON: ["tarragon", "fresh tarragon"],
  HERB_BAY_LEAF: ["bay leaf", "bay leaves", "laurel leaf", "dried bay leaf"],
  HERB_LEMONGRASS: ["lemongrass", "lemon grass", "lemongrass stalk", "lemongrass stalks"],
  HERB_CURRY_LEAF: ["curry leaf", "curry leaves", "fresh curry leaves", "kari patta"],
  HERB_KAFFIR_LIME_LEAF: ["kaffir lime leaf", "kaffir lime leaves", "makrut lime leaf", "makrut lime leaves", "lime leaf", "lime leaves"],
  HERB_PANDAN_LEAF: ["pandan leaf", "pandan leaves", "screwpine leaf", "pandan"],
  HERB_MARJORAM: ["marjoram", "sweet marjoram"],
  HERB_LAVENDER: ["lavender", "culinary lavender", "dried lavender"],
  HERB_SHISO: ["shiso", "shiso leaf", "perilla leaf", "japanese basil"],
  HERB_PERILLA: ["perilla", "perilla leaves", "korean perilla", "kkaennip"],
  HERB_VIETNAMESE_CORIANDER: ["vietnamese coriander", "rau ram", "laksa leaf"],
  HERB_SAVORY: ["savory", "summer savory", "winter savory"],
  HERB_EPAZOTE: ["epazote"],

  // ════════════════════════════════════════════════════════════
  // OILS & FATS
  // ════════════════════════════════════════════════════════════

  OIL_OLIVE: ["olive oil", "extra virgin olive oil", "extra-virgin olive oil", "evoo", "light olive oil", "pure olive oil"],
  OIL_VEGETABLE: ["vegetable oil", "cooking oil", "neutral oil"],
  OIL_CANOLA: ["canola oil", "rapeseed oil"],
  OIL_SUNFLOWER: ["sunflower oil"],
  OIL_PEANUT: ["peanut oil", "groundnut oil"],
  OIL_SESAME: ["sesame oil", "toasted sesame oil", "dark sesame oil"],
  OIL_COCONUT: ["coconut oil", "virgin coconut oil"],
  OIL_AVOCADO: ["avocado oil"],
  OIL_GRAPESEED: ["grapeseed oil", "grape seed oil"],
  OIL_CHILI: ["chili oil", "chilli oil", "hot chili oil", "la-yu", "rayu"],
  OIL_TRUFFLE: ["truffle oil", "white truffle oil", "black truffle oil"],
  OIL_LARD: ["lard", "pork fat", "pork lard", "rendered lard"],
  OIL_SHORTENING: ["shortening", "vegetable shortening", "crisco"],

  // ════════════════════════════════════════════════════════════
  // VINEGARS
  // ════════════════════════════════════════════════════════════

  VINEGAR_WHITE: ["white vinegar", "distilled white vinegar", "distilled vinegar", "vinegar"],
  VINEGAR_APPLE_CIDER: ["apple cider vinegar", "cider vinegar", "acv"],
  VINEGAR_RICE: ["rice vinegar", "rice wine vinegar", "seasoned rice vinegar"],
  VINEGAR_BALSAMIC: ["balsamic vinegar", "balsamic", "white balsamic vinegar"],
  VINEGAR_RED_WINE: ["red wine vinegar"],
  VINEGAR_WHITE_WINE: ["white wine vinegar"],
  VINEGAR_SHERRY: ["sherry vinegar"],
  VINEGAR_MALT: ["malt vinegar"],
  VINEGAR_BLACK: ["black vinegar", "chinese black vinegar", "chinkiang vinegar", "zhenjiang vinegar"],

  // ════════════════════════════════════════════════════════════
  // SAUCES & PASTES
  // ════════════════════════════════════════════════════════════

  SAUCE_SOY: ["soy sauce", "soya sauce", "shoyu"],
  SAUCE_LIGHT_SOY: ["light soy sauce", "thin soy sauce", "regular soy sauce", "usukuchi"],
  SAUCE_DARK_SOY: ["dark soy sauce", "thick soy sauce", "sweet soy sauce"],
  SAUCE_FISH: ["fish sauce", "nam pla", "nuoc mam", "patis"],
  SAUCE_OYSTER: ["oyster sauce"],
  SAUCE_HOISIN: ["hoisin sauce", "hoisin"],
  SAUCE_TERIYAKI: ["teriyaki sauce", "teriyaki"],
  SAUCE_WORCESTERSHIRE: ["worcestershire sauce", "worcestershire", "lea & perrins"],
  SAUCE_HOT: ["hot sauce", "pepper sauce", "louisiana hot sauce"],
  SAUCE_SRIRACHA: ["sriracha", "sriracha sauce", "rooster sauce"],
  SAUCE_TABASCO: ["tabasco", "tabasco sauce"],
  SAUCE_SAMBAL_OELEK: ["sambal oelek", "sambal olek", "sambal", "chili sambal"],
  SAUCE_SWEET_CHILI: ["sweet chili sauce", "sweet chilli sauce", "thai sweet chili"],
  SAUCE_TOMATO: ["tomato sauce", "passata"],
  SAUCE_MARINARA: ["marinara", "marinara sauce"],
  SAUCE_BBQ: ["bbq sauce", "barbecue sauce", "barbeque sauce"],
  SAUCE_TAHINI: ["tahini", "tahina", "sesame paste"],
  SAUCE_PESTO: ["pesto", "basil pesto", "pesto sauce"],
  SAUCE_MIRIN: ["mirin", "sweet rice wine", "rice wine for cooking"],
  SAUCE_SAKE: ["cooking sake", "cooking wine", "sake"],
  SAUCE_SHAOXING_WINE: ["shaoxing wine", "shaoxing", "chinese cooking wine", "chinese rice wine", "huangjiu"],
  SAUCE_COCONUT_AMINOS: ["coconut aminos"],
  SAUCE_TAMARI: ["tamari", "gluten-free soy sauce"],
  SAUCE_PONZU: ["ponzu", "ponzu sauce"],
  SAUCE_GOCHUJANG: ["gochujang", "korean chili paste", "korean red pepper paste"],
  SAUCE_DOENJANG: ["doenjang", "korean soybean paste", "dwenjang"],
  SAUCE_MISO_WHITE: ["white miso", "shiro miso", "sweet miso"],
  SAUCE_MISO_RED: ["red miso", "aka miso", "dark miso"],
  SAUCE_XO: ["xo sauce"],
  SAUCE_BLACK_BEAN: ["black bean sauce", "fermented black bean sauce", "black bean garlic sauce"],
  SAUCE_PLUM: ["plum sauce", "chinese plum sauce"],
  SAUCE_ENCHILADA: ["enchilada sauce", "red enchilada sauce"],
  SAUCE_CURRY_PASTE_RED: ["red curry paste", "thai red curry paste"],
  SAUCE_CURRY_PASTE_GREEN: ["green curry paste", "thai green curry paste"],
  SAUCE_CURRY_PASTE_YELLOW: ["yellow curry paste", "thai yellow curry paste"],
  SAUCE_TOM_YUM_PASTE: ["tom yum paste", "tom yam paste"],
  SAUCE_CHILI_GARLIC: ["chili garlic sauce", "chilli garlic sauce"],
  SAUCE_SALSA: ["salsa", "salsa verde", "pico de gallo"],

  // ════════════════════════════════════════════════════════════
  // CONDIMENTS
  // ════════════════════════════════════════════════════════════

  CONDIMENT_KETCHUP: ["ketchup", "catsup", "tomato ketchup"],
  CONDIMENT_MUSTARD: ["mustard", "prepared mustard"],
  CONDIMENT_DIJON_MUSTARD: ["dijon mustard", "dijon"],
  CONDIMENT_YELLOW_MUSTARD: ["yellow mustard", "american mustard", "french's mustard"],
  CONDIMENT_MAYONNAISE: ["mayonnaise", "mayo", "kewpie mayo", "japanese mayo", "kewpie mayonnaise"],
  CONDIMENT_RELISH: ["relish", "pickle relish", "sweet relish"],
  CONDIMENT_PICKLE: ["pickle", "pickles", "dill pickle", "dill pickles", "cornichon", "cornichons", "gherkin", "gherkins"],
  CONDIMENT_CAPER: ["caper", "capers"],
  CONDIMENT_BLACK_OLIVE: ["black olive", "black olives", "kalamata olive", "kalamata olives"],
  CONDIMENT_GREEN_OLIVE: ["green olive", "green olives", "castelvetrano olive", "manzanilla olive"],
  CONDIMENT_KIMCHI: ["kimchi", "kimchee"],
  CONDIMENT_SAUERKRAUT: ["sauerkraut"],
  CONDIMENT_HARISSA: ["harissa", "harissa paste"],
  CONDIMENT_TOMATO_PASTE: ["tomato paste", "tomato concentrate", "double concentrated tomato paste"],
  CONDIMENT_TOMATO_PUREE: ["tomato puree", "tomato purée", "crushed tomatoes", "strained tomatoes"],
  CONDIMENT_SUN_DRIED_TOMATO: ["sun-dried tomato", "sun dried tomato", "sun-dried tomatoes", "sun dried tomatoes", "sundried tomato"],
  CONDIMENT_MANGO_CHUTNEY: ["mango chutney", "chutney"],
  CONDIMENT_CHILI_PASTE: ["chili paste", "chilli paste", "red chili paste"],
  CONDIMENT_GARLIC_PASTE: ["garlic paste", "minced garlic"],
  CONDIMENT_GINGER_PASTE: ["ginger paste", "minced ginger"],
  CONDIMENT_ANCHOVY_PASTE: ["anchovy paste"],

  // ════════════════════════════════════════════════════════════
  // BAKING
  // ════════════════════════════════════════════════════════════

  // Flours
  BAKING_ALL_PURPOSE_FLOUR: ["all-purpose flour", "all purpose flour", "plain flour", "ap flour", "flour"],
  BAKING_BREAD_FLOUR: ["bread flour", "strong flour", "high-gluten flour"],
  BAKING_CAKE_FLOUR: ["cake flour", "soft flour"],
  BAKING_WHOLE_WHEAT_FLOUR: ["whole wheat flour", "wholemeal flour", "wholewheat flour", "whole grain flour"],
  BAKING_SELF_RISING_FLOUR: ["self-rising flour", "self rising flour", "self-raising flour", "self raising flour"],
  BAKING_RICE_FLOUR: ["rice flour"],
  BAKING_GLUTINOUS_RICE_FLOUR: ["glutinous rice flour", "sweet rice flour", "mochiko", "shiratamako"],
  BAKING_ALMOND_FLOUR: ["almond flour", "almond meal", "ground almond", "ground almonds"],
  BAKING_COCONUT_FLOUR: ["coconut flour"],
  BAKING_CHICKPEA_FLOUR: ["chickpea flour", "gram flour", "besan", "garbanzo flour"],

  // Starches
  BAKING_CORN_STARCH: ["corn starch", "cornstarch", "corn flour", "maize starch"],
  BAKING_TAPIOCA_STARCH: ["tapioca starch", "tapioca flour", "tapioca"],
  BAKING_POTATO_STARCH: ["potato starch", "potato flour"],
  BAKING_ARROWROOT: ["arrowroot", "arrowroot powder", "arrowroot starch"],

  // Sweeteners
  BAKING_SUGAR: ["sugar", "granulated sugar", "white sugar", "caster sugar", "castor sugar"],
  BAKING_BROWN_SUGAR: ["brown sugar", "light brown sugar", "dark brown sugar", "packed brown sugar", "demerara sugar", "turbinado sugar", "muscovado"],
  BAKING_POWDERED_SUGAR: ["powdered sugar", "confectioners sugar", "confectioner's sugar", "icing sugar"],
  BAKING_COCONUT_SUGAR: ["coconut sugar", "coconut palm sugar"],
  BAKING_PALM_SUGAR: ["palm sugar", "jaggery", "gula melaka", "gula jawa"],
  BAKING_HONEY: ["honey", "raw honey", "wildflower honey", "manuka honey"],
  BAKING_MAPLE_SYRUP: ["maple syrup", "pure maple syrup"],
  BAKING_MOLASSES: ["molasses", "blackstrap molasses", "treacle"],
  BAKING_AGAVE: ["agave", "agave nectar", "agave syrup"],
  BAKING_CORN_SYRUP: ["corn syrup", "light corn syrup", "dark corn syrup", "karo"],

  // Leavening
  BAKING_BAKING_POWDER: ["baking powder"],
  BAKING_BAKING_SODA: ["baking soda", "bicarbonate of soda", "bicarb", "sodium bicarbonate"],
  BAKING_YEAST: ["yeast", "active dry yeast", "instant yeast", "rapid rise yeast", "dry yeast", "fresh yeast"],
  BAKING_CREAM_OF_TARTAR: ["cream of tartar"],
  BAKING_GELATIN: ["gelatin", "gelatine", "gelatin sheet", "gelatin sheets", "gelatin powder", "unflavored gelatin"],
  BAKING_AGAR_AGAR: ["agar agar", "agar", "kanten"],

  // Extracts
  BAKING_VANILLA_EXTRACT: ["vanilla extract", "vanilla", "pure vanilla extract", "vanilla essence"],
  BAKING_ALMOND_EXTRACT: ["almond extract", "almond essence"],
  BAKING_PANDAN_EXTRACT: ["pandan extract", "pandan essence", "pandan paste"],
  BAKING_ROSE_WATER: ["rose water", "rosewater"],
  BAKING_ORANGE_BLOSSOM_WATER: ["orange blossom water", "orange flower water"],

  // Chocolate
  BAKING_COCOA_POWDER: ["cocoa powder", "unsweetened cocoa", "dutch process cocoa", "cocoa"],
  BAKING_DARK_CHOCOLATE: ["dark chocolate", "bittersweet chocolate", "semisweet chocolate", "semi-sweet chocolate"],
  BAKING_MILK_CHOCOLATE: ["milk chocolate"],
  BAKING_WHITE_CHOCOLATE: ["white chocolate"],
  BAKING_CHOCOLATE_CHIPS: ["chocolate chips", "chocolate morsels", "semi-sweet chocolate chips", "dark chocolate chips", "milk chocolate chips"],
  BAKING_COCONUT_FLAKES: ["coconut flakes", "desiccated coconut", "shredded coconut", "coconut shreds", "flaked coconut"],

  // ════════════════════════════════════════════════════════════
  // NUTS & SEEDS
  // ════════════════════════════════════════════════════════════

  NUT_ALMOND: ["almond", "almonds", "whole almond", "whole almonds", "sliced almond", "sliced almonds", "slivered almonds"],
  NUT_WALNUT: ["walnut", "walnuts", "walnut halves"],
  NUT_CASHEW: ["cashew", "cashews", "cashew nut", "cashew nuts"],
  NUT_PISTACHIO: ["pistachio", "pistachios", "pistachio nut"],
  NUT_PECAN: ["pecan", "pecans", "pecan halves"],
  NUT_MACADAMIA: ["macadamia", "macadamia nut", "macadamia nuts", "macadamias"],
  NUT_HAZELNUT: ["hazelnut", "hazelnuts", "filbert", "filberts"],
  NUT_PINE_NUT: ["pine nut", "pine nuts", "pignoli", "pignolia"],
  NUT_CHESTNUT: ["chestnut", "chestnuts", "roasted chestnut"],
  NUT_BRAZIL_NUT: ["brazil nut", "brazil nuts"],
  NUT_PEANUT: ["peanut", "peanuts", "groundnut", "groundnuts"],
  NUT_SUNFLOWER_SEED: ["sunflower seed", "sunflower seeds", "sunflower kernel"],
  NUT_PUMPKIN_SEED: ["pumpkin seed", "pumpkin seeds", "pepita", "pepitas"],
  NUT_SESAME_SEED: ["sesame seed", "sesame seeds", "white sesame seed", "toasted sesame seeds"],
  NUT_BLACK_SESAME_SEED: ["black sesame seed", "black sesame seeds", "kuro goma"],
  NUT_FLAX_SEED: ["flax seed", "flax seeds", "flaxseed", "linseed", "ground flax"],
  NUT_CHIA_SEED: ["chia seed", "chia seeds", "chia"],
  NUT_HEMP_SEED: ["hemp seed", "hemp seeds", "hemp hearts"],
  NUT_POPPY_SEED: ["poppy seed", "poppy seeds"],
  NUT_COCONUT_SHREDDED: ["coconut shredded", "dried coconut"],

  // ════════════════════════════════════════════════════════════
  // BEVERAGES & LIQUIDS
  // ════════════════════════════════════════════════════════════

  BEVERAGE_WATER: ["water", "cold water", "warm water", "hot water", "boiling water", "lukewarm water", "room temperature water", "filtered water", "tap water"],
  BEVERAGE_ICE: ["ice", "ice cubes"],
  BEVERAGE_COFFEE: ["coffee", "brewed coffee", "espresso", "strong coffee", "instant coffee"],
  BEVERAGE_TEA: ["tea", "black tea", "brewed tea", "tea leaves"],
  BEVERAGE_GREEN_TEA: ["green tea", "sencha"],
  BEVERAGE_MATCHA: ["matcha", "matcha powder", "matcha green tea"],
  BEVERAGE_RED_WINE: ["red wine", "dry red wine"],
  BEVERAGE_WHITE_WINE: ["white wine", "dry white wine"],
  BEVERAGE_BEER: ["beer", "lager", "ale", "stout"],
  BEVERAGE_CHICKEN_BROTH: ["chicken broth", "chicken stock", "chicken bouillon"],
  BEVERAGE_BEEF_BROTH: ["beef broth", "beef stock", "beef bouillon"],
  BEVERAGE_VEGETABLE_BROTH: ["vegetable broth", "vegetable stock", "veggie broth"],
  BEVERAGE_DASHI: ["dashi", "dashi stock", "dashi broth", "japanese fish stock"],
  BEVERAGE_COCONUT_WATER: ["coconut water", "coconut juice"],
  BEVERAGE_RICE_WINE: ["rice wine"],

  // ════════════════════════════════════════════════════════════
  // MISCELLANEOUS
  // ════════════════════════════════════════════════════════════

  MISC_TOFU: ["tofu", "bean curd"],
  MISC_SILKEN_TOFU: ["silken tofu", "soft tofu", "japanese tofu"],
  MISC_FIRM_TOFU: ["firm tofu", "regular tofu", "chinese tofu"],
  MISC_EXTRA_FIRM_TOFU: ["extra-firm tofu", "extra firm tofu", "pressed tofu"],
  MISC_TEMPEH: ["tempeh", "tempe"],
  MISC_SEITAN: ["seitan", "wheat gluten", "wheat meat"],
  MISC_NORI: ["nori", "nori sheet", "nori sheets", "seaweed sheet", "sushi nori", "roasted nori", "roasted seaweed"],
  MISC_KOMBU: ["kombu", "kelp", "dried kelp", "konbu"],
  MISC_WAKAME: ["wakame", "dried wakame", "wakame seaweed"],
  MISC_DRIED_SEAWEED: ["dried seaweed", "seaweed", "laver"],
  MISC_BONITO_FLAKES: ["bonito flakes", "katsuobushi", "dried bonito"],
  MISC_TAMARIND_PASTE: ["tamarind paste", "tamarind concentrate"],
  MISC_NUTRITIONAL_YEAST: ["nutritional yeast", "nooch"],
  MISC_LIQUID_SMOKE: ["liquid smoke"],
  MISC_BELACAN: ["belacan", "shrimp paste block", "blachan", "terasi", "trassi"],
  MISC_PEANUT_BUTTER: ["peanut butter", "creamy peanut butter", "crunchy peanut butter", "chunky peanut butter", "natural peanut butter"],
  MISC_ALMOND_BUTTER: ["almond butter"],
  MISC_TAHINI_PASTE: ["tahini paste"],
  MISC_BANANA_LEAF: ["banana leaf", "banana leaves"],

  // ════════════════════════════════════════════════════════════
  // EXPANSION — Asian Cuisine Focus + Global Coverage
  // ════════════════════════════════════════════════════════════

  // ── PRODUCE: Asian Greens & Vegetables ─────────────────────
  PRODUCE_GARLIC_CHIVES: ["garlic chives", "chinese chives", "nira", "ku chai", "buchu", "garlic chive"],
  PRODUCE_CHOY_SUM: ["choy sum", "choi sum", "cai xin", "chinese flowering cabbage", "yu cai"],
  PRODUCE_YU_CHOY: ["yu choy", "you choy", "yu choy sum", "oil vegetable"],
  PRODUCE_TATSOI: ["tatsoi", "tat soi", "rosette bok choy", "spoon mustard"],
  PRODUCE_CHRYSANTHEMUM_GREENS: ["chrysanthemum greens", "crown daisy", "ssukgat", "tong ho", "shungiku", "garland chrysanthemum"],
  PRODUCE_PEA_SHOOT: ["pea shoots", "pea shoot", "pea sprouts", "dou miao", "pea tips", "pea tendrils"],
  PRODUCE_CHINESE_SPINACH: ["chinese spinach", "amaranth greens", "red amaranth", "callaloo", "bayam"],
  PRODUCE_SAVOY_CABBAGE: ["savoy cabbage"],
  PRODUCE_ROMANESCO: ["romanesco", "romanesco broccoli", "roman cauliflower"],
  PRODUCE_TURNIP_GREENS: ["turnip greens", "turnip green", "turnip tops"],
  PRODUCE_RADISH_GREENS: ["radish greens", "radish tops", "radish leaves"],
  PRODUCE_BEET_GREENS: ["beet greens", "beetroot greens", "beet tops"],
  PRODUCE_CELERY_LEAF: ["celery leaf", "celery leaves"],
  PRODUCE_MICROGREENS: ["microgreens", "micro greens"],

  // ── PRODUCE: Asian Roots & Tubers ──────────────────────────
  PRODUCE_BURDOCK_ROOT: ["burdock root", "burdock", "gobo", "gobou", "arctium"],
  PRODUCE_CHINESE_YAM: ["chinese yam", "nagaimo", "yamaimo", "japanese mountain yam", "mountain yam", "dioscorea"],
  PRODUCE_PURPLE_YAM: ["purple yam", "ube", "ubi", "purple sweet potato"],
  PRODUCE_KOREAN_RADISH: ["korean radish", "mu", "moo", "korean daikon"],
  PRODUCE_JERUSALEM_ARTICHOKE: ["jerusalem artichoke", "sunchoke", "sunroot", "earth apple"],
  PRODUCE_LOTUS_STEM: ["lotus stem", "lotus stalk"],
  PRODUCE_BANANA_STEM: ["banana stem", "banana trunk", "banana stalk"],

  // ── PRODUCE: Asian Alliums ─────────────────────────────────
  PRODUCE_NEGI: ["negi", "japanese long onion", "japanese leek", "naga negi", "shiro negi"],
  PRODUCE_MYOGA: ["myoga", "myoga ginger", "japanese ginger bud"],
  PRODUCE_RAMP: ["ramp", "ramps", "wild leek", "wild leeks", "wild garlic"],

  // ── PRODUCE: Peppers ───────────────────────────────────────
  PRODUCE_SHISHITO: ["shishito", "shishito pepper", "shishito peppers"],
  PRODUCE_DRIED_CHILI: ["dried chili", "dried chilli", "dried chili pepper", "dried hot pepper", "whole dried chili"],
  PRODUCE_BANANA_PEPPER: ["banana pepper", "banana peppers", "yellow wax pepper"],
  PRODUCE_FRESNO_PEPPER: ["fresno pepper", "fresno chili", "fresno peppers"],

  // ── PRODUCE: Mushrooms ─────────────────────────────────────
  PRODUCE_DRIED_SHIITAKE: ["dried shiitake", "dried shiitake mushroom", "dried shiitake mushrooms", "dried chinese mushroom"],
  PRODUCE_SHIMEJI: ["shimeji", "shimeji mushroom", "shimeji mushrooms", "beech mushroom", "bunashimeji", "hon shimeji"],
  PRODUCE_NAMEKO: ["nameko", "nameko mushroom", "nameko mushrooms"],
  PRODUCE_MATSUTAKE: ["matsutake", "matsutake mushroom", "pine mushroom"],
  PRODUCE_SNOW_FUNGUS: ["snow fungus", "white fungus", "silver ear mushroom", "tremella", "white wood ear"],
  PRODUCE_STRAW_MUSHROOM: ["straw mushroom", "straw mushrooms", "paddy straw mushroom"],
  PRODUCE_DRIED_LILY_BUD: ["dried lily bud", "dried lily buds", "golden needle", "golden needles", "lily flower", "dried lily flower"],
  PRODUCE_MOREL: ["morel", "morel mushroom", "morels", "morel mushrooms"],
  PRODUCE_PORCINI: ["porcini", "porcini mushroom", "porcini mushrooms", "dried porcini", "cep", "king bolete"],
  PRODUCE_TRUFFLE: ["truffle", "black truffle", "white truffle", "truffle shavings"],

  // ── PRODUCE: Gourds & Beans ────────────────────────────────
  PRODUCE_WINGED_BEAN: ["winged bean", "winged beans", "goa bean", "princess bean", "four-angled bean"],
  PRODUCE_RIDGE_GOURD: ["ridge gourd", "ridged gourd", "turai", "tori", "luffa acutangula"],
  PRODUCE_BOTTLE_GOURD: ["bottle gourd", "calabash", "lauki", "dudhi", "long melon"],
  PRODUCE_IVY_GOURD: ["ivy gourd", "tindora", "tondli", "kundru"],
  PRODUCE_SNAKE_GOURD: ["snake gourd", "chichinda", "padwal"],
  PRODUCE_POINTED_GOURD: ["pointed gourd", "parwal", "parval", "potol"],
  PRODUCE_CLUSTER_BEAN: ["cluster bean", "guar bean", "gavar", "gawar"],
  PRODUCE_DRUMSTICK_VEGETABLE: ["drumstick", "moringa pod", "moringa", "sahjan"],
  PRODUCE_PENNYWORT: ["pennywort", "gotu kola", "asiatic pennywort", "pegaga", "rau ma"],
  PRODUCE_GREEN_PAPAYA: ["green papaya", "unripe papaya", "raw papaya"],
  PRODUCE_WATER_DROPWORT: ["water dropwort", "minari", "seri", "water celery", "korean water parsley"],
  PRODUCE_FIDDLEHEAD_FERN: ["fiddlehead fern", "fiddlehead", "fiddleheads", "gosari", "fernbrake"],
  PRODUCE_MORINGA_LEAF: ["moringa leaf", "moringa leaves", "drumstick leaves", "malunggay"],
  PRODUCE_TOMATILLO: ["tomatillo", "tomatillos", "mexican husk tomato", "tomate verde"],
  PRODUCE_NOPAL: ["nopal", "nopal cactus", "nopales", "cactus paddle", "prickly pear cactus"],

  // ── PRODUCE: Asian & Tropical Fruits ───────────────────────
  PRODUCE_RAMBUTAN: ["rambutan", "rambutans"],
  PRODUCE_MANGOSTEEN: ["mangosteen", "mangosteens"],
  PRODUCE_LONGAN: ["longan", "longans", "dragon eye", "fresh longan"],
  PRODUCE_SOURSOP: ["soursop", "guanabana", "graviola"],
  PRODUCE_BREADFRUIT: ["breadfruit", "bread fruit"],
  PRODUCE_JUJUBE: ["jujube", "jujubes", "chinese date", "chinese dates", "red date", "red dates", "dried jujube"],
  PRODUCE_GOJI_BERRY: ["goji berry", "goji berries", "wolfberry", "wolfberries", "dried goji berry", "lycium"],
  PRODUCE_ASIAN_PEAR: ["asian pear", "nashi", "nashi pear", "korean pear", "japanese pear"],
  PRODUCE_SAPODILLA: ["sapodilla", "chikoo", "chiku", "naseberry"],
  PRODUCE_CUSTARD_APPLE: ["custard apple", "cherimoya", "sugar apple", "sweetsop", "atemoya"],
  PRODUCE_SUGARCANE: ["sugarcane", "sugar cane"],

  // ── MEAT: Offal & Asian Cuts ───────────────────────────────
  MEAT_BEEF_FLANK: ["flank steak", "flank", "beef flank", "london broil"],
  MEAT_BEEF_SHANK: ["beef shank", "beef shin", "shin beef", "osso buco"],
  MEAT_OXTAIL: ["oxtail", "ox tail", "oxtails"],
  MEAT_BEEF_TONGUE: ["beef tongue", "ox tongue", "lengua"],
  MEAT_BEEF_RIB: ["beef rib", "beef ribs", "bone-in rib", "standing rib"],
  MEAT_TRIPE: ["tripe", "beef tripe", "honeycomb tripe", "book tripe"],
  MEAT_PORK_LIVER: ["pork liver", "pig liver"],
  MEAT_PORK_HOCK: ["pork hock", "pork knuckle", "ham hock", "pork shank"],
  MEAT_PORK_EAR: ["pork ear", "pork ears", "pig ear"],
  MEAT_CHINESE_SAUSAGE: ["chinese sausage", "lap cheong", "lap cheung", "lop cheung", "lup cheong"],
  MEAT_CURED_PORK_BELLY: ["cured pork belly", "chinese cured pork", "la rou", "chinese bacon"],
  MEAT_BLOOD_SAUSAGE: ["blood sausage", "black pudding", "morcilla", "boudin noir"],
  MEAT_GROUND_VEAL: ["ground veal", "veal mince", "minced veal"],
  MEAT_HOTDOG: ["hot dog", "hotdog", "frankfurter", "wiener", "vienna sausage"],
  MEAT_ANDOUILLE: ["andouille", "andouille sausage"],
  MEAT_KIELBASA: ["kielbasa", "polish sausage", "kolbasz"],
  MEAT_MORTADELLA: ["mortadella", "bologna"],
  MEAT_PEPPERONI: ["pepperoni"],
  MEAT_BRESAOLA: ["bresaola"],

  // ── POULTRY: Asian Cuts ────────────────────────────────────
  POULTRY_CHICKEN_FEET: ["chicken feet", "chicken foot", "chicken paws"],
  POULTRY_CHICKEN_GIZZARD: ["chicken gizzard", "chicken gizzards", "gizzard"],
  POULTRY_CHICKEN_HEART: ["chicken heart", "chicken hearts"],
  POULTRY_DUCK_LEG: ["duck leg", "duck legs", "duck drumstick"],
  POULTRY_TURKEY_BREAST: ["turkey breast", "turkey cutlet"],
  POULTRY_CHICKEN_SKIN: ["chicken skin"],
  POULTRY_CHICKEN_LEG_QUARTER: ["chicken leg quarter", "chicken quarter", "chicken maryland"],
  POULTRY_DUCK_CONFIT: ["duck confit", "confit de canard"],

  // ── SEAFOOD: Japanese ──────────────────────────────────────
  SEAFOOD_EEL: ["eel", "unagi", "freshwater eel"],
  SEAFOOD_CONGER_EEL: ["conger eel", "anago", "sea eel"],
  SEAFOOD_SEA_BREAM: ["sea bream", "tai", "madai", "red sea bream", "dorade"],
  SEAFOOD_YELLOWTAIL: ["yellowtail", "hamachi", "buri", "yellowtail fish", "amberjack"],
  SEAFOOD_WHITEBAIT: ["whitebait", "shirasu", "ikan bilis kecil"],
  SEAFOOD_TOBIKO: ["tobiko", "flying fish roe"],
  SEAFOOD_SALMON_ROE: ["salmon roe", "ikura", "red caviar"],
  SEAFOOD_MENTAIKO: ["mentaiko", "pollock roe", "mentai", "tarako", "spicy cod roe"],
  SEAFOOD_SKIPJACK_TUNA: ["skipjack tuna", "skipjack", "katsuo"],
  SEAFOOD_BONITO: ["bonito", "bonito fish"],

  // ── SEAFOOD: Chinese / Korean / SE Asian ───────────────────
  SEAFOOD_DRIED_SCALLOP: ["dried scallop", "dried scallops", "conpoy", "dried conpoy"],
  SEAFOOD_SEA_CUCUMBER: ["sea cucumber", "sea cucumbers", "bêche-de-mer", "hai shen"],
  SEAFOOD_JELLYFISH: ["jellyfish", "dried jellyfish", "jellyfish salad"],
  SEAFOOD_FISH_MAW: ["fish maw", "dried fish maw", "swim bladder"],
  SEAFOOD_DRIED_SQUID: ["dried squid", "dried cuttlefish"],
  SEAFOOD_RAZOR_CLAM: ["razor clam", "razor clams", "razor shell"],
  SEAFOOD_COCKLE: ["cockle", "cockles", "blood cockle", "blood clam"],
  SEAFOOD_MANTIS_SHRIMP: ["mantis shrimp", "mantis prawn"],
  SEAFOOD_WHELK: ["whelk", "whelks", "sea snail"],

  // ── SEAFOOD: Global ────────────────────────────────────────
  SEAFOOD_TURBOT: ["turbot"],
  SEAFOOD_MONKFISH: ["monkfish", "anglerfish", "goosefish"],
  SEAFOOD_PERCH: ["perch", "yellow perch", "ocean perch"],
  SEAFOOD_SMELT: ["smelt", "smelts", "rainbow smelt"],
  SEAFOOD_BASA: ["basa", "basa fish", "pangasius", "swai"],
  SEAFOOD_GEODUCK: ["geoduck", "geoduck clam"],
  SEAFOOD_SNOW_CRAB: ["snow crab", "snow crab legs"],
  SEAFOOD_KING_CRAB: ["king crab", "king crab legs", "alaskan king crab"],
  SEAFOOD_SOFT_SHELL_CRAB: ["soft-shell crab", "soft shell crab", "softshell crab"],
  SEAFOOD_LANGOUSTINE: ["langoustine", "langoustines", "dublin bay prawn", "scampi"],
  SEAFOOD_SKATE: ["skate", "skate wing"],

  // ── DAIRY: Asian Eggs & Cheese ─────────────────────────────
  DAIRY_CENTURY_EGG: ["century egg", "century eggs", "preserved egg", "thousand-year egg", "pidan", "pi dan"],
  DAIRY_SALTED_EGG: ["salted egg", "salted eggs", "salted duck egg", "salted duck eggs"],
  DAIRY_COCONUT_YOGURT: ["coconut yogurt", "coconut yoghurt"],
  DAIRY_LABNEH: ["labneh", "labne", "labna", "strained yogurt cheese"],
  DAIRY_CLOTTED_CREAM: ["clotted cream", "devonshire cream"],
  DAIRY_PROVOLONE: ["provolone", "provolone cheese"],
  DAIRY_HAVARTI: ["havarti", "havarti cheese"],
  DAIRY_HALLOUMI: ["halloumi", "haloumi", "hallumi", "grilling cheese"],
  DAIRY_BURRATA: ["burrata", "burrata cheese"],
  DAIRY_CAMEMBERT: ["camembert", "camembert cheese"],
  DAIRY_MANCHEGO: ["manchego", "manchego cheese"],
  DAIRY_QUESO_FRESCO: ["queso fresco", "fresh mexican cheese"],
  DAIRY_CREME_FRAICHE: ["creme fraiche", "crème fraîche"],
  DAIRY_KEFIR: ["kefir", "milk kefir"],
  DAIRY_FROMAGE_BLANC: ["fromage blanc", "fromage frais"],

  // ── GRAINS: Asian Noodles ──────────────────────────────────
  GRAIN_SOMEN: ["somen", "somen noodle", "somen noodles", "soumen", "thin japanese noodle"],
  GRAIN_SHIRATAKI: ["shirataki", "shirataki noodle", "shirataki noodles", "konnyaku noodle", "miracle noodle", "zero calorie noodle"],
  GRAIN_SWEET_POTATO_NOODLE: ["sweet potato noodle", "sweet potato noodles", "japchae noodle", "dang myeon", "dangmyeon", "korean glass noodle"],
  GRAIN_NAENGMYEON: ["naengmyeon", "naengmyeon noodle", "cold buckwheat noodle", "mul naengmyeon"],
  GRAIN_MISUA: ["misua", "mi sua", "wheat vermicelli", "mee sua"],
  GRAIN_LAKSA_NOODLE: ["laksa noodle", "laksa noodles", "thick rice noodle"],
  GRAIN_FLAT_WHEAT_NOODLE: ["flat wheat noodle", "flat wheat noodles", "knife-cut noodle", "dao xiao mian", "biang biang noodle"],
  GRAIN_KALGUKSU: ["kalguksu", "kalguksu noodle", "korean knife-cut noodle"],
  GRAIN_INSTANT_NOODLE: ["instant noodle", "instant noodles", "instant ramen", "cup noodle"],
  GRAIN_RICE_CAKE_SHEET: ["fresh rice noodle sheet", "cheung fun", "chee cheong fun", "rice roll sheet"],

  // ── GRAINS: Asian Rice Products ────────────────────────────
  GRAIN_MOCHI: ["mochi", "mochi rice cake", "japanese rice cake", "kirimochi"],
  GRAIN_TTEOK: ["tteok", "rice cake", "korean rice cake", "garaetteok", "tteokbokki rice cake"],
  GRAIN_BLACK_RICE: ["black rice", "forbidden rice", "black glutinous rice"],
  GRAIN_RED_RICE: ["red rice", "bhutanese red rice", "himalayan red rice"],

  // ── GRAINS: Bread & Dough ──────────────────────────────────
  GRAIN_PUFF_PASTRY: ["puff pastry", "puff pastry sheet", "puff pastry sheets"],
  GRAIN_ROTI: ["roti", "roti canai", "roti prata", "flatbread"],
  GRAIN_MANTOU: ["mantou", "chinese steamed bun", "steamed bun"],
  GRAIN_BAO_BUN: ["bao bun", "bao", "gua bao", "steamed bao", "lotus bun"],
  GRAIN_CHAPATI: ["chapati", "chapatti", "roti chapati"],
  GRAIN_PARATHA: ["paratha", "parata", "parantha", "stuffed paratha"],
  GRAIN_LAVASH: ["lavash", "lavash bread"],
  GRAIN_PAPPADAM: ["papadum", "papad", "pappadam", "poppadom", "poppadum"],
  GRAIN_INJERA: ["injera", "ethiopian bread"],
  GRAIN_PRAWN_CRACKER: ["prawn cracker", "prawn crackers", "shrimp cracker", "shrimp crackers", "kerupuk", "krupuk"],
  GRAIN_CORN_TORTILLA: ["corn tortilla", "corn tortillas"],
  GRAIN_TACO_SHELL: ["taco shell", "taco shells", "hard taco shell"],
  GRAIN_IDLI: ["idli", "idlis", "idly"],
  GRAIN_DOSA: ["dosa", "dosai", "thosai"],
  GRAIN_CROISSANT: ["croissant", "croissants"],
  GRAIN_BRIOCHE: ["brioche", "brioche bread", "brioche bun"],
  GRAIN_ENGLISH_MUFFIN: ["english muffin", "english muffins"],
  GRAIN_BAGEL: ["bagel", "bagels"],
  GRAIN_AMARANTH: ["amaranth", "amaranth grain"],
  GRAIN_TEFF: ["teff", "teff grain", "teff flour"],

  // ── LEGUMES: South & East Asian ────────────────────────────
  LEGUME_URAD_DAL: ["urad dal", "urad dhal", "black gram", "urid dal", "black lentil dal"],
  LEGUME_TOOR_DAL: ["toor dal", "toor dhal", "split pigeon pea", "arhar dal", "tur dal"],
  LEGUME_CHANA_DAL: ["chana dal", "chana dhal", "split chickpea", "bengal gram"],
  LEGUME_PIGEON_PEA: ["pigeon pea", "pigeon peas", "gungo pea"],
  LEGUME_RED_BEAN_PASTE: ["red bean paste", "anko", "azuki paste", "sweet red bean paste", "tsubuan", "koshian"],
  LEGUME_YELLOW_LENTIL: ["yellow lentil", "yellow lentils", "moong dal", "yellow dal"],
  LEGUME_BLACK_LENTIL: ["black lentil", "black lentils", "beluga lentil", "urad whole"],
  LEGUME_DAL: ["dal", "dhal", "daal", "lentil soup"],

  // ── SPICES: Korean ─────────────────────────────────────────
  SPICE_GOCHUGARU: ["gochugaru", "korean chili flakes", "korean red pepper flakes", "korean pepper flakes"],
  SPICE_KOREAN_CHILI_POWDER: ["korean chili powder", "korean red pepper powder", "gochu garu powder"],

  // ── SPICES: Japanese ───────────────────────────────────────
  SPICE_SANSHO: ["sansho", "sansho pepper", "japanese pepper", "japanese peppercorn"],
  SPICE_FURIKAKE: ["furikake", "rice seasoning", "japanese rice seasoning"],
  SPICE_DASHI_POWDER: ["dashi powder", "hondashi", "dashi granules", "bonito powder", "instant dashi"],

  // ── SPICES: Chinese ────────────────────────────────────────
  SPICE_DRIED_TANGERINE_PEEL: ["dried tangerine peel", "chen pi", "chenpi", "dried mandarin peel", "dried orange peel"],
  SPICE_DRIED_RED_CHILI: ["dried red chili", "dried red chilies", "whole dried red chili", "dried red pepper"],
  SPICE_BLACK_CARDAMOM: ["black cardamom", "black cardamom pod", "tsao kuo", "cao guo"],
  SPICE_LONG_PEPPER: ["long pepper", "pippali", "indian long pepper"],

  // ── SPICES: Southeast Asian ────────────────────────────────
  SPICE_GALANGAL_POWDER: ["galangal powder", "ground galangal", "laos powder"],
  SPICE_LEMONGRASS_POWDER: ["lemongrass powder", "ground lemongrass", "dried lemongrass"],
  SPICE_TOASTED_RICE_POWDER: ["toasted rice powder", "khao kua", "roasted rice powder"],
  SPICE_CANDLENUT: ["candlenut", "kemiri", "candlenuts", "buah keras"],
  SPICE_KENCUR: ["kencur", "lesser galangal", "aromatic ginger", "kentjur", "cekur"],
  SPICE_PANDAN_POWDER: ["pandan powder", "pandan leaf powder"],
  SPICE_DRIED_SHRIMP_POWDER: ["dried shrimp powder", "shrimp powder", "prawn powder"],

  // ── SPICES: South Asian ────────────────────────────────────
  SPICE_NIGELLA_SEED: ["nigella seed", "nigella seeds", "kalonji", "black cumin", "black onion seed"],
  SPICE_AJWAIN: ["ajwain", "carom seed", "carom seeds", "bishop's weed", "ajwain seed"],
  SPICE_AMCHUR: ["amchur", "amchoor", "dried mango powder", "mango powder"],
  SPICE_CHAT_MASALA: ["chaat masala", "chat masala"],
  SPICE_TAMARIND_POWDER: ["tamarind powder", "dried tamarind"],

  // ── SPICES: Global ─────────────────────────────────────────
  SPICE_GRAINS_OF_PARADISE: ["grains of paradise", "melegueta pepper", "alligator pepper"],
  SPICE_PINK_PEPPER: ["pink pepper", "pink peppercorn", "pink peppercorns"],
  SPICE_DRIED_BASIL: ["dried basil"],
  SPICE_DRIED_THYME: ["dried thyme"],
  SPICE_DRIED_ROSEMARY: ["dried rosemary"],
  SPICE_DRIED_PARSLEY: ["dried parsley"],
  SPICE_CHILI_DE_ARBOL: ["chile de arbol", "chili de arbol", "chile de árbol", "arbol chili"],
  SPICE_ANCHO_CHILI: ["ancho chili", "ancho chile", "ancho pepper", "dried poblano"],
  SPICE_GUAJILLO_CHILI: ["guajillo chili", "guajillo chile", "guajillo pepper"],
  SPICE_PASILLA_CHILI: ["pasilla chili", "pasilla chile", "chile negro"],

  // ── HERBS: Asian ───────────────────────────────────────────
  HERB_HOLY_BASIL: ["holy basil", "tulsi", "krapao", "ka prao"],
  HERB_LEMON_BASIL: ["lemon basil", "hoary basil", "kemangi"],
  HERB_SAWTOOTH_CORIANDER: ["sawtooth coriander", "culantro", "mexican coriander", "ngo gai", "sawtooth herb", "eryngium", "recao", "shadow beni"],
  HERB_BETEL_LEAF: ["betel leaf", "la lot", "betel leaves", "piper lolot", "wild betel"],
  HERB_MITSUBA: ["mitsuba", "japanese parsley", "japanese wild parsley", "trefoil"],
  HERB_KINOME: ["kinome", "sansho leaf", "sansho leaves"],
  HERB_RICE_PADDY_HERB: ["rice paddy herb", "ngo om", "rau om"],
  HERB_VIETNAMESE_BALM: ["vietnamese balm", "kinh gioi", "vietnamese lemon balm"],
  HERB_INDONESIAN_BAY_LEAF: ["indonesian bay leaf", "daun salam", "salam leaf", "salam leaves"],
  HERB_TURMERIC_LEAF: ["turmeric leaf", "turmeric leaves", "daun kunyit"],
  HERB_MUGWORT: ["mugwort", "yomogi", "ssuk", "artemisia"],

  // ── HERBS: Global ──────────────────────────────────────────
  HERB_CHERVIL: ["chervil", "french parsley"],
  HERB_SORREL: ["sorrel", "garden sorrel", "common sorrel"],
  HERB_LEMON_VERBENA: ["lemon verbena", "verbena"],

  // ── OILS: Asian & Global ───────────────────────────────────
  OIL_PERILLA: ["perilla oil", "perilla seed oil", "deulkkae oil"],
  OIL_RICE_BRAN: ["rice bran oil"],
  OIL_SICHUAN_PEPPERCORN: ["sichuan peppercorn oil", "szechuan peppercorn oil", "sichuan pepper oil", "mala oil"],
  OIL_SCALLION: ["scallion oil", "green onion oil"],
  OIL_GARLIC: ["garlic oil", "garlic infused oil"],
  OIL_CORN: ["corn oil"],
  OIL_SAFFLOWER: ["safflower oil"],

  // ── VINEGARS ───────────────────────────────────────────────
  VINEGAR_COCONUT: ["coconut vinegar"],
  VINEGAR_SUSHI: ["sushi vinegar", "seasoned sushi vinegar", "sushizu"],
  VINEGAR_PALM: ["palm vinegar"],

  // ── SAUCES: Chinese ────────────────────────────────────────
  SAUCE_DOUBANJIANG: ["doubanjiang", "dou ban jiang", "chili bean paste", "broad bean chili paste", "pixian doubanjiang", "toban djan"],
  SAUCE_TIAN_MIAN_JIANG: ["tian mian jiang", "sweet bean sauce", "sweet bean paste", "sweet wheat paste", "tian mian"],
  SAUCE_CHAR_SIU: ["char siu sauce", "chinese bbq sauce", "cha siu sauce"],
  SAUCE_SHA_CHA: ["sha cha sauce", "shacha sauce", "sa cha sauce", "chinese bbq paste"],
  SAUCE_CHU_HOU_PASTE: ["chu hou paste", "chu hou sauce", "zhu hou sauce"],
  SAUCE_FERMENTED_BEAN_CURD: ["fermented bean curd", "fermented tofu", "fu ru", "furu", "preserved tofu", "tofu cheese", "sufu"],
  SAUCE_CHILI_CRISP: ["chili crisp", "chilli crisp", "lao gan ma", "crunchy chili oil", "crispy chili oil"],
  SAUCE_YELLOW_BEAN_SAUCE: ["yellow bean sauce", "yellow bean paste", "soybean paste"],
  SAUCE_SCALLION_OIL: ["scallion oil sauce", "spring onion oil", "green onion oil sauce", "cong you"],

  // ── SAUCES: Japanese ───────────────────────────────────────
  SAUCE_KECAP_MANIS: ["kecap manis", "ketjap manis", "indonesian sweet soy sauce", "indonesian soy sauce"],
  SAUCE_YUZU_KOSHO: ["yuzu kosho", "yuzu pepper paste", "yuzu koshou"],
  SAUCE_TONKATSU_SAUCE: ["tonkatsu sauce", "japanese brown sauce", "katsu sauce"],
  SAUCE_OKONOMIYAKI_SAUCE: ["okonomiyaki sauce"],
  SAUCE_MENTSUYU: ["mentsuyu", "tsuyu", "noodle dipping sauce", "soba tsuyu"],
  SAUCE_UNAGI_SAUCE: ["unagi sauce", "eel sauce", "kabayaki sauce", "nitsume"],
  SAUCE_JAPANESE_CURRY_ROUX: ["japanese curry roux", "curry roux", "japanese curry block"],
  SAUCE_TARE: ["tare", "yakitori tare", "grilling sauce"],

  // ── SAUCES: Korean ─────────────────────────────────────────
  SAUCE_SSAMJANG: ["ssamjang", "ssam sauce", "korean dipping paste"],
  SAUCE_CHOGOCHUJANG: ["chogochujang", "cho gochujang", "vinegar gochujang"],
  SAUCE_KOREAN_BBQ_SAUCE: ["korean bbq sauce", "bulgogi sauce", "bulgogi marinade", "kalbi sauce", "galbi sauce"],

  // ── SAUCES: Thai / Vietnamese / SE Asian ───────────────────
  SAUCE_NUOC_CHAM: ["nuoc cham", "vietnamese dipping sauce", "nuoc mam cham"],
  SAUCE_NAM_JIM: ["nam jim", "nam jim jaew"],
  SAUCE_PRIK_NAM_PLA: ["prik nam pla", "fish sauce chili"],
  SAUCE_THAI_CHILI_JAM: ["thai chili jam", "nam prik pao", "roasted chili paste", "chili jam"],
  SAUCE_LAKSA_PASTE: ["laksa paste"],
  SAUCE_RENDANG_PASTE: ["rendang paste", "rendang spice paste"],
  SAUCE_SATAY_SAUCE: ["satay sauce", "peanut sauce", "sate sauce"],
  SAUCE_MASSAMAN_PASTE: ["massaman curry paste", "massaman paste"],
  SAUCE_PANANG_PASTE: ["panang curry paste", "panang paste", "panaeng curry paste"],
  SAUCE_PAD_THAI_SAUCE: ["pad thai sauce"],
  SAUCE_NAM_PRIK: ["nam prik", "thai chili dip", "thai relish"],

  // ── SAUCES: Global ─────────────────────────────────────────
  SAUCE_SOFRITO: ["sofrito", "recaito"],
  SAUCE_ALFREDO: ["alfredo sauce", "alfredo"],
  SAUCE_ADOBO_SAUCE: ["adobo sauce", "adobo", "chipotle in adobo"],
  SAUCE_GRAVY: ["gravy", "brown gravy", "turkey gravy", "chicken gravy"],
  SAUCE_CRANBERRY_SAUCE: ["cranberry sauce"],
  SAUCE_APPLE_SAUCE: ["apple sauce", "applesauce"],
  SAUCE_MINT_SAUCE: ["mint sauce", "mint jelly"],
  SAUCE_GREEN_SAUCE: ["green sauce", "green herb sauce"],

  // ── CONDIMENTS: Japanese ───────────────────────────────────
  CONDIMENT_PICKLED_GINGER: ["pickled ginger", "gari", "sushi ginger"],
  CONDIMENT_UMEBOSHI: ["umeboshi", "pickled plum", "japanese pickled plum", "ume"],
  CONDIMENT_FUKUJINZUKE: ["fukujinzuke", "fukujin pickles"],
  CONDIMENT_TAKUAN: ["takuan", "takuwan", "pickled daikon", "yellow pickled radish"],
  CONDIMENT_BENI_SHOGA: ["beni shoga", "red pickled ginger"],
  CONDIMENT_RAKKYO: ["rakkyo", "pickled rakkyo", "japanese pickled scallion", "pickled shallot"],
  CONDIMENT_NORI_FLAKES: ["nori flakes", "kizami nori", "shredded nori"],
  CONDIMENT_MENMA: ["menma", "seasoned bamboo shoot", "ramen bamboo", "shinachiku"],

  // ── CONDIMENTS: Chinese ────────────────────────────────────
  CONDIMENT_FERMENTED_BLACK_BEAN: ["fermented black bean", "fermented black beans", "douchi", "salted black bean", "preserved black bean"],
  CONDIMENT_PRESERVED_MUSTARD: ["preserved mustard greens", "zha cai", "zhacai", "sichuan preserved vegetable"],
  CONDIMENT_PICKLED_MUSTARD_GREEN: ["pickled mustard green", "pickled mustard greens", "suan cai", "chinese sauerkraut"],
  CONDIMENT_PICKLED_GARLIC: ["pickled garlic"],
  CONDIMENT_PICKLED_CABBAGE: ["pickled cabbage", "chinese pickled cabbage", "pickled napa cabbage"],
  CONDIMENT_CRISPY_SHALLOT: ["crispy fried shallots", "fried shallots", "crispy shallots", "bawang goreng"],
  CONDIMENT_CRISPY_GARLIC: ["crispy fried garlic", "fried garlic", "crispy garlic", "garlic chips"],

  // ── CONDIMENTS: Korean ─────────────────────────────────────
  CONDIMENT_DANMUJI: ["danmuji", "korean pickled radish", "korean yellow radish"],

  // ── CONDIMENTS: SE Asian / Global ──────────────────────────
  CONDIMENT_ACHAR: ["achar", "achaar", "asian pickle", "south asian pickle", "indian pickle"],
  CONDIMENT_SAMBAL_MATAH: ["sambal matah", "balinese sambal"],
  CONDIMENT_AJVAR: ["ajvar"],
  CONDIMENT_PICKLED_JALAPENO: ["pickled jalapeno", "pickled jalapeño", "pickled jalapenos"],
  CONDIMENT_PICKLED_RED_ONION: ["pickled red onion", "pickled red onions"],
  CONDIMENT_ROASTED_RED_PEPPER: ["roasted red pepper", "roasted red peppers", "roasted capsicum", "jarred red pepper"],

  // ── BAKING: Asian ──────────────────────────────────────────
  BAKING_ROCK_SUGAR: ["rock sugar", "rock candy", "bing tang", "chinese rock sugar"],
  BAKING_MALTOSE: ["maltose", "malt sugar", "rice malt", "malt syrup"],
  BAKING_RICE_SYRUP: ["rice syrup", "brown rice syrup"],
  BAKING_KINAKO: ["kinako", "roasted soybean flour", "soybean flour", "roasted soy flour"],
  BAKING_SWEET_POTATO_STARCH: ["sweet potato starch", "sweet potato flour"],
  BAKING_MUNG_BEAN_STARCH: ["mung bean starch", "mung bean flour", "green bean starch"],
  BAKING_WHEAT_STARCH: ["wheat starch", "tang flour", "tang mein flour", "non-gluten wheat starch"],
  BAKING_GOLDEN_SYRUP: ["golden syrup"],
  BAKING_BLACK_SESAME_POWDER: ["black sesame powder", "ground black sesame"],

  // ── NUTS & SEEDS: Asian ────────────────────────────────────
  NUT_GINKGO: ["ginkgo nut", "ginkgo nuts", "gingko nut", "ginnan"],
  NUT_LOTUS_SEED: ["lotus seed", "lotus seeds", "dried lotus seed"],
  NUT_CANDIED_WALNUT: ["candied walnut", "candied walnuts", "glazed walnut"],
  NUT_ROASTED_PEANUT: ["roasted peanut", "roasted peanuts", "dry roasted peanut"],
  NUT_WATERMELON_SEED: ["watermelon seed", "watermelon seeds"],

  // ── BEVERAGES: Asian ───────────────────────────────────────
  BEVERAGE_BARLEY_TEA: ["barley tea", "mugicha", "boricha", "roasted barley tea"],
  BEVERAGE_CORN_TEA: ["corn tea", "oksusu-cha", "corn silk tea"],
  BEVERAGE_HOJICHA: ["hojicha", "roasted green tea", "houjicha"],
  BEVERAGE_OOLONG_TEA: ["oolong tea", "oolong", "wulong tea"],
  BEVERAGE_JASMINE_TEA: ["jasmine tea"],
  BEVERAGE_CHAI: ["chai", "chai tea", "masala chai"],
  BEVERAGE_SOJU: ["soju", "korean soju"],
  BEVERAGE_SHOCHU: ["shochu", "japanese shochu"],
  BEVERAGE_AMAZAKE: ["amazake", "sweet sake", "rice amazake"],
  BEVERAGE_BONE_BROTH: ["bone broth", "pork bone broth", "tonkotsu broth"],
  BEVERAGE_PORK_BROTH: ["pork broth", "pork stock"],
  BEVERAGE_MUSHROOM_BROTH: ["mushroom broth", "mushroom stock"],
  BEVERAGE_KELP_BROTH: ["kelp broth", "kombu broth", "kombu dashi", "kelp stock"],
  BEVERAGE_ANCHOVY_BROTH: ["anchovy broth", "anchovy stock", "myeolchi broth", "anchovy dashi"],
  BEVERAGE_SPARKLING_WATER: ["sparkling water", "soda water", "carbonated water", "seltzer"],
  BEVERAGE_CLAM_JUICE: ["clam juice", "clam broth"],

  // ── MISC: Japanese ─────────────────────────────────────────
  MISC_NATTO: ["natto", "fermented soybean", "fermented soybeans"],
  MISC_TOFU_SKIN: ["tofu skin", "yuba", "bean curd skin", "bean curd sheet", "fuzhu", "dried tofu skin"],
  MISC_FRIED_TOFU: ["fried tofu", "aburaage", "aburage", "age", "fried bean curd"],
  MISC_TOFU_PUFF: ["tofu puff", "tofu puffs", "fried tofu puff", "tau pok", "tau kwa pok"],
  MISC_KONJAC: ["konjac", "konnyaku", "konjac jelly", "devil's tongue"],
  MISC_KOJI: ["koji", "rice koji", "shio koji", "koji rice"],
  MISC_TENKASU: ["tenkasu", "tempura flakes", "agedama", "tempura bits", "tempura crumbs"],
  MISC_SAKE_KASU: ["sake kasu", "sake lees", "sake cake"],

  // ── MISC: Chinese & General ────────────────────────────────
  MISC_BLACK_SESAME_PASTE: ["black sesame paste", "black sesame butter"],
  MISC_FISH_TOFU: ["fish tofu"],
  MISC_BLACK_MOSS: ["black moss", "fat choy", "fat choi", "hair vegetable"],
  MISC_DRIED_PERSIMMON: ["dried persimmon", "hoshigaki", "gotgam"],
  MISC_DRIED_LONGAN: ["dried longan", "dried longans", "longan meat"],
  MISC_TAPIOCA_PEARL: ["tapioca pearl", "tapioca pearls", "boba", "sago", "tapioca balls"],
  MISC_FRIED_ONION: ["crispy fried onions", "fried onions", "french fried onions", "bawang merah goreng"],
  MISC_COCONUT_CREAM_POWDER: ["coconut cream powder", "coconut milk powder", "desiccated coconut cream"],
  MISC_MALT_EXTRACT: ["malt extract"],
  MISC_YEAST_EXTRACT: ["yeast extract", "marmite", "vegemite"],

  // ── Final fill to 1,000 ────────────────────────────────────
  PRODUCE_KANGKONG: ["kangkong greens", "kangkung water spinach", "water morning glory"],
  PRODUCE_BANANA_LEAF_FRESH: ["fresh banana leaf", "fresh banana leaves"],
  PRODUCE_YOUNG_COCONUT: ["young coconut", "green coconut", "buko"],
  PRODUCE_TORCH_GINGER: ["torch ginger", "torch ginger flower", "bunga kantan", "ginger flower"],
  PRODUCE_TURMERIC_FLOWER: ["turmeric flower", "turmeric bud"],
  PRODUCE_LONG_EGGPLANT: ["long eggplant", "asian long eggplant"],
  PRODUCE_BABY_BOK_CHOY: ["baby bok choy head", "baby pak choi head", "shanghai bok choy"],
  PRODUCE_ENOKI_FRESH: ["fresh enoki", "fresh enoki mushroom"],
  PRODUCE_DAIKON_SPROUT: ["daikon sprout", "daikon sprouts", "kaiware"],
  CONDIMENT_SSAM_LETTUCE: ["ssam lettuce", "ssam leaves", "wrapping lettuce"],
  SPICE_PERILLA_POWDER: ["perilla powder", "perilla seed powder", "deulkkae powder"],
  SAUCE_MAKGEOLLI: ["makgeolli", "korean rice wine", "makkoli"],
  MISC_UMEBOSHI_PASTE: ["umeboshi paste", "ume paste", "plum paste"],
  MISC_DASHI_PACK: ["dashi pack", "dashi packet", "dashi bag"],
  MISC_YUZU_JUICE: ["bottled yuzu juice", "yuzu citrus juice"],
  MISC_YUZU_ZEST: ["yuzu zest", "yuzu peel", "yuzu rind"],
  SAUCE_DOUFU_RU: ["red fermented bean curd", "red fu ru", "nam yue", "red tofu cheese"],
  PRODUCE_CHILI_OIL_CRISP: ["chili oil with crisp", "lao gan ma style"],
  SAUCE_OYSTER_FLAVORED: ["vegetarian oyster sauce", "mushroom oyster sauce", "vegetarian stir-fry sauce"],
  HERB_LAKSA_LEAF: ["daun kesum", "kesum leaf"],
  HERB_KEMANGI: ["kemangi basil", "indonesian lemon basil"],
  SAUCE_BELACHAN_PASTE: ["belachan paste", "belacan cooking paste"],
  BAKING_SAGO_PEARL: ["sago pearl", "sago pearls", "sago starch"],
  PRODUCE_PETAI: ["petai", "stink bean", "peteh", "parkia"],
  PRODUCE_KECOMBRANG: ["kecombrang", "honje", "torch ginger bud"],
  CONDIMENT_SAMBAL_TERASI: ["sambal terasi", "sambal belacan"],
  DAIRY_COTTAGE_CHEESE: ["cottage cheese"],
  SAUCE_CHIMICHURRI: ["chimichurri", "chimichurri sauce"],
  SAUCE_ROMESCO: ["romesco", "romesco sauce"],
  SAUCE_TZATZIKI: ["tzatziki", "tzatziki sauce"],
  SAUCE_HOLLANDAISE: ["hollandaise", "hollandaise sauce"],
};

// ── Ambiguous Aliases ──────────────────────────────────────────

/**
 * Aliases that legitimately map to multiple canonicals.
 * The parser should flag these for review or use context to disambiguate.
 */
export const AMBIGUOUS_ALIASES: AmbiguousAlias[] = [
  {
    alias: "coriander",
    candidates: ["HERB_CILANTRO", "SPICE_CORIANDER_SEED"],
    notes: "In most Asian/Latin contexts = cilantro (leaf). In European/Middle Eastern = coriander seed. When dried/ground, usually seed.",
  },
  {
    alias: "pepper",
    candidates: ["SPICE_BLACK_PEPPER", "PRODUCE_BELL_PEPPER", "PRODUCE_CHILI_PEPPER"],
    notes: "Default mapped to SPICE_BLACK_PEPPER. Context: 'red pepper' could be bell or chili; 'cracked pepper' = black pepper.",
  },
  {
    alias: "yam",
    candidates: ["PRODUCE_YAM", "PRODUCE_SWEET_POTATO"],
    notes: "In the US, 'yam' often refers to sweet potato. True yams are a different species. Mapped to PRODUCE_YAM.",
  },
  {
    alias: "corn flour",
    candidates: ["BAKING_CORN_STARCH", "GRAIN_CORNMEAL"],
    notes: "In UK/AU, 'corn flour' = corn starch. In US, it can mean finely ground cornmeal. Mapped to BAKING_CORN_STARCH.",
  },
  {
    alias: "cream",
    candidates: ["DAIRY_CREAM", "DAIRY_HEAVY_CREAM"],
    notes: "Unqualified 'cream' mapped to DAIRY_CREAM. For baking/whipping, usually 'heavy cream'.",
  },
  {
    alias: "miso",
    candidates: ["SAUCE_MISO_WHITE", "SAUCE_MISO_RED"],
    notes: "Unqualified 'miso' defaults to white miso (shiro). In Korean/heavy soups, could be red.",
  },
  {
    alias: "broth",
    candidates: ["BEVERAGE_CHICKEN_BROTH", "BEVERAGE_BEEF_BROTH", "BEVERAGE_VEGETABLE_BROTH"],
    notes: "Unqualified 'broth' or 'stock' — needs context. Default: chicken broth.",
  },
  {
    alias: "rice",
    candidates: ["GRAIN_WHITE_RICE", "GRAIN_JASMINE_RICE", "GRAIN_BASMATI_RICE"],
    notes: "Unqualified 'rice' mapped to GRAIN_WHITE_RICE. Context may indicate jasmine/basmati.",
  },
  {
    alias: "oil",
    candidates: ["OIL_VEGETABLE", "OIL_OLIVE", "OIL_CANOLA"],
    notes: "Unqualified 'oil' or 'cooking oil' mapped to OIL_VEGETABLE.",
  },
  {
    alias: "vinegar",
    candidates: ["VINEGAR_WHITE", "VINEGAR_RICE", "VINEGAR_APPLE_CIDER"],
    notes: "Unqualified 'vinegar' mapped to VINEGAR_WHITE.",
  },
  {
    alias: "basil",
    candidates: ["HERB_BASIL", "HERB_THAI_BASIL"],
    notes: "Default 'basil' = sweet basil (HERB_BASIL). Thai recipes may mean Thai basil.",
  },
  {
    alias: "mushroom",
    candidates: ["PRODUCE_MUSHROOM", "PRODUCE_WHITE_MUSHROOM", "PRODUCE_CREMINI"],
    notes: "Generic 'mushroom' mapped to PRODUCE_MUSHROOM (button). Could be cremini or other variety.",
  },
];

// ── Utility: Expand to IngredientAlias[] ───────────────────────

/**
 * Expand the compact ALIAS_DATA into the full IngredientAlias[] structure.
 * Useful for serialization or when the interface format is needed.
 */
export function buildAliasArray(locale = "en"): IngredientAlias[] {
  const result: IngredientAlias[] = [];
  for (const [canonicalId, aliases] of Object.entries(ALIAS_DATA)) {
    for (const alias of aliases) {
      result.push({ alias, canonicalId, locale });
    }
  }
  return result;
}
