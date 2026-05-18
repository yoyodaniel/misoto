#!/usr/bin/env python3
"""Translate and apply Misoto 1.5 Localizable.strings to all locales."""

from __future__ import annotations

import hashlib
import json
import re
import time
from pathlib import Path

try:
    from deep_translator import GoogleTranslator
except ImportError:
    raise SystemExit("Install: pip3 install deep-translator")

ROOT = Path(__file__).resolve().parents[1]
MISOTO = ROOT / "Misoto"
EN_PATH = MISOTO / "en.lproj" / "Localizable.strings"
CACHE_PATH = ROOT / "scripts" / ".v15_translation_cache.json"

LANG_MAP = {
    "ar": "ar",
    "de": "de",
    "es": "es",
    "fil": "tl",
    "fr": "fr",
    "he": "iw",
    "hi": "hi",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "ms": "ms",
    "nl": "nl",
    "pt": "pt",
    "ru": "ru",
    "th": "th",
    "vi": "vi",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
}

OLD_WHATS_NEW_KEYS = {
    "Search with natural language.",
    "RPG-style XP and level-ups as you cook.",
    "Post publicly - or keep recipes private.",
    "AI helps polish recipe text while you write.",
}

WHATS_NEW_KEYS = [
    "AI Enhance for recipe photos—pick a style and tap Enhance.",
    "Stronger security for your account and uploads.",
    "More reliable search, AI, and editing.",
]

DISH_PHOTO_KEYS = [
    "Clean recipe app",
    "Modern patisserie",
    "Rustic comfort",
    "Minimalist",
    "Celebration",
    "Premium dessert",
    "Family cookbook",
    "Modern food blog",
    "Bright, neutral, app-thumbnail ready.",
    "Refined bakery finish and elegant plating.",
    "Warm homestyle cookbook feel.",
    "Calm, uncluttered Scandinavian look.",
    "Festive but tidy and photo-ready.",
    "High-end dessert photography polish.",
    "Approachable, authentic home-baked warmth.",
    "Editorial color pop, still realistic.",
    "Could not prepare the photo for enhancement.",
    "Invalid response from the photo enhancement service.",
    "No enhanced image was returned. Please try again.",
    "You have reached your free tier limit for AI photo enhancements",
    "Upgrade to Premium for unlimited AI photo enhancements",
    "Enhance dish photo",
    "Style",
    "Enhance again",
    "Enhance photo",
    "Use photo",
    "AI Enhance",
    "Tap the wand on a photo to enhance it for recipe cards. Free accounts have a monthly limit; Premium is unlimited.",
    "This AI feature was not found on the server. Deploy the matching Cloud Function to us-central1 (e.g. openaiImageEdit for photo enhance, openaiChatCompletions for recipe AI), and confirm the app uses the misoto-9cf71 Firebase project.",
    "Dish photo preview",
]

ALL_V15_KEYS = WHATS_NEW_KEYS + DISH_PHOTO_KEYS

LINE_RE = re.compile(
    r'^(\s*)"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;\s*$'
)


def strip_comments(text: str) -> str:
    return re.sub(r"/\*[\s\S]*?\*/", "", text)


def parse_strings(text: str) -> dict[str, str]:
    d: dict[str, str] = {}
    for m in re.finditer(
        r'"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)"\s*;',
        strip_comments(text),
    ):
        k = m.group(1).replace('\\"', '"')
        v = (
            m.group(2)
            .replace("\\n", "\n")
            .replace('\\"', '"')
            .replace("\\\\", "\\")
        )
        d[k] = v
    return d


def escape_value(s: str) -> str:
    return (
        s.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )


def ck(dest: str, text: str) -> str:
    return hashlib.sha256(f"{dest}|{text}".encode("utf-8")).hexdigest()[:32]


def load_cache() -> dict[str, str]:
    if CACHE_PATH.is_file():
        try:
            return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def save_cache(c: dict[str, str]) -> None:
    CACHE_PATH.write_text(json.dumps(c, ensure_ascii=False, indent=0), encoding="utf-8")


def translate(dest: str, text: str, cache: dict[str, str]) -> str:
    k = ck(dest, text)
    if k in cache:
        return cache[k]
    for attempt in range(5):
        try:
            out = GoogleTranslator(source="en", target=dest).translate(text)
            cache[k] = out
            time.sleep(0.12)
            return out
        except Exception:
            time.sleep(0.6 * (attempt + 1))
    cache[k] = text
    return text


def format_entry(key: str, value: str) -> str:
    return f'"{escape_value(key)}" = "{escape_value(value)}";\n'


def remove_keys_block(text: str, keys: set[str]) -> str:
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    for line in lines:
        m = LINE_RE.match(line.rstrip("\n\r"))
        if m and m.group(2).replace('\\"', '"').replace("\\\\", "\\") in keys:
            continue
        out.append(line)
    return "".join(out)


def insert_after_whats_new_comment(text: str, new_lines: str) -> str:
    marker = "/* What's New (app update sheet) */"
    idx = text.find(marker)
    if idx == -1:
        return text + "\n" + marker + "\n" + new_lines
    insert_at = idx + len(marker)
    if insert_at < len(text) and text[insert_at] == "\n":
        insert_at += 1
    return text[:insert_at] + new_lines + text[insert_at:]


def ensure_dish_photo_section(text: str, dish_lines: str) -> str:
    marker = "/* Dish photo AI enhance (1.5) */"
    if marker in text:
        # Replace existing dish photo block
        pattern = re.compile(
            r"/\* Dish photo AI enhance \(1\.5\) \*/\n(?:\"[^\"]*\" = \"[^\"]*\";\n)+",
            re.MULTILINE,
        )
        if pattern.search(text):
            return pattern.sub(marker + "\n" + dish_lines, text, count=1)
    # Insert before auto-synced block or at end
    auto = "/* Auto-synced from en"
    aidx = text.find(auto)
    block = marker + "\n" + dish_lines + "\n"
    if aidx != -1:
        return text[:aidx] + block + text[aidx:]
    return text.rstrip() + "\n\n" + block


def main() -> None:
    en = parse_strings(EN_PATH.read_text(encoding="utf-8"))
    cache = load_cache()

    translations: dict[str, dict[str, str]] = {"en": {k: en.get(k, k) for k in ALL_V15_KEYS}}
    for lang, dest in LANG_MAP.items():
        translations[lang] = {}
        print(f"Translating {lang} ({dest})...", flush=True)
        for key in ALL_V15_KEYS:
            english = en.get(key, key)
            translations[lang][key] = translate(dest, english, cache)
    save_cache(cache)

    for lang in LANG_MAP:
        dest = LANG_MAP[lang]
        t = translations[lang]
        wn = "".join(format_entry(k, t[k]) for k in WHATS_NEW_KEYS)
        dish = "".join(format_entry(k, t[k]) for k in DISH_PHOTO_KEYS)

        path = MISOTO / f"{lang}.lproj" / "Localizable.strings"
        text = path.read_text(encoding="utf-8")
        text = remove_keys_block(text, OLD_WHATS_NEW_KEYS | set(ALL_V15_KEYS))
        text = insert_after_whats_new_comment(text, "\n" + wn)
        text = ensure_dish_photo_section(text, dish)
        path.write_text(text, encoding="utf-8")
        print(f"  updated {lang}.lproj", flush=True)

    print("Done. 19 locales + en base unchanged.")


if __name__ == "__main__":
    main()
