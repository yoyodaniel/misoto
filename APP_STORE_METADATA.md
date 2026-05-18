# App Store Connect — copy-paste metadata (Misoto)

Paste these into **App Store Connect** → your app → **App Store** tab → select the version → **Promotional Text** / **What’s New in This Version**.

**Marketing version this copy targets:** 1.5 (adjust if your build differs). **Shipped 1.4:** see git tag `v1.4.0` on `main`.

---

## Subtitle (30 characters max)

```
AI recipes • 20 languages
```

*(29 characters.)*

---

## Promotional Text (170 characters max)

Apple shows this above your description and you can change it **without** submitting a new binary.

```
Misoto 1.5: AI Enhance for recipe photos. Save recipes, extract from photos, links & sites, 20 languages. Reviews, nutrition (beta). Sign in for AI.
```

**Character count:** ~148 (under Apple’s 170 limit).

---

## Description (App Store Connect → Description)

```
Misoto is your home for recipes in 20 languages—save favorites, explore cooks worldwide, and turn inspiration into complete dishes in seconds.

WHAT YOU CAN DO
• Save and organize your recipes with photos, ingredients, and step-by-step instructions
• Extract recipes from photos, links, or websites with AI (sign in required)
• Polish dish photos with AI Enhance—pick a style and tap Enhance on uploads and edits (v1.5)
• Search recipes with natural language
• Read ratings and reviews on dishes in Explore
• See nutrition estimates (beta) with USDA-backed data and AI help when needed
• Share recipes publicly, keep them private, or share with selected people
• Level up as you cook with XP and achievements
• Use the app in 20 languages

PREMIUM
Misoto Premium unlocks unlimited recipes and higher limits on AI features. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID account settings after purchase.

AI FEATURES
Some features use AI and require you to sign in. Availability may vary by region. Free accounts have monthly limits; Premium includes expanded access.

SUPPORT
Questions or feedback: support@misoto.app

Privacy Policy: https://misoto.app/privacy
Terms of Use: https://misoto.app/terms
```

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

## Keywords (100 characters max, optional)

```
recipe,cooking,food,AI,photo,recipes,share,kitchen,meal,chef,nutrition,extract,enhance
```

---

## In-app alignment

The **What’s New** sheet inside the app uses the same three highlight strings as in `en.lproj` under `/* What's New (app update sheet) */` (v1.5: AI Enhance, security, reliability). After changing English, run your localization workflow (e.g. `scripts/sync_machine_translations.py`) to refresh other languages, or update `Localizable.strings` per locale manually.

The **Share App** text in Settings uses the long `AI-Powered recipe sharing app...` key in `Localizable.strings`; that English string is updated alongside this doc so invite copy matches the product story.
