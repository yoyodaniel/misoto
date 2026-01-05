//
//  UnitTranslations.swift
//  Misoto
//
//  Hardcoded translations for all cooking units
//  Since unit names are universal, we can use static translations instead of localization files
//

import Foundation

class UnitTranslations {
    /// Dictionary mapping English unit keys to translations in all supported languages
    static let translations: [String: [String: String]] = [
        // Empty unit (no unit)
        "": [
            "en": "-",
            "zh-Hans": "-",
            "zh-Hant": "-",
            "es": "-",
            "fr": "-",
            "de": "-",
            "it": "-",
            "pt": "-",
            "nl": "-",
            "ru": "-",
            "ja": "-",
            "ko": "-",
            "th": "-",
            "vi": "-",
            "id": "-",
            "ms": "-",
            "fil": "-",
            "hi": "-",
            "ar": "-",
            "he": "-"
        ],
        // Multiplier (x)
        "x": [
            "en": "x",
            "zh-Hans": "x",
            "zh-Hant": "x",
            "es": "x",
            "fr": "x",
            "de": "x",
            "it": "x",
            "pt": "x",
            "nl": "x",
            "ru": "x",
            "ja": "x",
            "ko": "x",
            "th": "x",
            "vi": "x",
            "id": "x",
            "ms": "x",
            "fil": "x",
            "hi": "x",
            "ar": "x",
            "he": "x"
        ],
        // Teaspoon
        "tsp": [
            "en": "Teaspoon (tsp)",
            "zh-Hans": "茶匙 (tsp)",
            "zh-Hant": "茶匙 (tsp)",
            "es": "Cucharadita (cdta)",
            "fr": "Cuillère à café (c. à c.)",
            "de": "Teelöffel (TL)",
            "it": "Cucchiaino (cucch.)",
            "pt": "Colher de chá (c. chá)",
            "nl": "Theelepel (tl)",
            "ru": "Чайная ложка (ч. л.)",
            "ja": "小さじ (小さじ)",
            "ko": "작은 술 (작은 술)",
            "th": "ช้อนชา (ชช.)",
            "vi": "Thìa cà phê (thìa cà phê)",
            "id": "Sendok teh (sdt)",
            "ms": "Sudu teh (sdt)",
            "fil": "Kutsarita (kuts.)",
            "hi": "चम्मच (चम्मच)",
            "ar": "ملعقة صغيرة (ملعقة صغيرة)",
            "he": "כפית (כפית)"
        ],
        // Tablespoon
        "tbsp": [
            "en": "Tablespoon (tbsp)",
            "zh-Hans": "汤匙 (tbsp)",
            "zh-Hant": "湯匙 (tbsp)",
            "es": "Cucharada (cda)",
            "fr": "Cuillère à soupe (c. à s.)",
            "de": "Esslöffel (EL)",
            "it": "Cucchiaio (cucch.)",
            "pt": "Colher de sopa (c. sopa)",
            "nl": "Eetlepel (el)",
            "ru": "Столовая ложка (ст. л.)",
            "ja": "大さじ (大さじ)",
            "ko": "큰 술 (큰 술)",
            "th": "ช้อนโต๊ะ (ชต.)",
            "vi": "Thìa canh (thìa canh)",
            "id": "Sendok makan (sdm)",
            "ms": "Sudu besar (sdm)",
            "fil": "Kutsara (kuts.)",
            "hi": "बड़ा चम्मच (बड़ा चम्मच)",
            "ar": "ملعقة كبيرة (ملعقة كبيرة)",
            "he": "כף (כף)"
        ],
        // Cup
        "cup": [
            "en": "Cup",
            "zh-Hans": "杯",
            "zh-Hant": "杯",
            "es": "Taza",
            "fr": "Tasse",
            "de": "Tasse",
            "it": "Tazza",
            "pt": "Xícara",
            "nl": "Kopje",
            "ru": "Чашка",
            "ja": "カップ",
            "ko": "컵",
            "th": "ถ้วย",
            "vi": "Cốc",
            "id": "Cangkir",
            "ms": "Cawan",
            "fil": "Tasa",
            "hi": "कप",
            "ar": "كوب",
            "he": "כוס"
        ],
        // Ounce
        "oz": [
            "en": "Ounce (oz)",
            "zh-Hans": "盎司 (oz)",
            "zh-Hant": "盎司 (oz)",
            "es": "Onza (oz)",
            "fr": "Once (oz)",
            "de": "Unze (oz)",
            "it": "Oncia (oz)",
            "pt": "Onça (oz)",
            "nl": "Ons (oz)",
            "ru": "Унция (oz)",
            "ja": "オンス (oz)",
            "ko": "온스 (oz)",
            "th": "ออนซ์ (oz)",
            "vi": "Ao-xơ (oz)",
            "id": "Ons (oz)",
            "ms": "Auns (oz)",
            "fil": "Onsa (oz)",
            "hi": "औंस (oz)",
            "ar": "أونصة (أونصة)",
            "he": "אונקיה (אונקיה)"
        ],
        // Fluid Ounce
        "fl_oz": [
            "en": "Fluid Ounce (fl oz)",
            "zh-Hans": "液量盎司 (fl oz)",
            "zh-Hant": "液量盎司 (fl oz)",
            "es": "Onza líquida (fl oz)",
            "fr": "Once liquide (fl oz)",
            "de": "Flüssigunze (fl oz)",
            "it": "Oncia fluida (fl oz)",
            "pt": "Onça fluida (fl oz)",
            "nl": "Vloeistof ons (fl oz)",
            "ru": "Жидкая унция (fl oz)",
            "ja": "液量オンス (fl oz)",
            "ko": "액량 온스 (fl oz)",
            "th": "ออนซ์ของเหลว (fl oz)",
            "vi": "Ao-xơ chất lỏng (fl oz)",
            "id": "Ons cair (fl oz)",
            "ms": "Auns cecair (fl oz)",
            "fil": "Onsang likido (fl oz)",
            "hi": "औंस (oz)",
            "ar": "أونصة سائلة (أونصة سائلة)",
            "he": "אונקיה נוזלית (אונקיה נוזלית)"
        ],
        // Pound
        "lb": [
            "en": "Pound (lb)",
            "zh-Hans": "磅 (lb)",
            "zh-Hant": "磅 (lb)",
            "es": "Libra (lb)",
            "fr": "Livre (lb)",
            "de": "Pfund (lb)",
            "it": "Libbra (lb)",
            "pt": "Libra (lb)",
            "nl": "Pond (lb)",
            "ru": "Фунт (lb)",
            "ja": "ポンド (lb)",
            "ko": "파운드 (lb)",
            "th": "ปอนด์ (lb)",
            "vi": "Pao (lb)",
            "id": "Pon (lb)",
            "ms": "Paun (lb)",
            "fil": "Libra (lb)",
            "hi": "औंस (oz)",
            "ar": "رطل (رطل)",
            "he": "פאונד (פאונד)"
        ],
        // Gram
        "g": [
            "en": "Gram (g)",
            "zh-Hans": "克 (g)",
            "zh-Hant": "克 (g)",
            "es": "Gramo (g)",
            "fr": "Gramme (g)",
            "de": "Gramm (g)",
            "it": "Grammo (g)",
            "pt": "Grama (g)",
            "nl": "Gram (g)",
            "ru": "Грамм (g)",
            "ja": "グラム (g)",
            "ko": "그램 (g)",
            "th": "กรัม (g)",
            "vi": "Gam (g)",
            "id": "Gram (g)",
            "ms": "Gram (g)",
            "fil": "Gramo (g)",
            "hi": "औंस (oz)",
            "ar": "جرام (جرام)",
            "he": "גרם (גרם)"
        ],
        // Kilogram
        "kg": [
            "en": "Kilogram (kg)",
            "zh-Hans": "千克 (kg)",
            "zh-Hant": "千克 (kg)",
            "es": "Kilogramo (kg)",
            "fr": "Kilogramme (kg)",
            "de": "Kilogramm (kg)",
            "it": "Chilogrammo (kg)",
            "pt": "Quilograma (kg)",
            "nl": "Kilogram (kg)",
            "ru": "Килограмм (kg)",
            "ja": "キログラム (kg)",
            "ko": "킬로그램 (kg)",
            "th": "กิโลกรัม (kg)",
            "vi": "Kilôgam (kg)",
            "id": "Kilogram (kg)",
            "ms": "Kilogram (kg)",
            "fil": "Kilogramo (kg)",
            "hi": "औंस (oz)",
            "ar": "كيلوغرام (كيلوغرام)",
            "he": "קילוגרם (קילוגרם)"
        ],
        // Milliliter
        "ml": [
            "en": "Milliliter (ml)",
            "zh-Hans": "毫升 (ml)",
            "zh-Hant": "毫升 (ml)",
            "es": "Mililitro (ml)",
            "fr": "Millilitre (ml)",
            "de": "Milliliter (ml)",
            "it": "Millilitro (ml)",
            "pt": "Mililitro (ml)",
            "nl": "Milliliter (ml)",
            "ru": "Миллилитр (ml)",
            "ja": "ミリリットル (ml)",
            "ko": "밀리리터 (ml)",
            "th": "มิลลิลิตร (ml)",
            "vi": "Mililít (ml)",
            "id": "Mililiter (ml)",
            "ms": "Mililiter (ml)",
            "fil": "Mililitro (ml)",
            "hi": "औंस (oz)",
            "ar": "مليلتر (مليلتر)",
            "he": "מיליליטר (מיליליטר)"
        ],
        // Liter
        "l": [
            "en": "Liter (l)",
            "zh-Hans": "升 (l)",
            "zh-Hant": "升 (l)",
            "es": "Litro (l)",
            "fr": "Litre (l)",
            "de": "Liter (l)",
            "it": "Litro (l)",
            "pt": "Litro (l)",
            "nl": "Liter (l)",
            "ru": "Литр (l)",
            "ja": "リットル (l)",
            "ko": "리터 (l)",
            "th": "ลิตร (l)",
            "vi": "Lít (l)",
            "id": "Liter (l)",
            "ms": "Liter (l)",
            "fil": "Litro (l)",
            "hi": "औंस (oz)",
            "ar": "لتر (لتر)",
            "he": "ליטר (ליטר)"
        ],
        // Quart
        "qt": [
            "en": "Quart (qt)",
            "zh-Hans": "夸脱 (qt)",
            "zh-Hant": "夸脫 (qt)",
            "es": "Cuarto de galón (qt)",
            "fr": "Quart (qt)",
            "de": "Quart (qt)",
            "it": "Quarto (qt)",
            "pt": "Quarto (qt)",
            "nl": "Kwart (qt)",
            "ru": "Кварта (qt)",
            "ja": "クォート (qt)",
            "ko": "쿼트 (qt)",
            "th": "ควอร์ต (qt)",
            "vi": "Quart (qt)",
            "id": "Quart (qt)",
            "ms": "Quart (qt)",
            "fil": "Quart (qt)",
            "hi": "क्वार्ट (qt)",
            "ar": "كوارت (qt)",
            "he": "קוורט (qt)"
        ],
        // Pinch
        "pinch": [
            "en": "Pinch",
            "zh-Hans": "撮",
            "zh-Hant": "撮",
            "es": "Pizca",
            "fr": "Pincée",
            "de": "Prise",
            "it": "Pizzico",
            "pt": "Pitada",
            "nl": "Mespuntje",
            "ru": "Щепотка",
            "ja": "ひとつまみ",
            "ko": "꼬집",
            "th": "หยิบ",
            "vi": "Nhúm",
            "id": "Sejumput",
            "ms": "Secubit",
            "fil": "Kurot",
            "hi": "औंस (oz)",
            "ar": "قبضة",
            "he": "קורט"
        ],
        // Piece (pc)
        "pc": [
            "en": "Piece (pc)",
            "zh-Hans": "个 (pc)",
            "zh-Hant": "個 (pc)",
            "es": "Pieza (pc)",
            "fr": "Morceau (pc)",
            "de": "Stück (pc)",
            "it": "Pezzo (pc)",
            "pt": "Peça (pc)",
            "nl": "Stuk (pc)",
            "ru": "Штука (pc)",
            "ja": "個 (pc)",
            "ko": "개 (pc)",
            "th": "ชิ้น (pc)",
            "vi": "Miếng (pc)",
            "id": "Buah (pc)",
            "ms": "Keping (pc)",
            "fil": "Piraso (pc)",
            "hi": "औंस (oz)",
            "ar": "قطعة (قطعة)",
            "he": "חתיכה (חתיכה)"
        ],
        // Pieces (pcs)
        "pcs": [
            "en": "Pieces (pcs)",
            "zh-Hans": "个 (pcs)",
            "zh-Hant": "個 (pcs)",
            "es": "Piezas (pcs)",
            "fr": "Morceaux (pcs)",
            "de": "Stücke (pcs)",
            "it": "Pezzi (pcs)",
            "pt": "Peças (pcs)",
            "nl": "Stukken (stk)",
            "ru": "Штуки (pcs)",
            "ja": "個 (pcs)",
            "ko": "개 (pcs)",
            "th": "ชิ้น (pcs)",
            "vi": "Miếng (pcs)",
            "id": "Buah (pcs)",
            "ms": "Keping (pcs)",
            "fil": "Piraso (pcs)",
            "hi": "औंस (oz)",
            "ar": "قطع (قطع)",
            "he": "חתיכות (חתיכות)"
        ],
        // Slice
        "slice": [
            "en": "Slice",
            "zh-Hans": "片",
            "zh-Hant": "片",
            "es": "Rodaja",
            "fr": "Tranche",
            "de": "Scheibe",
            "it": "Fetta",
            "pt": "Fatia",
            "nl": "Plak",
            "ru": "Ломтик",
            "ja": "切れ",
            "ko": "조각",
            "th": "ชิ้น",
            "vi": "Lát",
            "id": "Iris",
            "ms": "Hiris",
            "fil": "Hiwa",
            "hi": "औंस (oz)",
            "ar": "شريحة",
            "he": "פרוסה"
        ],
        // Clove
        "clove": [
            "en": "Clove",
            "zh-Hans": "瓣",
            "zh-Hant": "瓣",
            "es": "Diente",
            "fr": "Gousse",
            "de": "Zehe",
            "it": "Spicchio",
            "pt": "Dente",
            "nl": "Teen",
            "ru": "Зубчик",
            "ja": "片",
            "ko": "쪽",
            "th": "กลีบ",
            "vi": "Tép",
            "id": "Siung",
            "ms": "Ulas",
            "fil": "Butil",
            "hi": "औंस (oz)",
            "ar": "فص",
            "he": "שיני"
        ],
        // Bunch
        "bunch": [
            "en": "Bunch",
            "zh-Hans": "束",
            "zh-Hant": "束",
            "es": "Manojo",
            "fr": "Bouquet",
            "de": "Bündel",
            "it": "Mazzetto",
            "pt": "Maço",
            "nl": "Bos",
            "ru": "Пучок",
            "ja": "束",
            "ko": "다발",
            "th": "กำ",
            "vi": "Bó",
            "id": "Ikat",
            "ms": "Ikat",
            "fil": "Bigkis",
            "hi": "औंस (oz)",
            "ar": "حزمة",
            "he": "צרור"
        ],
        // Head
        "head": [
            "en": "Head",
            "zh-Hans": "头",
            "zh-Hant": "頭",
            "es": "Cabeza",
            "fr": "Tête",
            "de": "Kopf",
            "it": "Testa",
            "pt": "Cabeça",
            "nl": "Kop",
            "ru": "Головка",
            "ja": "玉",
            "ko": "통",
            "th": "หัว",
            "vi": "Củ",
            "id": "Kepala",
            "ms": "Biji",
            "fil": "Ulo",
            "hi": "औंस (oz)",
            "ar": "رأس",
            "he": "ראש"
        ],
        // Strand
        "strand": [
            "en": "Strand",
            "zh-Hans": "缕",
            "zh-Hant": "縷",
            "es": "Hebra",
            "fr": "Brin",
            "de": "Strang",
            "it": "Filo",
            "pt": "Fio",
            "nl": "Streng",
            "ru": "Прядь",
            "ja": "本",
            "ko": "줄",
            "th": "เส้น",
            "vi": "Sợi",
            "id": "Helai",
            "ms": "Helai",
            "fil": "Hibla",
            "hi": "औंस (oz)",
            "ar": "خيط",
            "he": "חוט"
        ],
        // Strands
        "strands": [
            "en": "Strands",
            "zh-Hans": "缕",
            "zh-Hant": "縷",
            "es": "Hebras",
            "fr": "Brins",
            "de": "Stränge",
            "it": "Fili",
            "pt": "Fios",
            "nl": "Strengen",
            "ru": "Пряди",
            "ja": "本",
            "ko": "줄",
            "th": "เส้น",
            "vi": "Sợi",
            "id": "Helai",
            "ms": "Helai",
            "fil": "Hibla",
            "hi": "औंस (oz)",
            "ar": "خيوط",
            "he": "חוטים"
        ],
        // Large
        "large": [
            "en": "Large",
            "zh-Hans": "大",
            "zh-Hant": "大",
            "es": "Grande",
            "fr": "Grand",
            "de": "Groß",
            "it": "Grande",
            "pt": "Grande",
            "nl": "Groot",
            "ru": "Большой",
            "ja": "大",
            "ko": "큰",
            "th": "ใหญ่",
            "vi": "Lớn",
            "id": "Besar",
            "ms": "Besar",
            "fil": "Malaki",
            "hi": "औंस (oz)",
            "ar": "كبير",
            "he": "גדול"
        ],
        // Small
        "small": [
            "en": "Small",
            "zh-Hans": "小",
            "zh-Hant": "小",
            "es": "Pequeño",
            "fr": "Petit",
            "de": "Klein",
            "it": "Piccolo",
            "pt": "Pequeno",
            "nl": "Klein",
            "ru": "Маленький",
            "ja": "小",
            "ko": "작은",
            "th": "เล็ก",
            "vi": "Nhỏ",
            "id": "Kecil",
            "ms": "Kecil",
            "fil": "Maliit",
            "hi": "औंस (oz)",
            "ar": "صغير",
            "he": "קטן"
        ]
    ]
    
    /// Normalize unit key - converts full unit names to keys (e.g., "tablespoon" -> "tbsp")
    private static func normalizeUnitKey(_ unit: String) -> String {
        let lowercased = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Mapping of common full names to keys
        let nameToKey: [String: String] = [
            "teaspoon": "tsp",
            "teaspoons": "tsp",
            "tablespoon": "tbsp",
            "tablespoons": "tbsp",
            "cup": "cup",
            "cups": "cup",
            "ounce": "oz",
            "ounces": "oz",
            "fluid ounce": "fl_oz",
            "fluid ounces": "fl_oz",
            "pound": "lb",
            "pounds": "lb",
            "gram": "g",
            "grams": "g",
            "kilogram": "kg",
            "kilograms": "kg",
            "milliliter": "ml",
            "milliliters": "ml",
            "liter": "l",
            "liters": "l",
            "litre": "l",
            "litres": "l",
            "quart": "qt",
            "quarts": "qt",
            "pinch": "pinch",
            "pinches": "pinch",
            "piece": "pc",
            "pieces": "pc",
            "slice": "slice",
            "slices": "slice",
            "clove": "clove",
            "cloves": "clove",
            "bunch": "bunch",
            "bunches": "bunch",
            "head": "head",
            "heads": "head",
            "strand": "strand",
            "strands": "strand",
            "large": "large",
            "small": "small"
        ]
        
        return nameToKey[lowercased] ?? unit
    }
    
    /// Get the abbreviation for a unit in the current language
    /// - Parameters:
    ///   - unitKey: The English unit key (e.g., "tsp", "tbsp") or full name (e.g., "tablespoon")
    ///   - amount: Optional amount string to determine if plural form should be used
    /// - Returns: The abbreviation in the current language, or the English abbreviation if not found
    static func abbreviation(for unitKey: String, amount: String? = nil) -> String {
        // Trim whitespace and normalize
        let trimmedUnit = unitKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedUnit.isEmpty else {
            return "-"
        }
        
        // Normalize unit key (convert full names to keys)
        let normalizedKey = normalizeUnitKey(trimmedUnit)
        
        // Determine if we should use plural form
        let shouldPluralize = shouldUsePluralForm(unitKey: normalizedKey, amount: amount)
        let unitToTranslate = shouldPluralize ? getPluralForm(unitKey: normalizedKey) : normalizedKey
        
        // Get the translated name (which includes abbreviation in parentheses)
        let translatedName = self.translatedName(for: unitToTranslate)
        
        // Extract abbreviation from parentheses (e.g., "Theelepel (tl)" -> "tl")
        if let openParen = translatedName.firstIndex(of: "("),
           let closeParen = translatedName.firstIndex(of: ")") {
            let abbreviation = String(translatedName[translatedName.index(after: openParen)..<closeParen])
            return abbreviation.trimmingCharacters(in: .whitespaces)
        }
        
        // If no parentheses found, return the translated name itself (for units without abbreviations)
        // This ensures "cup" shows as "Kopje" in Dutch, not "cup"
        return translatedName
    }
    
    /// Get the translated unit name with pluralization support
    /// - Parameters:
    ///   - unitKey: The English unit key (e.g., "tsp", "cup", "pc") or full name (e.g., "tablespoon")
    ///   - amount: Optional amount string to determine if plural form should be used
    /// - Returns: The translated unit name with appropriate pluralization
    static func translatedName(for unitKey: String, amount: String? = nil) -> String {
        // Trim whitespace and normalize
        let trimmedUnit = unitKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedUnit.isEmpty else {
            // Return empty unit translation
            return getTranslation(for: "", languageCode: getCurrentLanguageCode()) ?? "-"
        }
        
        // Normalize unit key (convert full names to keys)
        let normalizedKey = normalizeUnitKey(trimmedUnit)
        
        // Determine if we should use plural form
        let shouldPluralize = shouldUsePluralForm(unitKey: normalizedKey, amount: amount)
        let unitToTranslate = shouldPluralize ? getPluralForm(unitKey: normalizedKey) : normalizedKey
        
        // Get current language code
        let languageCode = getCurrentLanguageCode()
        
        // If English is selected, return English name
        if languageCode.lowercased() == "en" || languageCode.lowercased().hasPrefix("en-") {
            return getTranslation(for: unitToTranslate, languageCode: "en") ?? trimmedUnit
        }
        
        // Get translation
        return getTranslation(for: unitToTranslate, languageCode: languageCode) ?? getTranslation(for: unitToTranslate, languageCode: "en") ?? trimmedUnit
    }
    
    /// Determine if plural form should be used based on amount
    private static func shouldUsePluralForm(unitKey: String, amount: String?) -> Bool {
        guard let amountString = amount else { return false }
        let amountValue = Double(amountString.trimmingCharacters(in: .whitespaces)) ?? 0
        return amountValue > 1
    }
    
    /// Get the plural form of a unit key
    private static func getPluralForm(unitKey: String) -> String {
        // Mapping of singular to plural unit keys
        let pluralMapping: [String: String] = [
            "cup": "cups",
            "pinch": "pinches",
            "pc": "pcs",
            "slice": "slices",
            "clove": "cloves",
            "bunch": "bunches",
            "head": "heads",
            "strand": "strands"
        ]
        
        return pluralMapping[unitKey] ?? unitKey
    }
    
    /// Get translation for a specific unit and language code
    private static func getTranslation(for unitKey: String, languageCode: String) -> String? {
        // Normalize language code
        let normalizedCode = normalizeLanguageCode(languageCode)
        
        // Get translations for this unit
        guard let unitTranslations = translations[unitKey] else {
            return nil
        }
        
        // Try normalized code first
        if let translated = unitTranslations[normalizedCode] {
            return translated
        }
        
        // Try original code as fallback
        if let translated = unitTranslations[languageCode] {
            return translated
        }
        
        return nil
    }
    
    /// Get current language code based on LocalizationManager
    private static func getCurrentLanguageCode() -> String {
        let currentLanguage = LocalizationManager.shared.currentLanguage
        
        switch currentLanguage {
        case .english:
            return "en"
        case .system:
            // Get system language code
            if let preferredLanguage = Locale.preferredLanguages.first {
                return normalizeLanguageCode(preferredLanguage)
            } else {
                return "en"
            }
        default:
            return currentLanguage.rawValue
        }
    }
    
    /// Normalize language codes (handles variants like nl-NL -> nl, en-US -> en, zh-HK -> zh-Hant, etc.)
    private static func normalizeLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        // Traditional Chinese regions
        if lowercased.hasPrefix("zh-hk") ||
           lowercased.contains("-hk") ||
           lowercased.contains("_hk") ||
           lowercased.hasPrefix("zh-tw") ||
           lowercased.contains("-tw") ||
           lowercased.contains("_tw") ||
           lowercased.hasPrefix("zh-mo") ||
           lowercased.contains("-mo") ||
           lowercased.contains("_mo") ||
           lowercased == "zh-hant" ||
           lowercased.hasPrefix("zh-hant") {
            return "zh-Hant"
        }
        
        // Simplified Chinese regions
        if lowercased.hasPrefix("zh-cn") ||
           lowercased.contains("-cn") ||
           lowercased.contains("_cn") ||
           lowercased.hasPrefix("zh-sg") ||
           lowercased.contains("-sg") ||
           lowercased.contains("_sg") ||
           lowercased == "zh-hans" ||
           lowercased.hasPrefix("zh-hans") {
            return "zh-Hans"
        }
        
        // If it's just "zh" without variant, default to Simplified
        if lowercased == "zh" {
            return "zh-Hans"
        }
        
        // Extract base language code (e.g., "nl-NL" -> "nl", "en-US" -> "en", "fr-FR" -> "fr")
        if let baseCode = lowercased.split(separator: "-").first ?? lowercased.split(separator: "_").first {
            return String(baseCode)
        }
        
        return code
    }
}

