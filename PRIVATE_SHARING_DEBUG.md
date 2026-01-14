# Private Recipe Sharing Debug Guide

## Issue: Shared users cannot view private recipes

## Step-by-Step Debugging

### 1. Verify Recipe is Saved Correctly

**On the recipe owner's device:**
1. Share a recipe with a specific user
2. Check Xcode console for logs:
   - Look for: `✅ Recipe [ID] sharing updated successfully. Verified sharedWith: [userIDs]`
   - Verify the user IDs in the array match the recipient's user ID

**In Firebase Console:**
1. Go to Firestore Database → `recipes` collection
2. Find the recipe document
3. Check these fields:
   - `isPrivate` = `true` ✅
   - `sharedWith` = `["userID1", "userID2", ...]` ✅
   - Verify the recipient's user ID is in the array

### 2. Verify Firestore Rules

**Current Rules:**
```javascript
// Allow authenticated users to read private recipes shared with them
allow read: if request.auth != null && 
  ('isPrivate' in resource.data && resource.data.isPrivate == true) &&
  ('sharedWith' in resource.data && request.auth.uid in resource.data.sharedWith);
```

**Check:**
- Rules are deployed to Firebase
- No syntax errors in rules
- Rules allow recipe authors to update `sharedWith`

### 3. Test on Recipient's Device

**On the recipient's device:**
1. Sign in with the account that should have access
2. Try to access the recipe (via direct link, search, or if visible in their feed)
3. Check Xcode console for logs:
   - Look for: `🔍 Recipe [ID] access check - isPrivate: true, isOwner: false, isSharedWithUser: true/false`
   - Look for: `🔍 Current user ID: [ID], sharedWith: [array]`
   - Look for: `❌ Access denied` or `✅ Recipe fetched successfully`

### 4. Common Issues and Fixes

#### Issue A: User ID Mismatch
**Symptom:** `isSharedWithUser: false` even though recipe was shared
**Fix:** 
- Verify the user ID in `sharedWith` matches exactly (case-sensitive)
- Check for extra spaces or formatting issues
- Re-share the recipe to ensure correct user ID

#### Issue B: Firestore Permission Error
**Symptom:** `Missing or insufficient permissions` error
**Fix:**
- Verify Firestore rules are deployed
- Check that the rule syntax is correct
- Ensure the user is authenticated

#### Issue C: Recipe Not Found
**Symptom:** Recipe returns `nil` or doesn't exist
**Fix:**
- Verify recipe ID is correct
- Check if recipe was deleted
- Verify recipe exists in Firestore

#### Issue D: sharedWith Array is Empty
**Symptom:** Recipe shows `sharedWith: []` after sharing
**Fix:**
- Check if `updateRecipeSharing` completed successfully
- Verify no errors in console during sharing
- Check Firestore rules allow updating `sharedWith`

### 5. Manual Verification Steps

**In Firebase Console:**
1. Open the recipe document
2. Check `sharedWith` field - should be an array of user IDs
3. Copy the recipient's user ID from their user document
4. Verify it exactly matches an entry in `sharedWith` array

**Test Query:**
Try this in Firebase Console → Firestore → recipes collection:
- Filter: `isPrivate == true`
- Check if `sharedWith` contains the recipient's user ID

### 6. Code Verification

**The code checks access in two places:**

1. **Firestore Rules** (server-side):
   - Allows read if user is in `sharedWith` array
   - This is the primary security check

2. **App Code** (client-side):
   - `fetchRecipe(byID:)` also checks `sharedWith.contains(userID)`
   - This is a secondary check for filtering

**Both must pass for the user to see the recipe.**

### 7. Testing Checklist

- [ ] Recipe owner can view their own private recipe
- [ ] Recipe owner can share recipe with user ID X
- [ ] Firestore document shows `sharedWith: ["userIDX"]`
- [ ] User X is authenticated when trying to view
- [ ] User X's UID matches exactly with entry in `sharedWith`
- [ ] Firestore rules are deployed
- [ ] No permission errors in console
- [ ] Recipe is marked as `isPrivate: true`

### 8. Debug Logs to Look For

**When Sharing:**
```
🔍 Updating recipe [ID] sharing - sharedWith: [userIDs]
✅ Recipe [ID] sharing updated successfully. Verified sharedWith: [userIDs]
```

**When Viewing (as recipient):**
```
🔍 Recipe [ID] access check - isPrivate: true, isOwner: false, isSharedWithUser: true
🔍 Current user ID: [ID], sharedWith: [array]
✅ Recipe [ID] fetched successfully - isPrivate: true, sharedWith: 1 users
```

**If Access Denied:**
```
❌ Access denied: User [ID] cannot access private recipe [ID]
```

### 9. Quick Fixes

**If sharing doesn't save:**
- Check Firestore rules allow recipe authors to update
- Verify user is authenticated
- Check for permission errors

**If recipient can't view:**
- Verify their user ID is in `sharedWith` array
- Check they're signed in with the correct account
- Verify Firestore rules are deployed
- Check console for permission errors

### 10. Firestore Rules Summary

**Read Access:**
- ✅ Public recipes: Anyone can read
- ✅ Private recipes: Only owner or users in `sharedWith` can read

**Write Access:**
- ✅ Recipe authors can update their own recipes (includes `sharedWith`)

**Current Rules Status:** ✅ Correctly configured
