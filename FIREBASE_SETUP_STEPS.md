# 🔥 Firebase Setup - Step by Step Guide

Follow these steps **in order** to set up Firebase for your Misoto app.

---

## ✅ Step 1: Create Firebase Project

1. Go to [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Click **"Add project"** (or "Create a project")
3. Enter project name: `Misoto` (or any name you like)
4. Click **"Continue"**
5. **Optional**: Enable Google Analytics (you can skip this for now)
6. Click **"Create project"**
7. Wait for project to be created (takes ~30 seconds)
8. Click **"Continue"** when done

**✅ Checkpoint**: You should now see your Firebase project dashboard.

---

## ✅ Step 2: Add iOS App to Firebase

1. In your Firebase project dashboard, look for the app icons at the top
2. Click the **iOS icon** (🍎) - or click "Add app" → iOS
3. Fill in the iOS app details:
   - **iOS bundle ID**: `com.miniadd.Misoto`
     - ⚠️ **Important**: Check this in Xcode: Project → Target → General → Bundle Identifier
   - **App nickname** (optional): `Misoto`
   - **App Store ID** (optional): Leave blank
4. Click **"Register app"**
5. **Download** the `GoogleService-Info.plist` file
   - ⚠️ **CRITICAL**: Save this file somewhere you can find it!
6. Click **"Next"** (you can skip the next steps for now)
7. Click **"Continue to console"**

**✅ Checkpoint**: You should have downloaded `GoogleService-Info.plist` file.

---

## ✅ Step 3: Add GoogleService-Info.plist to Xcode

1. Open your **Xcode** project
2. In the left sidebar (Project Navigator), find the **"Misoto"** folder (blue icon)
3. **Right-click** on the "Misoto" folder
4. Select **"Add Files to Misoto..."**
5. Navigate to where you saved `GoogleService-Info.plist`
6. Select the file
7. **IMPORTANT**: Make sure these are checked:
   - ✅ **"Copy items if needed"** (should be checked)
   - ✅ **"Misoto"** target is checked (under "Add to targets")
8. Click **"Add"**
9. Verify the file appears in your project (should be at the root level of Misoto folder)

**✅ Checkpoint**: `GoogleService-Info.plist` should be visible in your Xcode project.

---

## ✅ Step 4: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies...**
2. In the search bar at the top, paste this URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Press **Enter** or click the search icon
4. Wait for it to load (you'll see "firebase-ios-sdk" appear)
5. Click **"Add Package"** button
6. Wait for package to resolve (takes ~10 seconds)
7. You'll see a list of products. **Check these boxes**:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseCore**
8. Make sure **"Misoto"** is selected in the "Add to Target" dropdown
9. Click **"Add Package"**
10. Wait for it to finish (you'll see a progress indicator)

**Now add Google Sign In SDK:**
11. Go to **File** → **Add Package Dependencies...** again
12. Paste this URL:
    ```
    https://github.com/google/GoogleSignIn-iOS
    ```
13. Click **"Add Package"**
14. Wait for it to resolve
15. **Check this box**:
    - ✅ **GoogleSignIn**
16. Make sure **"Misoto"** is selected
17. Click **"Add Package"**

**✅ Checkpoint**: Firebase packages should appear in your Project Navigator under "Package Dependencies".

---

## ✅ Step 5: Enable Sign-in Methods in Firebase Console

### Enable Google Sign In

1. Go back to [Firebase Console](https://console.firebase.google.com/)
2. Make sure you're in your **Misoto** project
3. In the left sidebar, click **"Authentication"**
4. If you see "Get started", click it
5. Click the **"Sign-in method"** tab (at the top)
6. You'll see a list of providers. Find **"Google"** in the list
7. Click on **"Google"**
8. Toggle the **"Enable"** switch to **ON**
9. Enter a **Project support email** (your email address)
10. Click **"Save"**

**✅ Checkpoint**: Google should show as "Enabled" in the providers list.

### Enable Sign in with Apple

1. Still in the **"Sign-in method"** tab
2. Find **"Apple"** in the providers list
3. Click on **"Apple"**
4. Toggle the **"Enable"** switch to **ON**
5. **Optional**: Enter your App ID: `com.miniadd.Misoto`
6. Click **"Save"**

**✅ Checkpoint**: Both Google and Apple should show as "Enabled" in the providers list.

---

## ✅ Step 6: Create Firestore Database

1. In Firebase Console, click **"Firestore Database"** in the left sidebar
2. Click **"Create database"** button
3. Select **"Start in test mode"** (for development)
   - ⚠️ **Note**: This allows all reads/writes. We'll secure it in the next step.
4. Click **"Next"**
5. Choose a **Cloud Firestore location**:
   - Select the region closest to you (e.g., `us-central`, `europe-west`, etc.)
6. Click **"Enable"**
7. Wait for database to be created (~1 minute)
   - You'll see a progress indicator

**✅ Checkpoint**: You should see "Cloud Firestore" page with "No data" message.

---

## ✅ Step 7: Set Up Firestore Security Rules

1. In Firestore Database page, click the **"Rules"** tab (at the top)
2. You'll see default test mode rules. **Replace everything** with this code:

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

3. Click **"Publish"** button
4. You'll see a confirmation message

**✅ Checkpoint**: Rules should show as "Published" with a green checkmark.

---

## ✅ Step 8: Enable Sign in with Apple in Xcode

1. In **Xcode**, select your **project** in the Project Navigator (top item, blue icon)
2. Select the **"Misoto"** target (under TARGETS)
3. Click the **"Signing & Capabilities"** tab
4. Click the **"+ Capability"** button (top left, next to "All")
5. In the search box, type: `Sign In with Apple`
6. Double-click **"Sign In with Apple"** to add it
7. Verify it appears in your capabilities list

**✅ Checkpoint**: "Sign In with Apple" should appear in your capabilities.

---

## ✅ Step 9: Verify Your Code

1. Open `MisotoApp.swift` in Xcode
2. Verify it has these imports:
   ```swift
   import SwiftUI
   import FirebaseCore
   ```
3. Verify it has this in the `init()`:
   ```swift
   init() {
       FirebaseApp.configure()
   }
   ```
4. If it's missing, add it. The file should look like:
   ```swift
   import SwiftUI
   import FirebaseCore

   @main
   struct MisotoApp: App {
       @StateObject private var authViewModel = AuthViewModel()
       
       init() {
           FirebaseApp.configure()
       }
       
       var body: some Scene {
           WindowGroup {
               if authViewModel.isAuthenticated {
                   MainTabView()
               } else {
                   LoginView()
               }
           }
       }
   }
   ```

**✅ Checkpoint**: Your code should have Firebase configured.

---

## ✅ Step 10: Build and Test

1. In Xcode, select a **simulator** (e.g., iPhone 15 Pro)
2. Press **⌘ + R** (or click the Play ▶️ button)
3. Wait for the app to build and launch
4. You should see the login screen with "Sign in with Apple" button
5. Tap the button to test authentication

**✅ Checkpoint**: App should launch and show login screen.

---

## 🐛 Troubleshooting

### Error: "No such module 'FirebaseCore'"
**Solution**: 
- Make sure you added Firebase packages in Step 4
- Try: File → Packages → Reset Package Caches
- Clean build folder: Product → Clean Build Folder (⌘ + Shift + K)
- Build again

### Error: "GoogleService-Info.plist not found"
**Solution**:
- Make sure the file is in your project (check Project Navigator)
- Select the file → File Inspector (right panel) → Target Membership → ✅ Misoto should be checked
- Try removing and re-adding the file

### "Sign in with Apple" button doesn't work
**Solution**:
- Check Firebase Console → Authentication → Sign-in method → Apple is enabled
- Check Xcode → Signing & Capabilities → Sign In with Apple is added
- Make sure you're testing on a real device or simulator with Apple ID signed in

### Firestore permission denied errors
**Solution**:
- Check Firestore Rules are published (Step 7)
- Make sure you're signed in with Apple first
- Check the rules match exactly what's in Step 7

### Build errors about missing imports
**Solution**:
- Make sure all three packages are added: FirebaseAuth, FirebaseFirestore, FirebaseCore
- Try: File → Packages → Update to Latest Package Versions

---

## 📋 Quick Checklist

Before you run the app, make sure:

- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` downloaded and added to Xcode
- [ ] Firebase SDK packages added (FirebaseAuth, FirebaseFirestore, FirebaseCore)
- [ ] Sign in with Apple enabled in Firebase Console
- [ ] Firestore database created
- [ ] Firestore security rules published
- [ ] Sign in with Apple capability added in Xcode
- [ ] `FirebaseApp.configure()` in MisotoApp.swift

---

## 🎉 You're Done!

Once all steps are complete, your app should:
- ✅ Build without errors
- ✅ Show login screen
- ✅ Allow Sign in with Apple
- ✅ Create and save recipes
- ✅ All CRUD operations working

If you encounter any issues, check the Troubleshooting section above!

