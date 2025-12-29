# Misoto Recipe App - Setup Guide

Follow these steps in order to set up your recipe app:

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** (or "Create a project" if it's your first)
3. Enter project name: `Misoto` (or any name you prefer)
4. Click **"Continue"**
5. **Optional**: Enable Google Analytics (recommended for production)
6. Click **"Create project"**
7. Wait for project creation to complete
8. Click **"Continue"**

## Step 2: Add iOS App to Firebase

1. In your Firebase project dashboard, click the **iOS icon** (or "Add app" → iOS)
2. Enter your iOS bundle ID: `com.miniadd.Misoto`
   - You can find this in Xcode: Project → Target → General → Bundle Identifier
3. Enter App nickname (optional): `Misoto`
4. Enter App Store ID (optional, leave blank for now)
5. Click **"Register app"**
6. **Download** the `GoogleService-Info.plist` file
   - ⚠️ **IMPORTANT**: Save this file - you'll need it in the next step!

## Step 3: Add GoogleService-Info.plist to Xcode

1. Open your project in **Xcode**
2. In the Project Navigator (left sidebar), right-click on the **"Misoto"** folder
3. Select **"Add Files to Misoto..."**
4. Navigate to where you downloaded `GoogleService-Info.plist`
5. Select the file
6. **IMPORTANT**: Make sure these checkboxes are selected:
   - ✅ "Copy items if needed"
   - ✅ "Misoto" target is checked
7. Click **"Add"**
8. Verify the file appears in your project (should be at the root of the Misoto folder)

## Step 4: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. In the search bar, paste: `https://github.com/firebase/firebase-ios-sdk`
3. Click **"Add Package"**
4. Select the following packages (check the boxes):
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseCore**
5. Click **"Add Package"**
6. Wait for the packages to download and integrate

## Step 5: Enable Sign in with Apple in Firebase

1. Go back to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click **"Authentication"**
4. Click **"Get started"** (if you see this)
5. Click the **"Sign-in method"** tab
6. Click on **"Apple"** in the providers list
7. Toggle **"Enable"** to ON
8. Enter your **App ID** (optional, but recommended):
   - This is your bundle ID: `com.miniadd.Misoto`
9. Click **"Save"**

## Step 6: Create Firestore Database

1. In Firebase Console, click **"Firestore Database"** in the left sidebar
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
   - ⚠️ **Note**: You'll need to update security rules before production
4. Click **"Next"**
5. Choose a **Cloud Firestore location** (choose closest to your users)
6. Click **"Enable"**
7. Wait for database creation (takes ~1 minute)

## Step 7: Set Up Firestore Security Rules

1. In Firestore Database, click the **"Rules"** tab
2. Replace the existing rules with this code:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Recipes collection
    match /recipes/{recipeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.authorID == request.auth.uid;
    }
    
    // Favorites collection
    match /favorites/{favoriteId} {
      allow read: if request.auth != null && 
        resource.data.userID == request.auth.uid;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.userID;
    }
    
    // Follows collection
    match /follows/{followId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.followerID;
    }
  }
}
```

3. Click **"Publish"**

## Step 8: Enable Sign in with Apple in Xcode

1. In Xcode, select your **project** in the Project Navigator (top item)
2. Select the **"Misoto"** target
3. Click the **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button (top left)
5. Search for and add **"Sign In with Apple"**
6. Verify it appears in your capabilities list

## Step 9: Verify Your Code

1. Open `MisotoApp.swift` and verify it has:
   ```swift
   import FirebaseCore
   
   init() {
       FirebaseApp.configure()
   }
   ```

2. Make sure `GoogleService-Info.plist` is in your project and included in the target

## Step 10: Build and Run

1. In Xcode, select a **simulator** or **connected device**
2. Press **⌘ + R** (or click the Play button) to build and run
3. The app should launch and show the login screen
4. Tap **"Sign in with Apple"** to test authentication

## Troubleshooting

### Build Errors

**Error: "No such module 'FirebaseCore'"**
- Solution: Make sure you added Firebase packages in Step 4
- Try: File → Packages → Reset Package Caches

**Error: "GoogleService-Info.plist not found"**
- Solution: Make sure the file is in your project and target membership is checked
- Verify: Select the file → File Inspector → Target Membership → ✅ Misoto

### Runtime Errors

**"Sign in with Apple" button doesn't work**
- Check: Firebase Console → Authentication → Sign-in method → Apple is enabled
- Check: Xcode → Signing & Capabilities → Sign In with Apple is added

**Firestore permission denied**
- Check: Firestore Rules are published (Step 7)
- Verify: You're signed in with Apple

**Can't create recipes**
- Check: Firestore Database is created (Step 6)
- Check: Security rules allow creation (Step 7)

## Next Steps After Setup

1. ✅ Test creating a recipe
2. ✅ Test favoriting recipes
3. ✅ Test following users
4. ✅ Test all CRUD operations

## Production Checklist (Before App Store)

- [ ] Update Firestore security rules for production
- [ ] Set up proper error handling
- [ ] Add image upload functionality (Firebase Storage)
- [ ] Configure App Store Connect with Sign in with Apple
- [ ] Test on physical device
- [ ] Set up Firebase Analytics (optional)

---

**Need Help?** Check the Firebase documentation or review the error messages in Xcode console.

