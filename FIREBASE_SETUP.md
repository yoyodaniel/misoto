# Firebase Setup Guide

This app requires Firebase to be configured. Follow these steps to set up Firebase:

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enable Google Analytics (optional but recommended)

## 2. Add iOS App to Firebase

1. In your Firebase project, click "Add app" and select iOS
2. Enter your bundle identifier: `com.miniadd.Misoto`
3. Download the `GoogleService-Info.plist` file
4. Add the `GoogleService-Info.plist` file to your Xcode project:
   - Drag it into the `Misoto` folder in Xcode
   - Make sure "Copy items if needed" is checked
   - Select your target

## 3. Add Firebase SDK via Swift Package Manager

1. In Xcode, go to File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select the following packages:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseCore
4. Click "Add Package"

## 4. Enable Firebase Services

### Authentication
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Apple" as a sign-in provider
3. Configure the OAuth redirect URL if needed

### Firestore Database
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **test mode** for development (you can secure it later)
4. Choose a location for your database

## 5. Firestore Security Rules (Development)

For development, you can use these basic rules. **Update them for production!**

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

## 6. Enable Sign in with Apple in Xcode

1. In Xcode, select your project
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Sign In with Apple"

## 7. Test the Setup

1. Build and run the app
2. You should see the login screen with "Sign in with Apple" button
3. After signing in, you should see the main tab view

## Troubleshooting

- **Build errors**: Make sure all Firebase packages are added and `GoogleService-Info.plist` is in the project
- **Authentication fails**: Check that Sign in with Apple is enabled in Firebase Console
- **Firestore errors**: Verify your security rules and that Firestore is enabled in Firebase Console

