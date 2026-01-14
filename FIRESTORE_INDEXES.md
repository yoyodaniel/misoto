# Firestore Indexes Required for Recipe Sharing

## Required Composite Indexes

### 1. recipeShares Collection - Get Shares for Recipe (Owner Query)

**Collection:** `recipeShares`  
**Fields:**
- `recipeID` (Ascending)
- `sharedBy` (Ascending)
- `sharedAt` (Descending)

**Used by:** `RecipeShareService.getShares(for:)` and `RecipeShareService.getSharedUserIDs(for:)`

**Create Index:**
Click this link to create the index automatically:
https://console.firebase.google.com/v1/r/project/misoto-9cf71/firestore/indexes?create_composite=ClFwcm9qZWN0cy9taXNvdG8tOWNmNzEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JlY2lwZVNoYXJlcy9pbmRleGVzL18QARoMCghyZWNpcGVJRBABGgwKCHNoYXJlZEJ5EAEaDAoIc2hhcmVkQXQQAhoMCghfX25hbWVfXxAC

**Or create manually:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Collection ID: `recipeShares`
4. Add fields:
   - `recipeID` - Ascending
   - `sharedBy` - Ascending
   - `sharedAt` - Descending
5. Click "Create"

### 2. recipeShares Collection - Get Recipes Shared With Me

**Collection:** `recipeShares`  
**Fields:**
- `userID` (Ascending)
- `sharedAt` (Descending)

**Used by:** `RecipeShareService.getRecipesSharedWithMe()`

**Create Index:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Collection ID: `recipeShares`
4. Add fields:
   - `userID` - Ascending
   - `sharedAt` - Descending
5. Click "Create"

### 3. recipeShares Collection - Get Recipes Shared By Me

**Collection:** `recipeShares`  
**Fields:**
- `sharedBy` (Ascending)
- `sharedAt` (Descending)

**Used by:** `RecipeShareService.getRecipesSharedByMe()`

**Create Index:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Collection ID: `recipeShares`
4. Add fields:
   - `sharedBy` - Ascending
   - `sharedAt` - Descending
5. Click "Create"

### 4. recipeShares Collection - Check if Recipe is Shared (for Access Check)

**Collection:** `recipeShares`  
**Fields:**
- `recipeID` (Ascending)
- `userID` (Ascending)

**Used by:** `RecipeShareService.isRecipeShared(recipeID:with:)`

**Create Index:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Collection ID: `recipeShares`
4. Add fields:
   - `recipeID` - Ascending
   - `userID` - Ascending
5. Click "Create"

## Quick Setup

**Fastest way:** Click the link in the error message when it appears - it will automatically create the required index.

**Or create all indexes at once:**
1. Go to Firebase Console → Firestore Database → Indexes
2. Create each index listed above
3. Wait for indexes to build (usually takes a few minutes)

## Notes

- Indexes are required for queries that filter on multiple fields or use ordering
- Single-field queries don't require indexes (Firestore creates them automatically)
- Composite indexes can take a few minutes to build
- The app will work in offline mode while indexes are building, but queries will fail when online until indexes are ready
