#!/usr/bin/env python3
"""
Machine-translate Localizable.strings entries that still match English.
Uses deep-translator (Google). Cache: scripts/.translation_cache.json

  pip3 install deep-translator
  python3 scripts/sync_machine_translations.py
  python3 scripts/sync_machine_translations.py --apply-cache-only
  python3 scripts/sync_machine_translations.py --fill-missing 400
"""

from __future__ import annotations

import json
import re
import time
import hashlib
import sys
from pathlib import Path

try:
    from deep_translator import GoogleTranslator
except ImportError:
    raise SystemExit("Install: pip3 install deep-translator")

ROOT = Path(__file__).resolve().parents[1]
MISOTO = ROOT / "Misoto"
EN_PATH = MISOTO / "en.lproj" / "Localizable.strings"
CACHE_PATH = ROOT / "scripts" / ".translation_cache.json"

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


def placeholder_tokens(s: str) -> list[str]:
    return re.findall(
        r"%(?:\d+\$)?@|%(?:\d+\$)?(?:lld|ld|d|u|f|g|e|@)|%\d*\.?\d*f|%%",
        s,
        flags=re.IGNORECASE,
    )


def should_skip(key: str, english: str) -> bool:
    if english.strip() == "":
        return True
    if english in ("Misoto", "OK", "AI", "JSON"):
        return True
    if key == "Misoto" and english == "Misoto":
        return True
    if english.startswith("http://") or english.startswith("https://"):
        return True
    if len(english) <= 2 and not any(c.isalpha() for c in english):
        return True
    if len(english) > 4500:
        return True
    return False


def load_cache() -> dict[str, str]:
    if CACHE_PATH.is_file():
        try:
            return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
        except Exception:
            return {}
    return {}


def save_cache(c: dict[str, str]) -> None:
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    CACHE_PATH.write_text(json.dumps(c, ensure_ascii=False, indent=0), encoding="utf-8")


def ck(dest: str, text: str) -> str:
    h = hashlib.sha256(f"{dest}|{text}".encode("utf-8")).hexdigest()[:32]
    return h


def translate(dest: str, text: str, cache: dict[str, str], save_counter: list[int]) -> str:
    k = ck(dest, text)
    if k in cache:
        return cache[k]
    for attempt in range(5):
        try:
            out = GoogleTranslator(source="en", target=dest).translate(text)
            ot, nt = placeholder_tokens(text), placeholder_tokens(out)
            if ot and ot != nt:
                out = text
            cache[k] = out
            save_counter[0] += 1
            if save_counter[0] % 50 == 0:
                save_cache(cache)
            time.sleep(0.1)
            return out
        except Exception:
            time.sleep(0.5 * (attempt + 1))
    cache[k] = text
    return text


def apply_updates(path: Path, key_to_val: dict[str, str]) -> int:
    if not key_to_val:
        return 0
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    changed = 0
    out: list[str] = []
    for line in lines:
        m = LINE_RE.match(line.rstrip("\n\r"))
        if not m:
            out.append(line)
            continue
        indent = m.group(1)
        key = m.group(2).replace('\\"', '"').replace("\\\\", "\\")
        if key not in key_to_val:
            out.append(line)
            continue
        nv = key_to_val[key]
        new_line = f'{indent}"{escape_value(key)}" = "{escape_value(nv)}";\n'
        out.append(new_line)
        changed += 1
    path.write_text("".join(out), encoding="utf-8")
    return changed


def apply_phase(
    en: dict[str, str],
    memo: dict[tuple[str, str], str],
    per_lang_keys: dict[str, set[str]],
) -> None:
    for lang, dest in LANG_MAP.items():
        updates: dict[str, str] = {}
        for key in per_lang_keys[lang]:
            en_val = en[key]
            tr = memo.get((dest, en_val), en_val)
            if tr != en_val:
                updates[key] = tr
        p = MISOTO / f"{lang}.lproj" / "Localizable.strings"
        n = apply_updates(p, updates)
        print(lang, "lines rewritten:", n)


def build_per_lang_keys(en: dict[str, str], lang_map: dict[str, str]) -> dict[str, set[str]]:
    per_lang_keys: dict[str, set[str]] = {lang: set() for lang in lang_map}
    for lproj in sorted(MISOTO.glob("*.lproj")):
        lang = lproj.name.replace(".lproj", "")
        if lang == "en" or lang not in lang_map:
            continue
        dest = lang_map[lang]
        loc = parse_strings((lproj / "Localizable.strings").read_text(encoding="utf-8"))
        for key, en_val in en.items():
            if loc.get(key) != en_val:
                continue
            if should_skip(key, en_val):
                continue
            per_lang_keys[lang].add(key)
    return per_lang_keys


def apply_cache_only() -> None:
    """Write cached translations to .strings files (no network)."""
    en = parse_strings(EN_PATH.read_text(encoding="utf-8"))
    cache = load_cache()
    per_lang_keys = build_per_lang_keys(en, LANG_MAP)
    pairs: set[tuple[str, str]] = set()
    for lang in LANG_MAP:
        dest = LANG_MAP[lang]
        for key in per_lang_keys[lang]:
            pairs.add((dest, en[key]))
    memo: dict[tuple[str, str], str] = {}
    for dest, text in pairs:
        k = ck(dest, text)
        memo[(dest, text)] = cache.get(k, text)
    apply_phase(en, memo, per_lang_keys)
    print(
        "apply-cache-only done; pairs:",
        len(pairs),
        "cached hits:",
        sum(1 for d, t in pairs if ck(d, t) in cache),
    )


def fill_missing(max_new: int) -> None:
    """Translate up to max_new uncached (dest, text) pairs, then apply all from cache."""
    en = parse_strings(EN_PATH.read_text(encoding="utf-8"))
    cache = load_cache()
    per_lang_keys = build_per_lang_keys(en, LANG_MAP)
    pairs: set[tuple[str, str]] = set()
    for lang in LANG_MAP:
        dest = LANG_MAP[lang]
        for key in per_lang_keys[lang]:
            pairs.add((dest, en[key]))
    uncached = [(d, t) for d, t in sorted(pairs) if ck(d, t) not in cache]
    todo = uncached[:max_new]
    print("uncached pairs:", len(uncached), "will translate:", len(todo))
    save_counter = [0]
    for i, (dest, text) in enumerate(todo, 1):
        translate(dest, text, cache, save_counter)
        if i % 20 == 0:
            print(f"  {i}/{len(todo)}", flush=True)
    memo = {(d, t): cache.get(ck(d, t), t) for d, t in pairs}
    apply_phase(en, memo, per_lang_keys)
    save_cache(cache)
    print("fill-missing done.")


def main() -> None:
    """Translate every uncached pair (long run). Prefer --fill-missing N in batches."""
    en = parse_strings(EN_PATH.read_text(encoding="utf-8"))
    cache = load_cache()

    per_lang_keys = build_per_lang_keys(en, LANG_MAP)
    pairs: set[tuple[str, str]] = set()
    for lang in LANG_MAP:
        dest = LANG_MAP[lang]
        for key in per_lang_keys[lang]:
            pairs.add((dest, en[key]))

    print("Unique (target_lang, english) pairs to translate:", len(pairs))
    memo: dict[tuple[str, str], str] = {}
    save_counter = [0]
    for i, (dest, text) in enumerate(sorted(pairs), 1):
        memo[(dest, text)] = translate(dest, text, cache, save_counter)
        if i % 50 == 0:
            print(f"  translated {i}/{len(pairs)}", flush=True)

    apply_phase(en, memo, per_lang_keys)

    save_cache(cache)
    print("Finished.")


if __name__ == "__main__":
    if "--apply-cache-only" in sys.argv:
        apply_cache_only()
    elif "--fill-missing" in sys.argv:
        n = 400
        for i, a in enumerate(sys.argv):
            if a == "--fill-missing" and i + 1 < len(sys.argv):
                n = int(sys.argv[i + 1])
        fill_missing(n)
    else:
        main()
