# App Store Connect — copy-paste metadata (Misoto)

Paste these into **App Store Connect** → your app → **App Store** tab → select the version → **Promotional Text** / **What’s New in This Version**.

**Marketing version this copy targets:** 1.5 (adjust if your build differs). **Shipped 1.4:** see git tag `v1.4.0` on `main`.

---

## Promotional Text (170 characters max)

Apple shows this above your description and you can change it **without** submitting a new binary.

```
Misoto: discover & save recipes. AI from photos, links & sites; 20 languages; reviews & nutrition (beta). Sign in to use AI. Private or public sharing—download now.
```

**Character count:** 164 (including spaces; under Apple’s 170 limit).

---

## What’s New in This Version (release notes)

Use the full block below for **What’s New** (well under Apple’s limit). Trim bullets if you prefer a shorter list.

```
What’s new in Misoto 1.5

• AI Enhance for recipe photos—pick a style and tap Enhance.
• Stronger security for your account and uploads.
• More reliable search, AI, and editing.
```

---

## Optional: Subtitle (30 characters max)

```
AI recipes • 20 languages
```

*(29 characters.)*

---

## In-app alignment

The **What’s New** sheet inside the app uses the same three highlight strings as in `en.lproj` under `/* What's New (app update sheet) */` (v1.5: AI Enhance, security, reliability). After changing English, run your localization workflow (e.g. `scripts/sync_machine_translations.py`) to refresh other languages, or update `Localizable.strings` per locale manually.

The **Share App** text in Settings uses the long `AI-Powered recipe sharing app...` key in `Localizable.strings`; that English string is updated alongside this doc so invite copy matches the product story.
