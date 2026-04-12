// ─────────────────────────────────────────────────────────────
// Expansion Ingredient Data
// ~9000 additional ingredients in compact format.
// 
// Format: category key → array of ingredient names.
// The export script auto-generates:
//   - Canonical IDs (CATEGORY_NAME_IN_UPPER_SNAKE_CASE)
//   - Basic aliases (name, plural, common variants)
//   - Allergen assignments based on category rules
//
// Existing curated canonical items (999) take precedence;
// duplicates are automatically skipped.
// ─────────────────────────────────────────────────────────────

export const EXPANSION: Record<string, string[]> = {

produce: [
  // ── Leafy Greens ──
  "Arugula","Baby Arugula","Radicchio","Endive","Belgian Endive","Curly Endive","Frisée","Escarole",
  "Romaine Lettuce","Iceberg Lettuce","Butter Lettuce","Red Leaf Lettuce","Green Leaf Lettuce",
  "Little Gem Lettuce","Bibb Lettuce","Oak Leaf Lettuce","Mesclun","Spring Mix","Mixed Greens",
  "Baby Spinach","Mature Spinach","Savoy Spinach","New Zealand Spinach","Malabar Spinach",
  "Swiss Chard","Rainbow Chard","Red Chard","Green Chard",
  "Collard Greens","Mustard Greens","Turnip Greens","Beet Greens","Dandelion Greens",
  "Sorrel","Purslane","Lamb's Lettuce","Mâche","Mizuna","Tatsoi","Chrysanthemum Greens",
  "Pea Shoots","Sunflower Sprouts","Microgreens","Broccoli Microgreens","Radish Microgreens",
  "Watercress","Land Cress","Garden Cress","Upland Cress",
  "Amaranth Greens","Callaloo","Moringa Leaves","Curry Leaves","Pandan Leaves","Banana Leaves",
  "Perilla Leaves","Shiso","Vietnamese Coriander","Rau Ram","Culantro","Epazote",
  "Papalo","Huacatay","Pipicha","Hoja Santa",

  // ── Root & Tuber Vegetables ──
  "Carrot","Baby Carrot","Rainbow Carrot","Purple Carrot","White Carrot",
  "Parsnip","Turnip","Baby Turnip","Rutabaga","Swede",
  "Beet","Golden Beet","Chioggia Beet","Baby Beet",
  "Radish","Daikon","Watermelon Radish","Black Radish","French Breakfast Radish",
  "Celeriac","Celery Root","Kohlrabi","Jerusalem Artichoke","Sunchoke",
  "Jicama","Yam","Purple Yam","Ube","Taro","Taro Root","Eddoe",
  "Cassava","Yuca","Tapioca Root","Malanga","Boniato",
  "Lotus Root","Burdock Root","Gobo","Galangal","Fingerroot",
  "Arrowroot","Water Chestnut","Ginger Root","Young Ginger","Turmeric Root",
  "Horseradish Root","Wasabi Root",

  // ── Nightshades ──
  "Heirloom Tomato","Green Tomato","Sun-Dried Tomato","Campari Tomato",
  "Yellow Tomato","Kumato","Tomatillo",
  "Russet Potato","Yukon Gold Potato","Red Potato","Fingerling Potato","Purple Potato",
  "New Potato","Baby Potato","Creamer Potato","Kennebec Potato",
  "Japanese Sweet Potato","Purple Sweet Potato","Garnet Yam","Jewel Yam","Hannah Sweet Potato",
  "Globe Eggplant","Italian Eggplant","Graffiti Eggplant","Indian Eggplant","White Eggplant",
  "Banana Pepper","Cherry Pepper","Cubanelle Pepper","Shishito Pepper","Padrón Pepper",
  "Fresno Pepper","Cayenne Pepper","Guajillo Pepper","Ancho Pepper","Pasilla Pepper",
  "Chipotle Pepper","Cascabel Pepper","Mulato Pepper","New Mexico Pepper","Hungarian Wax Pepper",
  "Pepperoncini","Piquillo Pepper","Aleppo Pepper","Urfa Pepper","Espelette Pepper",
  "Carolina Reaper","Ghost Pepper","Trinidad Scorpion","Datil Pepper",
  "Aji Amarillo","Aji Panca","Rocoto Pepper","Malagueta Pepper",
  "Sichuan Pepper","Facing Heaven Pepper","Tianjin Pepper","Korean Red Pepper",

  // ── Alliums ──
  "White Onion","Red Onion","Pearl Onion","Cipollini Onion","Boiling Onion",
  "Maui Onion","Walla Walla Onion","Spring Onion","Torpedo Onion",
  "Scallion","Welsh Onion","Ramp","Wild Garlic","Green Garlic",
  "Garlic Scape","Elephant Garlic","Black Garlic","Roasted Garlic",
  "Chive Blossoms","Garlic Chives","Chinese Chives",
  "Leek","Baby Leek",

  // ── Cruciferous ──
  "Broccoli","Broccolini","Broccoli Rabe","Chinese Broccoli","Gai Lan",
  "Cauliflower","Purple Cauliflower","Romanesco","Broccoflower",
  "Green Cabbage","Red Cabbage","Savoy Cabbage","Napa Cabbage","Taiwanese Cabbage",
  "Brussels Sprouts","Baby Brussels Sprouts",
  "Kale","Lacinato Kale","Curly Kale","Red Kale","Baby Kale",
  "Bok Choy","Baby Bok Choy","Shanghai Bok Choy","Choy Sum","Yu Choy",
  "Kohlrabi Greens","Kai-Lan","Komatsuna",

  // ── Squash & Gourds ──
  "Zucchini","Yellow Squash","Pattypan Squash","Cousa Squash",
  "Butternut Squash","Acorn Squash","Spaghetti Squash","Delicata Squash",
  "Kabocha Squash","Hubbard Squash","Buttercup Squash","Turban Squash",
  "Honeynut Squash","Red Kuri Squash","Carnival Squash","Sweet Dumpling Squash",
  "Pumpkin","Sugar Pumpkin","Pie Pumpkin","Japanese Pumpkin",
  "Chayote","Bottle Gourd","Calabash","Luffa","Ridge Gourd","Snake Gourd",
  "Bitter Melon","Indian Bitter Gourd","Winter Melon","Wax Gourd","Fuzzy Melon",
  "Ivy Gourd","Tinda","Ash Gourd",
  "Cucumber","English Cucumber","Persian Cucumber","Kirby Cucumber","Lemon Cucumber",
  "Japanese Cucumber","Armenian Cucumber",

  // ── Mushrooms ──
  "White Button Mushroom","Cremini Mushroom","Baby Bella Mushroom","Portobello Mushroom",
  "Shiitake Mushroom","Fresh Shiitake","Dried Shiitake",
  "Oyster Mushroom","King Oyster Mushroom","Pink Oyster Mushroom","Yellow Oyster Mushroom",
  "Maitake Mushroom","Hen of the Woods","Enoki Mushroom","Beech Mushroom",
  "Lion's Mane Mushroom","Chanterelle Mushroom","Black Trumpet Mushroom",
  "Morel Mushroom","Porcini Mushroom","Dried Porcini",
  "Matsutake Mushroom","Truffle","Black Truffle","White Truffle","Truffle Shavings",
  "Wood Ear Mushroom","Cloud Ear Mushroom","Snow Fungus","Tremella",
  "Straw Mushroom","Abalone Mushroom","Nameko Mushroom","Pioppino Mushroom",
  "Hedgehog Mushroom","Lobster Mushroom","Chicken of the Woods",
  "Shimeji Mushroom","White Shimeji","Brown Shimeji",
  "Dried Mixed Mushrooms","Mushroom Powder",

  // ── Corn & Pods ──
  "Sweet Corn","Corn on the Cob","Baby Corn","White Corn","Blue Corn",
  "Hominy","Dried Corn","Popcorn Kernels",
  "Green Bean","Wax Bean","Romano Bean","Dragon Tongue Bean","Haricots Verts",
  "Snow Pea","Sugar Snap Pea","English Pea","Sweet Pea","Pea Pod",
  "Okra","Chinese Long Bean","Yard Long Bean","Winged Bean","Hyacinth Bean",

  // ── Stalks & Stems ──
  "Celery","Celery Heart","Chinese Celery","Celery Stalk",
  "Asparagus","White Asparagus","Purple Asparagus",
  "Artichoke","Baby Artichoke","Artichoke Heart",
  "Fennel","Fennel Bulb","Baby Fennel","Florence Fennel",
  "Rhubarb","Cardoon","Hearts of Palm","Bamboo Shoot","Fresh Bamboo Shoot",
  "Lemongrass","Lemongrass Stalk","Banana Blossom","Banana Flower",
  "Fiddlehead Fern","Bracken Fern","Water Spinach","Morning Glory","Kangkung",
  "Nopal","Cactus Paddle",

  // ── Asian Vegetables ──
  "Chinese Broccoli","Chinese Mustard","Gai Choy","Chinese Spinach","Amaranth",
  "Chinese Celery","Chinese Leek","Garlic Bolt","Taiwan Lettuce","A Choy",
  "Lotus Leaf","Lotus Seed","Dried Lily Bud","Tiger Lily Bud",
  "Bean Sprout","Mung Bean Sprout","Soybean Sprout","Alfalfa Sprout",
  "Daikon Sprout","Kaiware","Shiso Leaf","Green Shiso","Red Shiso",
  "Myoga","Japanese Ginger Bud","Wasabi Leaves","Negi","Tokyo Negi",
  "Edamame","Fresh Edamame","Frozen Edamame",
  "Kailan","Pak Choi","Kai Choi","Sin Choy","Ong Choy",
  "Pickled Mustard Green","Preserved Vegetable","Suan Cai","Ya Cai",
  "Korean Radish","Mu","Perilla","Kkaennip","Crown Daisy","Ssukgat",
  "Fernbrake","Gosari","Doraji","Bellflower Root",
  "Pennywort","Gotu Kola","Sawtooth Coriander","Ngò Gai",

  // ── Tropical & Latin Vegetables ──
  "Plantain","Green Plantain","Ripe Plantain","Maduros",
  "Breadfruit","Jackfruit","Young Jackfruit","Canned Jackfruit",
  "Chayote","Christophine","Cho Cho","Calabaza","West Indian Pumpkin",
  "Yautía","Batata","Name","Tannier","Dasheen",
  "Nopales","Huauzontle","Verdolaga","Quelites","Chipilín",
  "Achiote Leaf","Avocado Leaf","Epazote Leaf",

  // ── Fruits: Citrus ──
  "Orange","Navel Orange","Blood Orange","Cara Cara Orange","Valencia Orange","Mandarin Orange",
  "Clementine","Tangerine","Satsuma","Tangelo","Minneola","Kumquat","Calamansi","Calamondin",
  "Lemon","Meyer Lemon","Eureka Lemon","Preserved Lemon",
  "Lime","Key Lime","Persian Lime","Makrut Lime","Kaffir Lime","Finger Lime",
  "Grapefruit","Ruby Red Grapefruit","White Grapefruit","Pink Grapefruit","Pomelo","Oroblanco",
  "Yuzu","Sudachi","Kabosu","Bergamot","Citron","Buddha's Hand","Ugli Fruit",

  // ── Fruits: Berries ──
  "Strawberry","Wild Strawberry","Blueberry","Wild Blueberry","Raspberry","Golden Raspberry",
  "Blackberry","Boysenberry","Loganberry","Marionberry","Mulberry","Black Mulberry",
  "Cranberry","Fresh Cranberry","Dried Cranberry","Lingonberry","Huckleberry",
  "Gooseberry","Cape Gooseberry","Golden Berry","Elderberry","Açaí Berry",
  "Goji Berry","Dried Goji Berry","Barberry","Dried Barberry",
  "Currant","Black Currant","Red Currant","White Currant",
  "Juniper Berry","Schisandra Berry","Sea Buckthorn Berry",

  // ── Fruits: Stone Fruits ──
  "Peach","White Peach","Yellow Peach","Donut Peach",
  "Nectarine","White Nectarine","Apricot","Plum","Italian Plum","Greengage Plum",
  "Cherry","Sweet Cherry","Sour Cherry","Bing Cherry","Rainier Cherry","Maraschino Cherry",
  "Damson","Sloe Berry","Mirabelle Plum","Pluot","Plumcot","Apriplum",
  "Lychee","Longan","Rambutan","Mangosteen",

  // ── Fruits: Tropical ──
  "Mango","Ataulfo Mango","Tommy Mango","Alphonso Mango","Green Mango",
  "Papaya","Green Papaya","Hawaiian Papaya","Mexican Papaya",
  "Pineapple","Baby Pineapple","Golden Pineapple",
  "Banana","Green Banana","Red Banana","Burro Banana","Lady Finger Banana",
  "Coconut","Young Coconut","Mature Coconut","Coconut Meat","Coconut Water",
  "Passion Fruit","Purple Passion Fruit","Yellow Passion Fruit",
  "Guava","Pink Guava","White Guava","Feijoa","Pineapple Guava",
  "Dragon Fruit","White Dragon Fruit","Red Dragon Fruit","Yellow Dragon Fruit",
  "Star Fruit","Carambola","Tamarind","Fresh Tamarind","Tamarind Paste","Tamarind Concentrate",
  "Soursop","Cherimoya","Custard Apple","Sugar Apple","Atemoya",
  "Durian","Fresh Durian","Frozen Durian",
  "Sapodilla","Mamey Sapote","Black Sapote","Canistel","Lucuma",
  "Jackfruit","Fresh Jackfruit","Canned Jackfruit",
  "Persimmon","Fuyu Persimmon","Hachiya Persimmon","Dried Persimmon",
  "Kiwi","Golden Kiwi","Baby Kiwi","Kiwi Berry",
  "Fig","Black Mission Fig","Kadota Fig","Turkish Fig","Dried Fig","Calimyrna Fig",
  "Date","Medjool Date","Deglet Noor Date","Barhi Date",
  "Pomegranate","Pomegranate Seeds","Pomegranate Arils",
  "Loquat","Jujube","Red Date","Dried Jujube",

  // ── Fruits: Melons ──
  "Watermelon","Seedless Watermelon","Yellow Watermelon","Mini Watermelon",
  "Cantaloupe","Honeydew","Galia Melon","Canary Melon","Crenshaw Melon",
  "Charentais Melon","Korean Melon","Hami Melon","Bitter Melon",
  "Santa Claus Melon","Casaba Melon","Pepino Melon",

  // ── Fruits: Pome ──
  "Apple","Granny Smith Apple","Fuji Apple","Gala Apple","Honeycrisp Apple",
  "Pink Lady Apple","Golden Delicious Apple","Red Delicious Apple","Braeburn Apple",
  "McIntosh Apple","Cortland Apple","Jonagold Apple","Jazz Apple","Envy Apple",
  "Crab Apple","Green Apple",
  "Pear","Bartlett Pear","Bosc Pear","Anjou Pear","Comice Pear","Asian Pear",
  "Nashi Pear","Forelle Pear","Seckel Pear","Starkrimson Pear",
  "Quince","Medlar",

  // ── Fruits: Grapes ──
  "Grape","Red Grape","Green Grape","Black Grape","Concord Grape",
  "Thompson Grape","Cotton Candy Grape","Muscat Grape","Champagne Grape",
  "Raisin","Golden Raisin","Sultana","Currant Raisin","Dried Grape",

  // ── Dried Fruits ──
  "Dried Apricot","Dried Mango","Dried Pineapple","Dried Papaya","Dried Banana Chip",
  "Prune","Dried Plum","Dried Cherry","Dried Blueberry","Dried Strawberry",
  "Dried Apple","Dried Pear","Dried Peach","Dried Coconut","Coconut Flake",
  "Desiccated Coconut","Toasted Coconut",
  "Dried Kiwi","Dried Cantaloupe","Freeze-Dried Raspberry","Freeze-Dried Strawberry",

  // ── Sea Vegetables ──
  "Nori","Roasted Nori","Nori Sheet","Nori Flakes",
  "Kombu","Dried Kombu","Dashi Kombu",
  "Wakame","Dried Wakame","Fresh Wakame",
  "Hijiki","Arame","Dulse","Sea Lettuce","Irish Moss",
  "Agar Agar","Agar Flakes","Kelp","Kelp Noodles","Kelp Granules",
  "Spirulina","Chlorella","Mekabu","Mozuku","Sea Grapes","Umibudo",
],

meat: [
  // ── Beef ──
  "Beef Tenderloin","Beef Filet Mignon","Beef Ribeye","Beef Ribeye Steak",
  "Beef Strip Steak","New York Strip","Beef T-Bone","Beef Porterhouse",
  "Beef Sirloin","Top Sirloin","Bottom Sirloin","Tri-Tip","Beef Tri-Tip Roast",
  "Beef Chuck Roast","Chuck Eye Steak","Beef Shoulder","Beef Blade Steak",
  "Beef Brisket","Flat Cut Brisket","Point Cut Brisket","Beef Plate",
  "Beef Short Rib","Boneless Short Rib","Flanken Short Rib",
  "Beef Flank Steak","Beef Skirt Steak","Beef Hanger Steak",
  "Beef Round","Top Round","Bottom Round","Eye of Round","Beef Rump Roast",
  "Beef Shank","Beef Osso Buco","Beef Marrow Bone",
  "Ground Beef","Lean Ground Beef","Ground Chuck","Ground Sirloin","Ground Round",
  "Beef Stew Meat","Beef Kabob Meat","Beef Tips",
  "Beef Tongue","Beef Heart","Beef Liver","Beef Kidney","Beef Tripe",
  "Beef Oxtail","Beef Cheek","Beef Sweetbread","Beef Brain",
  "Beef Tendon","Beef Knuckle","Beef Neck","Beef Shin",
  "Wagyu Beef","Kobe Beef","Angus Beef","Grass-Fed Beef",
  "Corned Beef","Beef Jerky","Beef Bresaola","Dried Beef","Beef Tallow",
  "Beef Stock Bones","Beef Soup Bones","Beef Suet",

  // ── Pork ──
  "Pork Loin","Pork Tenderloin","Pork Chop","Bone-In Pork Chop","Boneless Pork Chop",
  "Pork Shoulder","Pork Butt","Boston Butt","Pork Picnic",
  "Pork Belly","Pork Belly Slices","Pork Skin","Pork Rind",
  "Pork Ribs","Baby Back Ribs","Spare Ribs","St. Louis Ribs","Country-Style Ribs",
  "Pork Shank","Pork Hock","Ham Hock","Pork Trotter","Pig's Feet",
  "Ground Pork","Pork Mince","Pork Sausage Meat",
  "Pork Liver","Pork Tongue","Pork Heart","Pork Kidney","Pork Ear","Pork Snout",
  "Pork Jowl","Guanciale","Pork Cheek","Pork Intestine","Pork Stomach",
  "Pork Neck","Pork Collar","Pork Loin Roast","Crown Roast of Pork",
  "Pork Fatback","Lard","Pork Fat","Leaf Lard",
  "Suckling Pig","Roast Pork","Char Siu Pork",

  // ── Lamb & Goat ──
  "Lamb Loin","Lamb Loin Chop","Lamb Rack","Rack of Lamb","Lamb Crown Roast",
  "Lamb Leg","Boneless Leg of Lamb","Lamb Shank","Lamb Shoulder",
  "Lamb Chop","Lamb Rib Chop","Lamb Sirloin","Lamb Rump",
  "Ground Lamb","Lamb Mince","Lamb Neck","Lamb Breast",
  "Lamb Liver","Lamb Kidney","Lamb Heart","Lamb Sweetbread","Lamb Brain",
  "Lamb Tongue","Lamb Tripe","Lamb Ribs",
  "Mutton","Mutton Leg","Mutton Shoulder","Mutton Chop",
  "Goat Meat","Goat Leg","Goat Shoulder","Goat Chop","Ground Goat",
  "Kid Goat","Cabrito",

  // ── Veal ──
  "Veal Cutlet","Veal Scallopini","Veal Chop","Veal Loin","Veal Tenderloin",
  "Veal Shank","Veal Osso Buco","Veal Shoulder","Veal Breast",
  "Ground Veal","Veal Stew Meat","Veal Liver","Veal Sweetbread","Veal Tongue",
  "Veal Stock Bones",

  // ── Game Meats ──
  "Venison","Venison Loin","Venison Chop","Venison Steak","Ground Venison",
  "Venison Shank","Venison Stew Meat","Venison Sausage",
  "Bison","Bison Steak","Bison Burger","Ground Bison","Bison Ribeye","Bison Tenderloin",
  "Elk","Elk Steak","Ground Elk","Elk Roast",
  "Wild Boar","Wild Boar Chop","Wild Boar Sausage","Wild Boar Ragu Meat",
  "Rabbit","Whole Rabbit","Rabbit Leg","Rabbit Loin","Rabbit Saddle",
  "Kangaroo","Kangaroo Steak","Kangaroo Fillet",
  "Ostrich","Ostrich Steak","Ostrich Fillet",
  "Alligator","Alligator Tail","Frog Legs",
  "Caribou","Moose","Antelope","Pheasant Breast",
  "Yak","Llama","Camel","Horse Meat",

  // ── Cured & Processed Meats ──
  "Bacon","Turkey Bacon","Canadian Bacon","Back Bacon","Pancetta","Thick-Cut Bacon","Slab Bacon",
  "Ham","Smoked Ham","Honey Ham","Black Forest Ham","Serrano Ham","Ibérico Ham",
  "Country Ham","Virginia Ham","Prosciutto","Prosciutto di Parma","Prosciutto Cotto",
  "Salami","Genoa Salami","Soppressata","Capocollo","Coppa","Lonza",
  "Mortadella","Bologna","Liverwurst","Braunschweiger",
  "Pepperoni","Summer Sausage","Landjaeger","Chorizo","Spanish Chorizo","Mexican Chorizo",
  "Nduja","Lap Cheong","Chinese Sausage","Lap Yuk","Chinese Cured Pork Belly",
  "Andouille Sausage","Boudin","Kielbasa","Bratwurst","Weisswurst","Frankfurter",
  "Italian Sausage","Sweet Italian Sausage","Hot Italian Sausage","Fennel Sausage",
  "Merguez","Boerewors","Cumberland Sausage","Bangers","Linguiça",
  "Blood Sausage","Black Pudding","Morcilla","Sundae","Soondae",
  "Cured Meat","Biltong","Cecina","Pastirma","Basturma",
  "Pâté","Liver Pâté","Duck Liver Pâté","Foie Gras","Rillettes",
  "Terrine","Head Cheese","Aspic","Confit Meat",
  "Beef Bacon","Duck Bacon","Lamb Bacon",
  "Corned Beef Brisket","Pastrami","Montreal Smoked Meat",
  "Spam","Canned Corned Beef","Canned Ham","Vienna Sausage",
  "Tocino","Tapa","Longganisa","Filipino Longganisa","Skinless Longganisa",
],

poultry: [
  // ── Chicken ──
  "Whole Chicken","Chicken Half","Chicken Quarter",
  "Chicken Breast","Boneless Skinless Chicken Breast","Bone-In Chicken Breast","Split Chicken Breast",
  "Chicken Thigh","Boneless Skinless Chicken Thigh","Bone-In Chicken Thigh",
  "Chicken Drumstick","Chicken Leg Quarter","Chicken Wing","Chicken Wingette","Chicken Wing Tip",
  "Chicken Tender","Chicken Strip","Chicken Cutlet",
  "Ground Chicken","Chicken Sausage","Chicken Mince",
  "Chicken Liver","Chicken Heart","Chicken Gizzard","Chicken Neck","Chicken Feet","Chicken Back",
  "Chicken Carcass","Chicken Bones","Rotisserie Chicken","Smoked Chicken",
  "Chicken Skin","Chicken Fat","Schmaltz",

  // ── Turkey ──
  "Whole Turkey","Turkey Breast","Boneless Turkey Breast","Turkey Thigh","Turkey Leg",
  "Turkey Drumstick","Turkey Wing","Ground Turkey","Turkey Sausage","Turkey Mince",
  "Turkey Cutlet","Turkey Tenderloin","Turkey Neck","Turkey Giblets",
  "Smoked Turkey","Smoked Turkey Leg","Turkey Bacon","Turkey Deli Meat",

  // ── Duck ──
  "Whole Duck","Duck Breast","Duck Leg","Duck Thigh","Duck Wing",
  "Duck Confit","Duck Fat","Rendered Duck Fat",
  "Duck Liver","Duck Gizzard","Duck Tongue","Duck Neck",
  "Ground Duck","Smoked Duck","Smoked Duck Breast","Peking Duck","Roast Duck",
  "Duck Egg","Salted Duck Egg","Century Egg","Preserved Duck Egg",

  // ── Other Poultry ──
  "Cornish Hen","Cornish Game Hen","Poussin","Spatchcock Chicken",
  "Quail","Whole Quail","Quail Breast","Quail Egg",
  "Goose","Goose Breast","Goose Leg","Goose Fat","Goose Liver",
  "Squab","Pigeon","Guinea Fowl","Pheasant","Partridge",
  "Emu","Turkey Egg","Goose Egg","Ostrich Egg",

  // ── Eggs ──
  "Egg","Chicken Egg","Egg White","Egg Yolk",
  "Free-Range Egg","Organic Egg","Pasteurized Egg",
  "Egg Powder","Dried Egg White","Meringue Powder",
  "Liquid Egg","Liquid Egg White","Liquid Egg Substitute",
],

seafood: [
  // ── White Fish ──
  "Cod","Atlantic Cod","Pacific Cod","Black Cod","Sablefish","Lingcod",
  "Haddock","Pollock","Alaska Pollock","Whiting","Hake","Silver Hake",
  "Halibut","Pacific Halibut","Atlantic Halibut","California Halibut",
  "Sole","Dover Sole","Lemon Sole","Petrale Sole",
  "Flounder","Summer Flounder","Winter Flounder","Fluke",
  "Sea Bass","Chilean Sea Bass","Black Sea Bass","Striped Bass","Branzino","Loup de Mer",
  "Snapper","Red Snapper","Yellowtail Snapper","Mutton Snapper","Lane Snapper",
  "Grouper","Black Grouper","Red Grouper","Goliath Grouper",
  "Tilapia","Nile Tilapia","Catfish","Channel Catfish","Swai","Basa","Pangasius",
  "Perch","Yellow Perch","Ocean Perch","Walleye","Pike","Northern Pike","Pickerel",
  "Turbot","John Dory","Monkfish","Monkfish Tail","Monkfish Liver","Ankimo",
  "Rockfish","Pacific Rockfish","Striped Rockfish",
  "Mahi Mahi","Dolphinfish","Wahoo","Ono",
  "Barramundi","Corvina","Drum","Redfish","Red Drum",
  "Skate","Skate Wing","Ray",
  "Pomfret","Silver Pomfret","Black Pomfret",
  "Milkfish","Bangus","Threadfin","Tarakihi","Blue Warehou",

  // ── Rich/Oily Fish ──
  "Salmon","Atlantic Salmon","King Salmon","Chinook Salmon","Sockeye Salmon",
  "Coho Salmon","Pink Salmon","Chum Salmon","Smoked Salmon","Lox","Gravlax",
  "Salmon Fillet","Salmon Steak","Salmon Belly","Salmon Roe","Ikura",
  "Tuna","Yellowfin Tuna","Ahi Tuna","Bigeye Tuna","Albacore Tuna","Skipjack Tuna",
  "Bluefin Tuna","Tuna Steak","Sashimi-Grade Tuna","Canned Tuna","Tuna Belly","Toro",
  "Mackerel","Atlantic Mackerel","Spanish Mackerel","King Mackerel","Japanese Mackerel","Saba",
  "Sardine","Fresh Sardine","Canned Sardine","Sardine Fillet",
  "Anchovy","Fresh Anchovy","Canned Anchovy","Anchovy Fillet","White Anchovy","Boquerón",
  "Herring","Pickled Herring","Smoked Herring","Kipper","Bloater",
  "Trout","Rainbow Trout","Brook Trout","Steelhead Trout","Smoked Trout",
  "Swordfish","Swordfish Steak","Marlin","Opah","Moonfish",
  "Arctic Char","Whitefish","Lake Whitefish","Smoked Whitefish",
  "Bluefish","Shad","Shad Roe","Pompano","Yellowtail","Hamachi","Kampachi","Amberjack",

  // ── Freshwater Fish ──
  "Carp","Common Carp","Grass Carp","Silver Carp","Crucian Carp",
  "Tilapia","Bream","Sea Bream","Gilt-Head Bream","Tai","Madai",
  "Eel","Freshwater Eel","Unagi","Saltwater Eel","Anago","Conger Eel","Smoked Eel",
  "Sturgeon","Beluga Sturgeon","Paddlefish",

  // ── Shellfish: Shrimp & Prawns ──
  "Shrimp","Large Shrimp","Jumbo Shrimp","Medium Shrimp","Small Shrimp",
  "Tiger Shrimp","Black Tiger Shrimp","White Shrimp","Gulf Shrimp","Rock Shrimp",
  "Spot Prawn","Prawn","King Prawn","Tiger Prawn","Banana Prawn",
  "Bay Shrimp","Cocktail Shrimp","Cooked Shrimp","Raw Shrimp",
  "Shell-On Shrimp","Peeled Shrimp","Deveined Shrimp",
  "Dried Shrimp","Shrimp Paste","Belacan","Kapi","Mam Tom",
  "Crayfish","Crawfish","Crawdad","Langoustine","Scampi",
  "Mantis Shrimp",

  // ── Shellfish: Crab ──
  "Crab","Blue Crab","Dungeness Crab","King Crab","Snow Crab","Stone Crab",
  "Soft-Shell Crab","Crab Leg","Crab Claw","Crab Meat","Lump Crab Meat",
  "Jumbo Lump Crab","Claw Crab Meat","Backfin Crab","Imitation Crab","Surimi",
  "Mud Crab","Swimmer Crab","Spider Crab","Horsehair Crab",
  "Canned Crab","Crab Roe","Crab Paste","Crab Tomalley",

  // ── Shellfish: Lobster ──
  "Lobster","Maine Lobster","Spiny Lobster","Rock Lobster","Lobster Tail",
  "Lobster Claw","Lobster Knuckle","Lobster Meat","Lobster Roe","Lobster Tomalley",
  "Slipper Lobster","Moreton Bay Bug","Crayfish","Yabby",

  // ── Mollusks ──
  "Clam","Littleneck Clam","Cherrystone Clam","Quahog","Manila Clam",
  "Razor Clam","Geoduck","Surf Clam","Cockle","Blood Cockle",
  "Mussel","Blue Mussel","Green-Lipped Mussel","Mediterranean Mussel",
  "Oyster","Eastern Oyster","Pacific Oyster","Kumamoto Oyster","Olympia Oyster","Belon Oyster",
  "Scallop","Sea Scallop","Bay Scallop","Diver Scallop","Dried Scallop","Conpoy",
  "Squid","Baby Squid","Squid Tube","Squid Ring","Squid Tentacle","Dried Squid",
  "Calamari","Cuttlefish","Cuttlefish Ink",
  "Octopus","Baby Octopus","Octopus Tentacle","Dried Octopus",
  "Abalone","Fresh Abalone","Canned Abalone","Dried Abalone",
  "Whelk","Conch","Queen Conch","Periwinkle","Sea Snail","Escargot",
  "Sea Urchin","Uni","Sea Cucumber","Dried Sea Cucumber","Rehydrated Sea Cucumber",
  "Jellyfish","Salted Jellyfish","Sea Squirt",

  // ── Preserved Seafood ──
  "Dried Fish","Stockfish","Salt Cod","Bacalao","Baccalà",
  "Fish Ball","Fish Cake","Kamaboko","Narutomaki","Chikuwa","Surimi Stick",
  "Canned Salmon","Canned Mackerel","Canned Sardine in Oil","Canned Sardine in Tomato",
  "Smoked Mackerel","Smoked Trout","Smoked Eel",
  "Caviar","Sturgeon Caviar","Salmon Caviar","Tobiko","Flying Fish Roe","Masago","Mentaiko",
  "Bottarga","Dried Mullet Roe","Karasumi",
  "Bonito Flakes","Katsuobushi","Dried Bonito",
  "Dried Squid","Dried Cuttlefish","Dried Scallop","Dried Oyster","Dried Abalone",
  "Fish Maw","Dried Fish Maw","Shark Fin","Dried Shark Fin",
  "Canned Clam","Canned Oyster","Smoked Oyster","Canned Mussel","Canned Octopus",
],

dairy: [
  // ── Milk ──
  "Whole Milk","Skim Milk","Low-Fat Milk","2% Milk","1% Milk",
  "Raw Milk","Organic Milk","A2 Milk","Lactose-Free Milk",
  "Goat Milk","Sheep Milk","Buffalo Milk","Camel Milk","Donkey Milk",
  "Evaporated Milk","Condensed Milk","Sweetened Condensed Milk",
  "Powdered Milk","Dry Milk","Nonfat Dry Milk","Malted Milk Powder",
  "Buttermilk","Cultured Buttermilk","Kefir","Kefir Milk",
  "Chocolate Milk","Strawberry Milk",

  // ── Cream ──
  "Heavy Cream","Heavy Whipping Cream","Light Cream","Half and Half",
  "Whipping Cream","Double Cream","Single Cream","Clotted Cream","Devonshire Cream",
  "Sour Cream","Light Sour Cream","Mexican Crema","Crème Fraîche",
  "Mascarpone","Cream Cheese","Whipped Cream Cheese","Neufchâtel",

  // ── Yogurt ──
  "Plain Yogurt","Greek Yogurt","Full-Fat Greek Yogurt","Non-Fat Greek Yogurt",
  "Whole Milk Yogurt","Low-Fat Yogurt","Vanilla Yogurt",
  "Strained Yogurt","Labneh","Skyr","Quark",
  "Goat Yogurt","Sheep Yogurt","Bulgarian Yogurt",
  "Coconut Yogurt","Almond Yogurt","Soy Yogurt","Oat Yogurt",
  "Ayran","Doogh","Lassi","Raita Base",

  // ── Butter ──
  "Unsalted Butter","Salted Butter","European Butter","Cultured Butter",
  "Clarified Butter","Ghee","Brown Butter","Beurre Noisette",
  "Whipped Butter","Compound Butter","Garlic Butter","Herb Butter",
  "Goat Butter","Sheep Butter","Vegan Butter","Plant-Based Butter",
  "Margarine","Shortening","Vegetable Shortening",

  // ── Cheese: Fresh ──
  "Mozzarella","Fresh Mozzarella","Buffalo Mozzarella","Burrata","Stracciatella",
  "Ricotta","Whole Milk Ricotta","Part-Skim Ricotta","Fresh Ricotta","Ricotta Salata",
  "Cottage Cheese","Small Curd Cottage Cheese","Large Curd Cottage Cheese",
  "Feta","Greek Feta","Bulgarian Feta","French Feta","Vegan Feta",
  "Goat Cheese","Chèvre","Fresh Goat Cheese","Aged Goat Cheese","Goat Cheese Log",
  "Paneer","Fresh Paneer","Queso Fresco","Queso Blanco","Queso Oaxaca",
  "Halloumi","Bread Cheese","Juustoleipä","Anari","Panela",

  // ── Cheese: Soft & Semi-Soft ──
  "Brie","Double Cream Brie","Triple Cream Brie",
  "Camembert","Époisses","Pont-l'Évêque","Reblochon","Taleggio","Stracchino",
  "Fontina","Havarti","Cream Havarti","Dill Havarti",
  "Muenster","Limburger","Port Salut","Saint-André",
  "Raclette","Morbier","Tomme de Savoie",

  // ── Cheese: Semi-Hard & Hard ──
  "Cheddar","Sharp Cheddar","Mild Cheddar","White Cheddar","Aged Cheddar","Extra Sharp Cheddar",
  "Colby","Colby-Jack","Monterey Jack","Pepper Jack",
  "Swiss Cheese","Emmental","Emmentaler","Gruyère","Comté","Beaufort","Appenzeller",
  "Gouda","Aged Gouda","Smoked Gouda","Young Gouda","Edam",
  "Provolone","Sharp Provolone","Mild Provolone",
  "American Cheese","Processed Cheese","Velveeta","Cheese Spread",
  "Jarlsberg","Maasdam","Leerdammer",
  "Manchego","Idiazábal","Mahón","Zamorano",
  "Asiago","Fresh Asiago","Aged Asiago",
  "Pecorino","Pecorino Romano","Pecorino Toscano","Pecorino Sardo",
  "Parmesan","Parmigiano-Reggiano","Grana Padano",
  "Piave","Montasio","Castelmagno","Bra","Raschera",

  // ── Cheese: Blue ──
  "Blue Cheese","Gorgonzola","Gorgonzola Dolce","Gorgonzola Piccante",
  "Roquefort","Stilton","Blue Stilton","Cambozola","Danish Blue","Maytag Blue",
  "Cabrales","Valdéon","Fourme d'Ambert","Bleu d'Auvergne","Saint Agur",

  // ── Cheese: Other ──
  "String Cheese","Cheese Curd","Queso Chihuahua","Queso Cotija","Queso Añejo",
  "Queso de Bola","Requesón","Provoleta",
  "Kashkaval","Tulum Cheese","Beyaz Peynir","Lor Cheese",
  "Cheese Slice","Shredded Cheese","Grated Cheese","Cheese Powder",
],

grain: [
  // ── Rice ──
  "White Rice","Long Grain Rice","Medium Grain Rice","Short Grain Rice",
  "Jasmine Rice","Basmati Rice","Brown Rice","Brown Basmati Rice",
  "Sushi Rice","Calrose Rice","Arborio Rice","Carnaroli Rice","Vialone Nano Rice",
  "Wild Rice","Black Rice","Forbidden Rice","Red Rice","Bhutanese Red Rice",
  "Sticky Rice","Glutinous Rice","Sweet Rice","Mochi Rice",
  "Bomba Rice","Valencia Rice","Carolina Gold Rice","Texmati Rice",
  "Parboiled Rice","Converted Rice","Instant Rice","Minute Rice",
  "Rice Flour","Glutinous Rice Flour","Brown Rice Flour","Rice Bran",
  "Puffed Rice","Crispy Rice","Rice Flakes","Beaten Rice","Poha","Flattened Rice",
  "Rice Paper","Rice Vermicelli","Rice Stick","Rice Noodle","Pad Thai Noodle",
  "Broken Rice","Com Tam",

  // ── Pasta ──
  "Spaghetti","Spaghettini","Spaghettoni","Angel Hair","Capellini",
  "Linguine","Fettuccine","Tagliatelle","Pappardelle","Bucatini",
  "Penne","Penne Rigate","Rigatoni","Ziti","Mostaccioli","Paccheri",
  "Fusilli","Rotini","Gemelli","Cavatappi","Cellentani",
  "Farfalle","Bow Tie Pasta","Campanelle","Gigli",
  "Orzo","Pastina","Acini di Pepe","Stelline","Ditalini","Tubettini",
  "Macaroni","Elbow Macaroni","Cavatelli","Orecchiette","Trofie",
  "Lasagna","Lasagna Sheet","Fresh Lasagna","No-Boil Lasagna","Cannelloni","Manicotti",
  "Ravioli","Tortellini","Tortelloni","Agnolotti","Cappelletti","Mezzaluna",
  "Gnocchi","Potato Gnocchi","Ricotta Gnocchi","Gnudi",
  "Couscous","Israeli Couscous","Pearl Couscous","Lebanese Couscous","Moghrabieh",
  "Fresh Pasta","Egg Pasta","Whole Wheat Pasta","Gluten-Free Pasta",
  "Chickpea Pasta","Lentil Pasta","Brown Rice Pasta","Corn Pasta",

  // ── Asian Noodles ──
  "Ramen Noodle","Fresh Ramen","Dried Ramen","Instant Ramen",
  "Udon Noodle","Fresh Udon","Dried Udon","Frozen Udon",
  "Soba Noodle","100% Buckwheat Soba","Green Tea Soba","Cha Soba",
  "Somen Noodle","Shirataki Noodle","Konnyaku Noodle",
  "Lo Mein Noodle","Chow Mein Noodle","Wonton Noodle","Egg Noodle",
  "Chinese Egg Noodle","Flat Rice Noodle","Chow Fun","Ho Fun","Kway Teow",
  "Glass Noodle","Cellophane Noodle","Bean Thread Noodle","Mung Bean Noodle",
  "Sweet Potato Noodle","Japchae Noodle","Dangmyeon",
  "Bún","Vietnamese Vermicelli","Bánh Phở","Pho Noodle",
  "Pad See Ew Noodle","Pad Kee Mao Noodle","Sen Yai","Sen Lek","Sen Mee",
  "Misua","Bihon","Pancit Noodle","Pancit Canton","Pancit Bihon",
  "Hokkien Noodle","Laksa Noodle","Mee Pok","Mee Kia","Bee Hoon",
  "Knife-Cut Noodle","Dao Xiao Mian","Hand-Pulled Noodle","La Mian",
  "Spinach Noodle","Squid Ink Noodle","Turmeric Noodle",

  // ── Bread ──
  "White Bread","Whole Wheat Bread","Multigrain Bread","Sourdough Bread",
  "Rye Bread","Pumpernickel","Dark Rye","Light Rye",
  "French Bread","Baguette","Ciabatta","Focaccia","Italian Bread",
  "Pita Bread","Whole Wheat Pita","Naan","Garlic Naan","Tandoori Roti","Chapati",
  "Tortilla","Flour Tortilla","Corn Tortilla","Whole Wheat Tortilla",
  "Brioche","Challah","Hawaiian Roll","Parker House Roll","Dinner Roll",
  "Cornbread","Corn Muffin","Hush Puppy",
  "English Muffin","Crumpet","Scone",
  "Flatbread","Lavash","Sangak","Barbari","Taftan",
  "Injera","Dosa","Appam","Idiyappam","Paratha","Roti Canai","Roti Prata",
  "Mantou","Chinese Steamed Bun","Milk Bread","Shokupan","Japanese Milk Bread",
  "Croissant","Pain au Chocolat","Danish Pastry",
  "Panko Breadcrumb","Italian Breadcrumb","Seasoned Breadcrumb","Fresh Breadcrumb",
  "Crouton","Garlic Crouton",

  // ── Grains & Cereals ──
  "Oats","Rolled Oats","Old-Fashioned Oats","Steel-Cut Oats","Quick Oats","Instant Oats",
  "Oat Flour","Oat Bran","Oat Milk Powder",
  "Quinoa","White Quinoa","Red Quinoa","Black Quinoa","Tricolor Quinoa",
  "Bulgur","Fine Bulgur","Coarse Bulgur","Freekeh","Green Freekeh",
  "Farro","Emmer Farro","Spelt","Spelt Berries","Spelt Flour",
  "Barley","Pearl Barley","Hulled Barley","Barley Flour","Barley Flakes",
  "Millet","Pearl Millet","Finger Millet","Ragi","Foxtail Millet",
  "Amaranth","Amaranth Flour","Puffed Amaranth",
  "Buckwheat","Buckwheat Groats","Kasha","Buckwheat Flour",
  "Teff","Teff Flour","Teff Grain",
  "Sorghum","Sorghum Flour","Popped Sorghum",
  "Cornmeal","Yellow Cornmeal","White Cornmeal","Blue Cornmeal",
  "Polenta","Instant Polenta","Grits","Hominy Grits","Stone-Ground Grits",
  "Wheat Berry","Cracked Wheat","Wheat Germ","Wheat Bran",
  "Kamut","Einkorn","Triticale",
  "Semolina","Durum Wheat","Coarse Semolina","Fine Semolina",

  // ── Wraps & Wrappers ──
  "Spring Roll Wrapper","Egg Roll Wrapper","Wonton Wrapper","Dumpling Wrapper",
  "Gyoza Wrapper","Shumai Wrapper","Lumpia Wrapper","Mandu Wrapper",
  "Phyllo Dough","Filo Pastry","Puff Pastry","Rough Puff Pastry",
  "Pie Crust","Tart Shell","Pâte Brisée","Pâte Sucrée","Pâte Sablée",
  "Crepe","Crêpe Batter","Galette",
  "Rice Paper Wrapper","Bánh Tráng","Dried Bean Curd Sheet","Tofu Skin","Yuba",
],

legume: [
  // ── Beans ──
  "Black Bean","Dried Black Bean","Canned Black Bean",
  "Kidney Bean","Red Kidney Bean","White Kidney Bean","Canned Kidney Bean",
  "Pinto Bean","Dried Pinto Bean","Canned Pinto Bean","Refried Beans",
  "Navy Bean","Great Northern Bean","Cannellini Bean","White Bean",
  "Lima Bean","Baby Lima Bean","Butter Bean","Gigante Bean",
  "Fava Bean","Broad Bean","Dried Fava Bean","Fresh Fava Bean",
  "Black-Eyed Pea","Dried Black-Eyed Pea","Canned Black-Eyed Pea",
  "Cranberry Bean","Borlotti Bean","Roman Bean",
  "Adzuki Bean","Red Bean","Azuki Bean","Sweet Red Bean Paste","Anko",
  "Mung Bean","Dried Mung Bean","Split Mung Bean","Mung Bean Paste",
  "Garbanzo Bean","Chickpea","Dried Chickpea","Canned Chickpea","Black Chickpea",
  "Lupini Bean","Flageolet Bean","Scarlet Runner Bean","Tepary Bean",
  "Pigeon Pea","Toor Dal","Dried Pigeon Pea",
  "Urad Dal","Black Gram","Whole Urad","Split Urad",
  "Moth Bean","Horse Gram","Kulthi",
  "Fermented Black Bean","Douchi","Salted Black Bean",

  // ── Lentils ──
  "Green Lentil","French Green Lentil","Puy Lentil",
  "Brown Lentil","Pardina Lentil",
  "Red Lentil","Split Red Lentil","Masoor Dal",
  "Yellow Lentil","Moong Dal","Chana Dal",
  "Black Lentil","Beluga Lentil","Urad Dal Whole",
  "Petite Crimson Lentil","Castelluccio Lentil",

  // ── Peas ──
  "Green Split Pea","Yellow Split Pea","Dried Whole Pea",
  "Chickpea Flour","Besan","Gram Flour",
  "Green Pea","Frozen Green Pea","Canned Pea","Petits Pois",
  "Wasabi Pea","Dried Pea","Marrowfat Pea","Mushy Peas",

  // ── Soy Products ──
  "Soybean","Dried Soybean","Fresh Soybean","Black Soybean",
  "Tofu","Firm Tofu","Extra-Firm Tofu","Silken Tofu","Soft Tofu",
  "Medium Tofu","Smoked Tofu","Fried Tofu","Agedashi Tofu","Aburage",
  "Tofu Puff","Dried Tofu","Tofu Stick","Frozen Tofu","Pressed Tofu","Dougan",
  "Fermented Tofu","Stinky Tofu","Tofu Skin","Yuba Sheet","Bean Curd Sheet",
  "Tempeh","Soy Tempeh","Tempeh Block","Tempeh Bacon",
  "Natto","Hikiwari Natto",
  "Soy Milk","Unsweetened Soy Milk","Soy Cream",
  "Soy Protein","Textured Vegetable Protein","TVP","Soy Curl",
  "Soy Flour","Kinako","Roasted Soy Flour",
  "Miso","White Miso","Red Miso","Yellow Miso","Barley Miso","Hatcho Miso","Awase Miso",
  "Edamame","Shelled Edamame","Frozen Edamame","Mukimame",
],

spice: [
  // ── Individual Spices ──
  "Allspice","Whole Allspice","Ground Allspice",
  "Anise Seed","Star Anise","Whole Star Anise",
  "Annatto Seed","Achiote Paste","Annatto Powder",
  "Asafoetida","Hing","Asafoetida Powder",
  "Black Cardamom","Green Cardamom","Cardamom Pod","Ground Cardamom","Cardamom Seed",
  "Black Mustard Seed","Yellow Mustard Seed","Brown Mustard Seed","Mustard Powder",
  "Black Pepper","White Pepper","Green Peppercorn","Pink Peppercorn","Long Pepper",
  "Szechuan Peppercorn","Sichuan Peppercorn","Sansho Pepper","Timut Pepper",
  "Caraway Seed","Caraway","Ground Caraway",
  "Celery Seed","Celery Salt","Ground Celery Seed",
  "Cinnamon","Cinnamon Stick","Ground Cinnamon","Ceylon Cinnamon","Cassia Cinnamon","Saigon Cinnamon",
  "Clove","Whole Clove","Ground Clove",
  "Coriander Seed","Ground Coriander","Whole Coriander",
  "Cumin","Cumin Seed","Ground Cumin","Whole Cumin","Black Cumin","Nigella Seed","Kalonji",
  "Dill Seed","Dill Weed","Dried Dill",
  "Fennel Seed","Ground Fennel","Whole Fennel Seed",
  "Fenugreek Seed","Ground Fenugreek","Fenugreek Leaf","Kasuri Methi","Methi Seed",
  "Galangal Powder","Dried Galangal",
  "Ginger Powder","Ground Ginger","Dried Ginger","Crystallized Ginger","Candied Ginger",
  "Grains of Paradise","Alligator Pepper",
  "Juniper Berry","Dried Juniper",
  "Mace","Ground Mace","Blade Mace",
  "Mahlab","Mahleb",
  "Nutmeg","Whole Nutmeg","Ground Nutmeg",
  "Paprika","Sweet Paprika","Hot Paprika","Smoked Paprika","Pimentón",
  "Hungarian Paprika","Spanish Paprika",
  "Poppy Seed","White Poppy Seed","Black Poppy Seed",
  "Saffron","Saffron Thread","Saffron Powder",
  "Sumac","Ground Sumac",
  "Turmeric","Ground Turmeric","Turmeric Powder","Fresh Turmeric",
  "Vanilla Bean","Vanilla Extract","Vanilla Paste","Vanilla Powder","Vanilla Sugar",
  "Wasabi Powder","Wasabi Paste",

  // ── Chili & Pepper Powders ──
  "Chili Powder","Ancho Chili Powder","Chipotle Powder","Guajillo Powder",
  "Cayenne Pepper","Red Pepper Flakes","Crushed Red Pepper",
  "Gochugaru","Korean Chili Flakes","Korean Red Pepper Powder",
  "Aleppo Pepper Flakes","Urfa Biber","Maras Pepper","Pul Biber",
  "Kashmiri Chili Powder","Kashmiri Mirch",
  "Togarashi","Shichimi Togarashi","Ichimi Togarashi","Nanami Togarashi",
  "Calabrian Chili","Peperoncino","Dried Chili","Dried Thai Chili","Dried Arbol Chili",
  "Chile de Árbol","Chile Pasilla","Chile Guajillo","Chile Ancho",
  "Chipotle in Adobo","Chipotles en Adobo",

  // ── Spice Blends ──
  "Garam Masala","Chaat Masala","Tandoori Masala","Biryani Masala","Panch Phoron",
  "Madras Curry Powder","Curry Powder","Mild Curry Powder","Hot Curry Powder",
  "Ras el Hanout","Baharat","Berbere","Mitmita","Suya Spice",
  "Chinese Five Spice","Five Spice Powder","Thirteen Spice","Shichimi",
  "Za'atar","Dukkah","Hawaiian Salt","Fleur de Sel",
  "Italian Seasoning","Herbs de Provence","Fines Herbes","Bouquet Garni",
  "Old Bay Seasoning","Cajun Seasoning","Creole Seasoning","Blackening Seasoning",
  "Taco Seasoning","Fajita Seasoning","Chili Seasoning","Adobo Seasoning",
  "Jerk Seasoning","Jamaican Jerk Spice","Caribbean Seasoning",
  "Pumpkin Pie Spice","Apple Pie Spice","Chai Spice","Mulling Spice",
  "Everything Bagel Seasoning","Ranch Seasoning","Garlic Salt","Onion Salt",
  "Seasoned Salt","Lawry's Seasoning","Lemon Pepper","Garlic Pepper",
  "Poultry Seasoning","Sage and Onion Stuffing Mix",
  "Dashi Powder","Hondashi","Kombu Dashi Powder",
  "Furikake","Nori Furikake","Wasabi Furikake","Shiso Furikake",
  "Khmeli Suneli","Advieh","Hawaij","Zhug Spice",
  "Rendang Paste","Laksa Paste","Tom Yum Paste","Tom Kha Paste",
  "Massaman Curry Paste","Panang Curry Paste",
  "Sambar Powder","Rasam Powder","Chole Masala","Kitchen King Masala",
  "Shawarma Spice","Kebab Spice","Doner Spice","Gyros Seasoning",
],

herb: [
  "Basil","Sweet Basil","Thai Basil","Holy Basil","Purple Basil","Lemon Basil","Genovese Basil",
  "Cilantro","Fresh Cilantro","Dried Cilantro","Cilantro Root",
  "Parsley","Flat-Leaf Parsley","Italian Parsley","Curly Parsley","Dried Parsley",
  "Mint","Spearmint","Peppermint","Chocolate Mint","Vietnamese Mint","Dried Mint",
  "Dill","Fresh Dill","Dill Frond",
  "Oregano","Fresh Oregano","Dried Oregano","Mexican Oregano","Greek Oregano",
  "Thyme","Fresh Thyme","Dried Thyme","Lemon Thyme",
  "Rosemary","Fresh Rosemary","Dried Rosemary",
  "Sage","Fresh Sage","Dried Sage","Rubbed Sage",
  "Tarragon","French Tarragon","Dried Tarragon",
  "Chive","Fresh Chive","Dried Chive","Garlic Chive",
  "Bay Leaf","Fresh Bay Leaf","Dried Bay Leaf","Turkish Bay Leaf","California Bay Leaf","Indian Bay Leaf","Tej Patta",
  "Lemongrass","Dried Lemongrass","Lemongrass Paste",
  "Marjoram","Sweet Marjoram","Dried Marjoram",
  "Lavender","Culinary Lavender","Dried Lavender","Lavender Bud",
  "Chervil","Fresh Chervil",
  "Savory","Summer Savory","Winter Savory",
  "Lovage","Lovage Leaf",
  "Borage","Borage Flower","Borage Leaf",
  "Lemon Balm","Lemon Verbena",
  "Kaffir Lime Leaf","Makrut Lime Leaf","Dried Lime Leaf",
  "Pandan Leaf","Frozen Pandan","Pandan Extract","Pandan Paste",
  "Curry Leaf","Fresh Curry Leaf","Dried Curry Leaf",
  "Shiso","Green Shiso Leaf","Red Shiso Leaf",
  "Perilla","Korean Perilla Leaf",
  "Vietnamese Coriander","Laksa Leaf","Rau Ram Leaf",
  "Mugwort","Ssuk","Korean Mugwort",
  "Woodruff","Sweet Woodruff",
  "Hyssop","Anise Hyssop",
  "Rue","Fresh Rue",
  "Sassafras","File Powder",
],

oil: [
  "Olive Oil","Extra Virgin Olive Oil","Virgin Olive Oil","Light Olive Oil","Garlic Olive Oil",
  "Lemon Olive Oil","Chili Olive Oil","Truffle Olive Oil","Basil Olive Oil",
  "Vegetable Oil","Canola Oil","Rapeseed Oil",
  "Sunflower Oil","High-Oleic Sunflower Oil",
  "Corn Oil","Soybean Oil","Safflower Oil",
  "Peanut Oil","Roasted Peanut Oil",
  "Sesame Oil","Toasted Sesame Oil","Light Sesame Oil","Black Sesame Oil",
  "Coconut Oil","Virgin Coconut Oil","Refined Coconut Oil","MCT Oil",
  "Avocado Oil","Grapeseed Oil","Rice Bran Oil","Palm Oil","Red Palm Oil",
  "Walnut Oil","Almond Oil","Hazelnut Oil","Pistachio Oil","Pecan Oil","Macadamia Oil",
  "Flaxseed Oil","Hemp Seed Oil","Pumpkin Seed Oil","Perilla Oil",
  "Mustard Oil","Indian Mustard Oil","Black Mustard Oil",
  "Tea Seed Oil","Camellia Oil",
  "Duck Fat","Goose Fat","Lard","Beef Tallow","Bacon Grease","Schmaltz",
  "Cooking Spray","Nonstick Spray","Olive Oil Spray",
  "Chili Oil","Sichuan Chili Oil","La You","Rayu","Crispy Chili Oil",
  "Garlic Oil","Infused Oil","Herb Oil","Scallion Oil",
],

vinegar: [
  "White Vinegar","Distilled White Vinegar",
  "Apple Cider Vinegar","Raw Apple Cider Vinegar",
  "Red Wine Vinegar","White Wine Vinegar","Champagne Vinegar","Sherry Vinegar","Port Vinegar",
  "Balsamic Vinegar","Aged Balsamic Vinegar","White Balsamic Vinegar","Balsamic Glaze","Balsamic Reduction",
  "Rice Vinegar","Seasoned Rice Vinegar","Unseasoned Rice Vinegar",
  "Chinese Black Vinegar","Chinkiang Vinegar","Zhenjiang Vinegar",
  "Malt Vinegar","Beer Vinegar",
  "Coconut Vinegar","Cane Vinegar","Sugarcane Vinegar","Sukang Iloco","Sukang Tuba",
  "Palm Vinegar","Toddy Vinegar",
  "Persimmon Vinegar","Plum Vinegar","Ume Vinegar","Umeboshi Vinegar",
  "Pomegranate Vinegar","Date Vinegar","Fig Vinegar","Raspberry Vinegar",
  "Tarragon Vinegar","Herb Vinegar","Garlic Vinegar",
  "Black Vinegar","Brown Rice Vinegar","Korean Vinegar",
  "Verjuice","Saba","Vincotto",
],

sauce: [
  // ── Soy-Based ──
  "Soy Sauce","Light Soy Sauce","Dark Soy Sauce","Double Black Soy Sauce",
  "Tamari","Gluten-Free Tamari","Low-Sodium Soy Sauce","Mushroom Soy Sauce",
  "Sweet Soy Sauce","Kecap Manis","Kecap Asin","Indonesian Soy Sauce",
  "Japanese Soy Sauce","Koikuchi Shoyu","Usukuchi Shoyu","Shiro Shoyu","White Soy Sauce",
  "Korean Soy Sauce","Ganjang","Soup Soy Sauce","Yangjo Ganjang",
  "Ponzu","Ponzu Sauce","Yuzu Ponzu",
  "Teriyaki Sauce","Teriyaki Glaze","Teriyaki Marinade",
  "Yakitori Sauce","Tare","Yakiniku Sauce",
  "Unagi Sauce","Eel Sauce","Kabayaki Sauce",
  "Tonkatsu Sauce","Bulldog Sauce","Japanese Curry Sauce",

  // ── Fish Sauce & Shrimp ──
  "Fish Sauce","Thai Fish Sauce","Vietnamese Fish Sauce","Nuoc Mam","Nam Pla","Patis",
  "Anchovy Sauce","Colatura di Alici","Garum",
  "Oyster Sauce","Vegetarian Oyster Sauce","Mushroom Oyster Sauce","Premium Oyster Sauce",
  "Shrimp Paste","Fermented Shrimp Paste","Belacan","Kapi","Mam Ruoc","Bagoong",
  "XO Sauce","Dried Shrimp Sauce",

  // ── Chili Sauces ──
  "Sriracha","Sriracha Sauce","Sambal","Sambal Oelek","Sambal Badjak","Sambal Manis",
  "Gochujang","Korean Chili Paste","Doenjang","Korean Soybean Paste",
  "Chili Garlic Sauce","Sweet Chili Sauce","Thai Sweet Chili Sauce",
  "Tabasco","Frank's Red Hot","Louisiana Hot Sauce","Cholula",
  "Harissa","Harissa Paste","Harissa Sauce","Rose Harissa",
  "Piri Piri Sauce","Peri Peri Sauce",
  "Chipotle Sauce","Adobo Sauce","Enchilada Sauce","Red Enchilada Sauce","Green Enchilada Sauce",
  "Salsa Roja","Salsa Verde","Tomatillo Salsa","Pico de Gallo","Salsa Macha",
  "Zhug","Schug","Zhoug",
  "Chili Crisp","Lao Gan Ma","Fly by Jing",
  "Doubanjiang","Pixian Doubanjiang","Broad Bean Paste","Spicy Bean Paste",
  "Chili Bean Sauce","Toban Djan",
  "Nam Prik","Thai Chili Jam","Nam Prik Pao",
  "Aji Sauce","Aji Verde","Aji Amarillo Sauce",

  // ── Fermented & Paste Sauces ──
  "Miso Paste","White Miso Paste","Red Miso Paste","Mixed Miso Paste",
  "Hoisin Sauce","Plum Sauce","Duck Sauce","Sweet Bean Sauce","Tianmian Sauce",
  "Black Bean Sauce","Fermented Black Bean Sauce",
  "Char Siu Sauce","Chinese BBQ Sauce","Shacha Sauce","Sa Cha Sauce",
  "Satay Sauce","Peanut Sauce","Thai Peanut Sauce",
  "Tamarind Sauce","Tamarind Chutney","Imli Chutney",
  "Tteokbokki Sauce","Ssamjang","Chogochujang",

  // ── Western Sauces ──
  "Worcestershire Sauce","HP Sauce","Brown Sauce","A1 Sauce","Steak Sauce",
  "Barbecue Sauce","BBQ Sauce","Kansas City BBQ Sauce","Carolina BBQ Sauce",
  "Hickory BBQ Sauce","Honey BBQ Sauce","Smoky BBQ Sauce",
  "Ketchup","Tomato Ketchup","Banana Ketchup","Mushroom Ketchup",
  "Tomato Sauce","Marinara Sauce","Pasta Sauce","Bolognese Sauce","Arrabbiata Sauce",
  "Alfredo Sauce","Pesto","Basil Pesto","Sun-Dried Tomato Pesto","Red Pesto",
  "Romesco Sauce","Chimichurri","Chimichurri Sauce","Salsa Criolla",
  "Béarnaise Sauce","Hollandaise Sauce","Béchamel Sauce","Mornay Sauce",
  "Velouté","Espagnole Sauce","Demi-Glace",
  "Gravy","Brown Gravy","Turkey Gravy","Mushroom Gravy","Onion Gravy","Gravy Granules",
  "Cranberry Sauce","Mint Sauce","Apple Sauce","Horseradish Sauce","Bread Sauce",
  "Tartare Sauce","Remoulade","Cocktail Sauce","Thousand Island Dressing",
  "Ranch Dressing","Caesar Dressing","Blue Cheese Dressing","Italian Dressing",
  "Vinaigrette","Balsamic Vinaigrette","French Dressing","Russian Dressing",
  "Green Goddess Dressing","Tahini Dressing","Miso Dressing","Ginger Dressing",
  "Carrot Ginger Dressing","Wafu Dressing","Sesame Dressing",
],

condiment: [
  // ── Mustards ──
  "Yellow Mustard","Dijon Mustard","Whole Grain Mustard","Stone Ground Mustard",
  "English Mustard","Chinese Mustard","German Mustard","Bavarian Mustard",
  "Honey Mustard","Spicy Brown Mustard","Creole Mustard","Karashi","Japanese Mustard",

  // ── Pickles & Preserves ──
  "Dill Pickle","Bread and Butter Pickle","Sweet Pickle","Cornichon","Gherkin",
  "Pickled Jalapeño","Pickled Onion","Pickled Red Onion","Pickled Ginger","Gari",
  "Beni Shoga","Red Pickled Ginger","Pickled Radish","Takuan","Danmuji",
  "Pickled Plum","Umeboshi","Pickled Garlic","Torshi",
  "Sauerkraut","Raw Sauerkraut","Kimchi","Napa Cabbage Kimchi","Radish Kimchi",
  "Kkakdugi","Cucumber Kimchi","Oi Sobagi","Water Kimchi","Mul Kimchi",
  "Pickled Bamboo Shoot","Pickled Mustard Green","Zha Cai","Sichuan Pickle",
  "Achaar","Indian Pickle","Mango Pickle","Lime Pickle","Mixed Pickle",
  "Tsukemono","Nukazuke","Asazuke","Shiozuke","Misozuke",

  // ── Pastes ──
  "Tomato Paste","Double Concentrated Tomato Paste","Sun-Dried Tomato Paste",
  "Red Curry Paste","Green Curry Paste","Yellow Curry Paste","Massaman Curry Paste","Panang Curry Paste",
  "Curry Paste","Indian Curry Paste","Vindaloo Paste","Korma Paste","Tikka Paste","Tandoori Paste",
  "Tahini","Tahini Paste","Black Tahini",
  "Garlic Paste","Ginger Paste","Ginger Garlic Paste","Lemongrass Paste",
  "Shrimp Paste","Anchovy Paste","Olive Tapenade","Black Olive Tapenade","Green Olive Tapenade",
  "Sofrito","Recaíto","Adodo Paste",
  "Wasabi Paste","Yuzu Kosho","Yuzu Paste",
  "Preserved Lemon Paste","Amba","Date Syrup",

  // ── Chutneys & Relishes ──
  "Mango Chutney","Mint Chutney","Cilantro Chutney","Tamarind Chutney","Coconut Chutney",
  "Tomato Chutney","Onion Chutney","Date Chutney","Apple Chutney","Cranberry Chutney",
  "Sweet Pickle Relish","Hot Dog Relish","Corn Relish","Pepper Relish",
  "Ajvar","Muhammara","Matbucha",

  // ── Olives & Capers ──
  "Green Olive","Kalamata Olive","Black Olive","Castelvetrano Olive","Cerignola Olive",
  "Niçoise Olive","Picholine Olive","Manzanilla Olive","Stuffed Olive",
  "Olive Brine","Caper","Salt-Packed Caper","Caper Berry","Caper Brine",

  // ── Other Condiments ──
  "Mayonnaise","Japanese Mayonnaise","Kewpie Mayonnaise","Vegan Mayonnaise",
  "Light Mayonnaise","Garlic Mayonnaise","Aioli","Chipotle Mayo",
  "Hummus","Classic Hummus","Roasted Red Pepper Hummus","Garlic Hummus",
  "Guacamole","Baba Ganoush","Muhammara","Labneh Dip",
  "Nutritional Yeast","Liquid Aminos","Bragg's Aminos","Coconut Aminos",
  "MSG","Monosodium Glutamate","Umami Seasoning",
],

baking: [
  // ── Flours ──
  "All-Purpose Flour","Bread Flour","Cake Flour","Pastry Flour","Self-Rising Flour",
  "Whole Wheat Flour","White Whole Wheat Flour","Whole Wheat Pastry Flour",
  "Almond Flour","Almond Meal","Coconut Flour","Oat Flour","Rice Flour",
  "Glutinous Rice Flour","Mochiko","Tapioca Flour","Tapioca Starch",
  "Potato Starch","Corn Starch","Arrowroot Starch","Arrowroot Powder",
  "Chickpea Flour","Besan","Gram Flour","Soy Flour",
  "Rye Flour","Dark Rye Flour","Pumpernickel Flour",
  "Buckwheat Flour","Teff Flour","Millet Flour","Sorghum Flour","Amaranth Flour",
  "Cassava Flour","Plantain Flour","Banana Flour",
  "Semolina Flour","Tipo 00 Flour","Durum Flour",
  "Gluten-Free Flour Blend","Cup4Cup","Bob's Red Mill GF Flour",
  "Vital Wheat Gluten","Seitan Flour",

  // ── Sugars & Sweeteners ──
  "Granulated Sugar","White Sugar","Caster Sugar","Superfine Sugar",
  "Brown Sugar","Light Brown Sugar","Dark Brown Sugar","Muscovado Sugar",
  "Demerara Sugar","Turbinado Sugar","Raw Sugar","Sucanat",
  "Powdered Sugar","Confectioners Sugar","Icing Sugar",
  "Palm Sugar","Coconut Sugar","Coconut Palm Sugar","Jaggery","Gur","Panela","Piloncillo",
  "Maple Syrup","Dark Maple Syrup","Grade A Maple Syrup",
  "Honey","Raw Honey","Manuka Honey","Acacia Honey","Buckwheat Honey","Clover Honey",
  "Agave Nectar","Light Agave","Dark Agave",
  "Corn Syrup","Light Corn Syrup","Dark Corn Syrup","Golden Syrup","Treacle","Black Treacle",
  "Molasses","Light Molasses","Dark Molasses","Blackstrap Molasses",
  "Rice Syrup","Brown Rice Syrup","Malt Syrup","Barley Malt Syrup",
  "Date Syrup","Silan","Pomegranate Molasses",
  "Stevia","Monk Fruit Sweetener","Erythritol","Xylitol","Allulose",
  "Simple Syrup","Rich Simple Syrup","Demerara Syrup",

  // ── Chocolate & Cocoa ──
  "Cocoa Powder","Dutch-Process Cocoa","Natural Cocoa Powder","Black Cocoa Powder",
  "Dark Chocolate","Bittersweet Chocolate","Semisweet Chocolate",
  "Milk Chocolate","White Chocolate","Ruby Chocolate",
  "Chocolate Chips","Dark Chocolate Chips","Milk Chocolate Chips","White Chocolate Chips",
  "Mini Chocolate Chips","Chocolate Chunk","Cacao Nibs","Raw Cacao Powder",
  "Unsweetened Chocolate","Baker's Chocolate","Chocolate Bar",
  "Couverture Chocolate","Chocolate Ganache","Chocolate Sauce",
  "Cocoa Butter","Cacao Butter",
  "Carob","Carob Powder","Carob Chips",

  // ── Leaveners ──
  "Baking Powder","Double-Acting Baking Powder","Aluminum-Free Baking Powder",
  "Baking Soda","Bicarbonate of Soda",
  "Active Dry Yeast","Instant Yeast","Rapid-Rise Yeast","Fresh Yeast","Cake Yeast",
  "Sourdough Starter","Levain","Cream of Tartar",

  // ── Extracts & Flavorings ──
  "Vanilla Extract","Pure Vanilla Extract","Imitation Vanilla","Vanilla Bean Paste",
  "Almond Extract","Lemon Extract","Orange Extract","Peppermint Extract",
  "Coconut Extract","Rum Extract","Maple Extract","Banana Extract",
  "Rose Water","Orange Blossom Water","Kewra Water",
  "Almond Essence","Pandan Extract",
  "Lemon Zest","Orange Zest","Lime Zest","Grapefruit Zest","Yuzu Zest",
  "Citric Acid","Tartaric Acid","Ascorbic Acid",

  // ── Gelatin & Thickeners ──
  "Gelatin","Gelatin Powder","Gelatin Sheet","Leaf Gelatin",
  "Agar Agar","Agar Powder","Agar Flakes",
  "Pectin","Apple Pectin","Citrus Pectin","Low-Sugar Pectin",
  "Xanthan Gum","Guar Gum","Locust Bean Gum","Konjac Powder",
  "Cornstarch","Modified Food Starch","Instant ClearJel",

  // ── Decorating ──
  "Sprinkles","Nonpareils","Jimmies","Sanding Sugar","Pearl Sugar",
  "Fondant","Rolled Fondant","Marzipan","Almond Paste",
  "Food Coloring","Gel Food Color","Edible Glitter","Luster Dust",
  "Meringue Powder","Royal Icing Mix","Candy Melts",
  "Edible Flower","Crystallized Violet","Candied Rose Petal",
],

nut: [
  // ── Tree Nuts ──
  "Almond","Whole Almond","Sliced Almond","Slivered Almond","Blanched Almond",
  "Marcona Almond","Smoked Almond","Roasted Almond","Raw Almond",
  "Walnut","Walnut Half","Walnut Piece","Black Walnut","Candied Walnut",
  "Pecan","Pecan Half","Chopped Pecan","Candied Pecan","Spiced Pecan",
  "Cashew","Raw Cashew","Roasted Cashew","Cashew Piece",
  "Pistachio","Shelled Pistachio","Roasted Pistachio","Raw Pistachio",
  "Macadamia Nut","Roasted Macadamia",
  "Hazelnut","Blanched Hazelnut","Roasted Hazelnut","Hazelnut Meal",
  "Brazil Nut","Pine Nut","Pignoli",
  "Chestnut","Roasted Chestnut","Chestnut Puree","Candied Chestnut","Marron Glacé",
  "Coconut","Shredded Coconut","Coconut Flake","Toasted Coconut","Coconut Chip",
  "Desiccated Coconut","Creamed Coconut","Coconut Cream","Coconut Milk",
  "Coconut Cream Concentrate","Coconut Butter",
  "Tiger Nut","Chufa",

  // ── Peanuts ──
  "Peanut","Raw Peanut","Roasted Peanut","Boiled Peanut","Spanish Peanut",
  "Virginia Peanut","Redskin Peanut","Peanut Butter","Creamy Peanut Butter",
  "Crunchy Peanut Butter","Natural Peanut Butter","Peanut Flour","Peanut Powder",

  // ── Seeds ──
  "Sesame Seed","White Sesame Seed","Black Sesame Seed","Toasted Sesame Seed",
  "Sunflower Seed","Raw Sunflower Seed","Roasted Sunflower Seed",
  "Pumpkin Seed","Pepita","Raw Pepita","Roasted Pepita",
  "Flax Seed","Ground Flax Seed","Flax Meal","Golden Flax Seed",
  "Chia Seed","White Chia Seed","Black Chia Seed",
  "Hemp Seed","Hemp Heart","Shelled Hemp Seed",
  "Poppy Seed","Nigella Seed","Black Seed",
  "Watermelon Seed","Lotus Seed","Dried Lotus Seed",
  "Pine Nut","Fennel Seed","Caraway Seed","Cumin Seed","Coriander Seed",
  "Mustard Seed","Celery Seed","Dill Seed","Anise Seed","Fenugreek Seed",

  // ── Nut Butters & Milks ──
  "Almond Butter","Cashew Butter","Hazelnut Spread","Nutella",
  "Sunflower Seed Butter","Tahini","Pistachio Butter","Pecan Butter","Walnut Butter",
  "Almond Milk","Unsweetened Almond Milk","Vanilla Almond Milk",
  "Cashew Milk","Oat Milk","Hemp Milk","Macadamia Milk","Pistachio Milk",
  "Coconut Milk","Full-Fat Coconut Milk","Light Coconut Milk","Coconut Cream",
  "Coconut Milk Powder","Coconut Water",
],

beverage: [
  // ── Stocks & Broths ──
  "Chicken Stock","Chicken Broth","Low-Sodium Chicken Broth",
  "Beef Stock","Beef Broth","Low-Sodium Beef Broth","Bone Broth",
  "Vegetable Stock","Vegetable Broth","Mushroom Stock","Mushroom Broth",
  "Fish Stock","Dashi","Dashi Stock","Kombu Dashi","Bonito Dashi","Anchovy Stock",
  "Seafood Stock","Clam Juice","Clam Broth","Court Bouillon",
  "Ham Stock","Pork Stock","Tonkotsu Broth","Turkey Stock","Lamb Stock",
  "Bouillon Cube","Chicken Bouillon","Beef Bouillon","Vegetable Bouillon",
  "Stock Concentrate","Better Than Bouillon",

  // ── Wine ──
  "White Wine","Dry White Wine","Sauvignon Blanc","Pinot Grigio","Chardonnay","Riesling",
  "Red Wine","Dry Red Wine","Cabernet Sauvignon","Merlot","Pinot Noir","Chianti",
  "Rosé Wine","Sparkling Wine","Prosecco","Champagne","Cava",
  "Marsala Wine","Dry Marsala","Sweet Marsala",
  "Madeira Wine","Port Wine","Ruby Port","Tawny Port",
  "Sherry","Dry Sherry","Fino Sherry","Cream Sherry","Amontillado Sherry",
  "Vermouth","Dry Vermouth","Sweet Vermouth",
  "Mirin","Hon Mirin","Aji Mirin",
  "Shaoxing Wine","Chinese Rice Wine","Huangjiu","Michiu",
  "Sake","Cooking Sake","Ryorishu","Junmai Sake",
  "Rice Wine","Korean Rice Wine","Cheongju","Makgeolli",

  // ── Spirits ──
  "Vodka","Rum","White Rum","Dark Rum","Spiced Rum","Coconut Rum",
  "Bourbon","Whiskey","Scotch Whisky","Rye Whiskey","Irish Whiskey",
  "Brandy","Cognac","Armagnac","Calvados","Apple Brandy","Pisco",
  "Tequila","Blanco Tequila","Reposado Tequila","Mezcal",
  "Gin","Dry Gin","Sloe Gin",
  "Grand Marnier","Cointreau","Triple Sec","Orange Liqueur",
  "Kahlúa","Coffee Liqueur","Amaretto","Frangelico","Limoncello",
  "Kirsch","Kirschwasser","Maraschino Liqueur","Crème de Cassis",
  "Sambuca","Anise Liqueur","Pastis","Ouzo","Arak","Raki",
  "Absinthe","Chartreuse","Bénédictine",
  "Baijiu","Soju","Shochu","Awamori",

  // ── Beer ──
  "Beer","Lager","Pale Ale","IPA","Stout","Porter","Wheat Beer",
  "Belgian Ale","Pilsner","Amber Ale","Brown Ale","Dark Beer",

  // ── Juices ──
  "Lemon Juice","Fresh Lemon Juice","Bottled Lemon Juice",
  "Lime Juice","Fresh Lime Juice","Key Lime Juice",
  "Orange Juice","Fresh Orange Juice",
  "Grapefruit Juice","Pineapple Juice","Cranberry Juice","Pomegranate Juice",
  "Apple Juice","Apple Cider","Pear Juice","Grape Juice","Tomato Juice",
  "Coconut Water","Coconut Cream","Tamarind Juice",
  "Yuzu Juice","Calamansi Juice","Passion Fruit Juice","Guava Juice","Mango Juice",
  "Carrot Juice","Celery Juice","Beet Juice","Ginger Juice",
  "Aloe Vera Juice","Sugarcane Juice",

  // ── Tea & Coffee ──
  "Green Tea","Matcha","Matcha Powder","Ceremonial Matcha","Culinary Matcha",
  "Black Tea","Earl Grey","English Breakfast Tea","Assam Tea","Darjeeling Tea",
  "Oolong Tea","Jasmine Tea","Chrysanthemum Tea","Chamomile Tea","Rooibos Tea",
  "Hibiscus Tea","Butterfly Pea Flower Tea","Thai Tea Mix","Chai Tea",
  "Pu-erh Tea","Genmaicha","Hojicha",
  "Coffee","Espresso","Instant Coffee","Coffee Powder","Cold Brew Coffee",
  "Turkish Coffee","Vietnamese Coffee","Chicory Coffee","Decaf Coffee",

  // ── Other ──
  "Water","Sparkling Water","Soda Water","Tonic Water","Club Soda",
  "Milk","Plant Milk","Oat Milk","Soy Milk","Almond Milk","Rice Milk",
  "Horchata","Agua de Jamaica","Agua Fresca",
],

misc: [
  // ── Canned Goods ──
  "Canned Tomato","Crushed Tomato","Diced Tomato","Whole Peeled Tomato",
  "Stewed Tomato","Fire-Roasted Tomato","Tomato Puree","Tomato Passata",
  "Sun-Dried Tomato","Sun-Dried Tomato in Oil",
  "Canned Coconut Milk","Canned Coconut Cream","Cream of Coconut",
  "Canned Pumpkin","Pumpkin Puree","Canned Sweet Potato",
  "Canned Artichoke Heart","Canned Heart of Palm",
  "Canned Corn","Creamed Corn","Canned Hominy",
  "Canned Bean","Canned Mixed Bean","Canned Baked Bean",
  "Canned Water Chestnut","Canned Bamboo Shoot","Canned Baby Corn",
  "Canned Jackfruit","Canned Lychee","Canned Mandarin","Canned Pineapple",
  "Canned Peach","Canned Pear","Fruit Cocktail",
  "Canned Chipotle in Adobo","Canned Green Chile","Canned Roasted Pepper",
  "Roasted Red Pepper","Fire-Roasted Red Pepper",
  "Canned Pimento",

  // ── Dried & Preserved ──
  "Dried Mushroom","Dried Porcini","Dried Shiitake","Dried Wood Ear",
  "Dried Chili","Dried Thai Chili","Dried Ancho","Dried Guajillo","Dried Arbol",
  "Dried Pasilla","Dried Chipotle","Dried Habanero","Dried Cascabel",
  "Dried Shrimp","Dried Scallop","Dried Fish","Dried Anchovy","Dried Squid",
  "Dried Seaweed","Dried Kombu","Dried Wakame","Dried Nori",
  "Dried Tofu","Dried Bean Curd Stick","Dried Bean Curd Sheet",
  "Dried Lily Flower","Dried Lotus Leaf","Dried Tangerine Peel","Chen Pi",
  "Dried Red Date","Dried Wolfberry","Goji Berry",
  "Dried Rose Petal","Dried Hibiscus Flower","Dried Lavender Bud",
  "Rock Sugar","Yellow Rock Sugar","Chinese Rock Sugar",
  "Palm Sugar","Thai Palm Sugar",

  // ── Frozen ──
  "Frozen Pea","Frozen Corn","Frozen Mixed Vegetable","Frozen Spinach",
  "Frozen Broccoli","Frozen Cauliflower","Frozen Green Bean",
  "Frozen Berry","Frozen Strawberry","Frozen Blueberry","Frozen Raspberry","Frozen Mango",
  "Frozen Banana","Frozen Pineapple","Frozen Peach","Frozen Açaí",
  "Frozen Shrimp","Frozen Fish Fillet","Frozen Calamari",
  "Frozen Dumpling","Frozen Gyoza","Frozen Wonton","Frozen Spring Roll",
  "Frozen Puff Pastry","Frozen Pie Crust","Frozen Phyllo",
  "Frozen Edamame","Frozen Tofu","Frozen Roti Prata",
  "Frozen Udon","Frozen Ramen",

  // ── Tofu & Plant-Based ──
  "Seitan","Wheat Gluten","Vital Wheat Gluten",
  "Jackfruit Meat","Pulled Jackfruit",
  "Beyond Meat","Impossible Burger","Plant-Based Ground","Plant-Based Sausage",
  "Vegan Cheese","Vegan Cream Cheese","Vegan Sour Cream",
  "Nutritional Yeast Flake","Brewer's Yeast",
  "Aquafaba","Chickpea Water",
  "Flax Egg","Chia Egg",

  // ── Wrappers & Specialty ──
  "Banana Leaf","Lotus Leaf","Corn Husk","Dried Corn Husk","Ti Leaf",
  "Bamboo Skewer","Wooden Skewer","Metal Skewer","Toothpick",
  "Parchment Paper","Cheesecloth","Butcher Twine","Kitchen String",
  "Charcoal","Binchotan","Lump Charcoal","Wood Chip","Smoking Chip",
  "Liquid Smoke","Hickory Liquid Smoke","Mesquite Liquid Smoke",

  // ── Salts ──
  "Sea Salt","Fine Sea Salt","Coarse Sea Salt",
  "Kosher Salt","Diamond Crystal Kosher Salt","Morton Kosher Salt",
  "Table Salt","Iodized Salt","Pickling Salt",
  "Himalayan Pink Salt","Black Salt","Kala Namak",
  "Flaky Salt","Maldon Salt","Fleur de Sel",
  "Smoked Salt","Truffle Salt","Garlic Salt","Celery Salt","Onion Salt",
  "Seasoned Salt","Old Bay","Tajín",

  // ── Miscellaneous ──
  "Ice","Crushed Ice","Ice Cube",
  "Cooking Wine","Shaoxing Cooking Wine",
  "Food Starch","Modified Starch","Potato Starch","Sweet Potato Starch",
  "Kuzu Starch","Kudzu Starch",
  "Konnyaku","Shirataki","Konjac",
  "Panko","Japanese Panko","Italian Breadcrumb",
  "Tempura Batter Mix","Frying Flour","Korean Frying Mix",
  "Wonton Wrapper","Spring Roll Wrapper","Dumpling Skin","Mandu Wrapper",
  "Egg Roll Wrapper","Rice Paper","Bánh Tráng",
  "Noodle Soup Base","Instant Noodle Seasoning","Curry Roux","Japanese Curry Block",
  "Bouillon Powder","Mushroom Powder","Chicken Powder","Dashi Packet",
  "Coconut Aminos","Liquid Aminos","Maggi Seasoning","Golden Mountain Sauce",
],

};
