# Scalable Recipe Sharing Implementation

## Overview

The recipe sharing system has been migrated from storing `sharedWith` arrays in recipe documents to a separate `recipeShares` collection. This allows recipes to be shared with thousands of users without hitting Firestore document size limits (1MB).

## Architecture

### New Components

1. **RecipeShare Model** (`Misoto/Models/RecipeShare.swift`)
   - Represents a share relationship between a recipe and a user
   - Fields: `id`, `recipeID`, `userID`, `sharedBy`, `sharedAt`, `createdAt`

2. **RecipeShareService** (`Misoto/Services/RecipeShareService.swift`)
   - Manages all share operations
   - Methods:
     - `shareRecipe(recipeID:with:)` - Share with multiple users
     - `unshareRecipe(recipeID:from:)` - Remove shares
     - `removeAllShares(for:)` - Remove all shares for a recipe
     - `isRecipeShared(recipeID:with:)` - Check if recipe is shared with user
     - `getSharedUserIDs(for:)` - Get all user IDs a recipe is shared with
     - `getRecipesSharedWithMe()` - Get all recipes shared with current user
     - `getRecipesSharedByMe()` - Get all recipes shared by current user
     - `getShares(for:)` - Get all shares for a recipe

### Updated Components

1. **RecipeService** (`Misoto/Services/RecipeService.swift`)
   - `fetchRecipe(byID:)` - Now checks `recipeShares` collection first, falls back to `sharedWith` array for backward compatibility
   - `updateRecipeSharing(recipeID:sharedWith:)` - Now uses `RecipeShareService` instead of updating `sharedWith` array
   - `toggleRecipePrivacy()` - Removes shares when making recipe public, preserves shares when making private
   - Filter methods (`fetchAllRecipes`, `searchRecipes`, `fetchFavoriteRecipes`) - Pre-fetch shared recipe IDs for efficient filtering

2. **Firestore Rules** (`FIRESTORE_RULES.txt`)
   - Added `recipeShares` collection rules
   - Users can read shares where they are the recipient (`userID`)
   - Recipe owners can read/create/delete shares for their recipes
   - Kept backward compatibility with `sharedWith` array check in recipe rules

## Backward Compatibility

The system maintains backward compatibility with existing recipes that use the `sharedWith` array:

1. **Reading Recipes**: Checks `recipeShares` first, then falls back to `sharedWith` array
2. **Auto-Migration**: When a recipe is accessed via old `sharedWith`, it's automatically migrated to `recipeShares`
3. **Dual Updates**: When sharing, both systems are updated (new system primary, old system for compatibility)

## Data Flow

### Sharing a Recipe
1. User selects users to share with
2. `updateRecipeSharing()` is called with user IDs
3. `RecipeShareService.shareRecipe()` creates share documents in `recipeShares` collection
4. Recipe is marked as `isPrivate: true`
5. Old `sharedWith` array is kept for backward compatibility (optional)

### Accessing a Shared Recipe
1. `fetchRecipe(byID:)` is called
2. If recipe is private, check if user is owner
3. If not owner, check `recipeShares` collection
4. If not found in new system, check old `sharedWith` array
5. If found in old system, auto-migrate to new system
6. Return recipe if access granted, `nil` otherwise

### Filtering Recipes
1. Pre-fetch all recipe IDs shared with current user from `recipeShares`
2. Filter recipes: public OR owner OR in shared recipe IDs OR in old `sharedWith` array

## Firestore Structure

### recipeShares Collection
```
recipeShares/{shareId}
  - id: string
  - recipeID: string
  - userID: string (recipient)
  - sharedBy: string (recipe owner)
  - sharedAt: timestamp
  - createdAt: timestamp
```

### Indexes Required
- `recipeID` + `userID` (for checking if recipe is shared with user)
- `userID` (for getting all recipes shared with user)
- `sharedBy` (for getting all recipes shared by user)

## Migration Notes

- Existing recipes with `sharedWith` arrays continue to work
- Shares are automatically migrated when accessed
- No manual migration needed
- Old `sharedWith` arrays can be cleaned up later if desired

## Performance Considerations

- **Pre-fetching**: Shared recipe IDs are pre-fetched for filtering operations to avoid N+1 queries
- **Batch Operations**: Share creation/deletion uses Firestore batch writes
- **Efficient Queries**: Uses indexed queries on `recipeID` and `userID`

## Testing Checklist

- [ ] Share recipe with single user
- [ ] Share recipe with multiple users
- [ ] Share recipe with thousands of users (stress test)
- [ ] Recipient can view shared recipe
- [ ] Recipient cannot view unshared recipe
- [ ] Owner can view their own private recipe
- [ ] Public recipes are visible to everyone
- [ ] Making recipe public removes all shares
- [ ] Making recipe private preserves existing shares
- [ ] Backward compatibility with old `sharedWith` arrays
- [ ] Auto-migration from old to new system

## Future Enhancements

1. **Share Permissions**: Add read/write permissions to shares
2. **Share Expiration**: Add expiration dates for shares
3. **Share Notifications**: Notify users when recipes are shared with them
4. **Bulk Operations**: Add UI for bulk sharing/unsharing
5. **Share Analytics**: Track share counts and popular shared recipes
