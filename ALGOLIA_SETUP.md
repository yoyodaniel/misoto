# Algolia Search Setup (Scalable)

This project is now wired for a scalable search architecture:

- Firestore remains source of truth for recipes.
- Cloud Functions syncs every recipe write/delete into Algolia.
- iOS app queries Algolia first and falls back to Firestore search if Algolia is not configured.

## 1) Create Algolia Index

1. Create an Algolia app.
2. Create an index named `recipes` (or your preferred name).
3. Create API keys:
   - **Admin API Key** (server-side only, for Cloud Functions)
   - **Search-Only API Key** (client-side, iOS app)

## 2) Configure Firebase Functions Environment

Set these Firebase Functions env vars/secrets before deploy:

- `ALGOLIA_APP_ID`
- `ALGOLIA_ADMIN_API_KEY`
- `ALGOLIA_INDEX_NAME` (optional, defaults to `recipes`)
- `SEARCH_BACKFILL_ADMIN_KEY` (for secured one-time backfill endpoint)

Then deploy the dedicated Algolia codebase:

```bash
cd functions-algolia
npm install
npm run deploy
```

### Deploy fails with “Timeout after 10000”

Firebase analyzes your `functions/index.js` locally; **10 seconds is often too short** when the project lives in **iCloud Drive** (slow disk sync).

**Fix A — more time + more memory for the Firebase CLI (recommended):**  
Large `functions` codebases (and iCloud paths) can make the CLI run out of memory during analysis (`JavaScript heap out of memory`). The repo’s `npm run deploy` sets:

- `FUNCTIONS_DISCOVERY_TIMEOUT=180` (seconds; CLI converts to ms)
- `NODE_OPTIONS=--max-old-space-size=16384` (16GB heap for the Node process running the CLI; raise if you still OOM)

You can also run manually:

```bash
cd functions
export FUNCTIONS_DISCOVERY_TIMEOUT=180
export NODE_OPTIONS=--max-old-space-size=16384
firebase deploy --only functions
```

If 16GB is still not enough, try `24576` or `32768` (only if your Mac has enough RAM + swap).

If `npx firebase` sits with no output for many minutes, **`npx` can hang** — use the project’s Firebase CLI instead:

```bash
cd functions-algolia
npm install
npm run deploy
```

(`npm run deploy` calls `./node_modules/.bin/firebase` so memory options apply and `npx` is skipped.)

### Why this is faster

This repo now uses two Firebase codebases:

- `default` -> `functions/` (legacy XP/notification triggers)
- `algolia` -> `functions-algolia/` (only Algolia sync + backfill)

Deploying `functions:algolia` avoids loading the large legacy bundle and is much less likely to timeout.

**Fix B — deploy from a local copy:**  
Copy the repo to e.g. `~/Developer/Misoto` (not iCloud), then `cd functions` and deploy again.

## 3) Configure iOS `GoogleService-Info.plist` (not committed)

Algolia credentials must live in **`GoogleService-Info.plist`** alongside your Firebase config (this file is **gitignored**; do not commit real keys).

1. Download `GoogleService-Info.plist` from the Firebase console into the `Misoto` app target folder.
2. Open the plist in Xcode and add string keys (or merge from `GoogleService-Info.example.plist` at the repo root):

- `ALGOLIA_APP_ID`
- `ALGOLIA_SEARCH_API_KEY` (search-only key)
- `ALGOLIA_INDEX_NAME` (optional; defaults to `recipes`)

**Do not** put these keys in `Info.plist`—they would ship in the merged app metadata and are easier to leak via source control if `Info.plist` is ever committed.

When Algolia keys are missing or empty, search automatically falls back to Firestore.

## 4) Recommended Algolia Index Settings

Set searchable attributes in this order for better relevance:

1. `title`
2. `titleEnglish`
3. `titleLocal`
4. `titleOriginal`
5. `ingredients`
6. `cuisine`
7. `cuisineEnglish`
8. `description`
9. `authorName`
10. `authorUsername`
11. `searchKeywords`

Set custom ranking:

- `desc(createdAtSec)`

Optional facets/filters:

- `isPrivate`
- `isHidden`
- `authorID`

## 5) Existing Data Backfill

Trigger-based sync covers new and updated recipes.
For historical recipes, use the included secured HTTPS function:

`backfillRecipesToAlgolia`

Example:

```bash
curl -X POST "https://<region>-<project-id>.cloudfunctions.net/backfillRecipesToAlgolia" \
  -H "x-admin-key: <SEARCH_BACKFILL_ADMIN_KEY>"
```
