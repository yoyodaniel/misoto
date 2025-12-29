# ✅ Remaining Setup Steps Checklist

Use this checklist to track what you still need to do:

## ✅ Completed (You've Done These)
- [x] Created Firebase project
- [x] Added iOS app to Firebase
- [x] Added GoogleService-Info.plist to Xcode
- [x] Enabled Google Sign In in Firebase Console
- [x] Enabled Apple Sign In in Firebase Console
- [x] Added Sign in with Apple capability in Xcode
- [x] Configured URL scheme for Google Sign In

## ⚠️ Still Need to Do

### 1. Add Firebase SDK Packages
- [ ] **File** → **Add Package Dependencies...**
- [ ] URL: `https://github.com/firebase/firebase-ios-sdk`
- [ ] Select: **FirebaseAuth**, **FirebaseFirestore**, **FirebaseCore**
- [ ] Add to target: **Misoto**

### 2. Add GoogleSignIn SDK Package
- [ ] **File** → **Add Package Dependencies...**
- [ ] URL: `https://github.com/google/GoogleSignIn-iOS`
- [ ] Select: **GoogleSignIn**
- [ ] Add to target: **Misoto**

### 3. Create Firestore Database
- [ ] Go to Firebase Console → **Firestore Database**
- [ ] Click **"Create database"**
- [ ] Select **"Start in test mode"**
- [ ] Choose a location (closest to you)
- [ ] Click **"Enable"**
- [ ] Wait for database to be created (~1 minute)

### 4. Set Up Firestore Security Rules
- [ ] In Firestore Database, click **"Rules"** tab
- [ ] Copy and paste the rules from `FIRESTORE_RULES.txt`
- [ ] Click **"Publish"**

### 5. Build and Test
- [ ] Select a simulator or device in Xcode
- [ ] Press **⌘ + R** to build and run
- [ ] Test "Continue with Google" button
- [ ] Test "Sign in with Apple" button
- [ ] Verify you can create a recipe
- [ ] Verify you can favorite recipes

---

## 🎯 Priority Order

Do these in order:

1. **Add Firebase SDK** (Step 1) - Required for app to build
2. **Add GoogleSignIn SDK** (Step 2) - Required for Google Sign In
3. **Create Firestore Database** (Step 3) - Required for data storage
4. **Set Security Rules** (Step 4) - Required for app to work
5. **Build and Test** (Step 5) - Final verification

---

## 🐛 If You Get Build Errors

**"No such module 'FirebaseCore'"**
→ You haven't added Firebase packages yet (Step 1)

**"No such module 'GoogleSignIn'"**
→ You haven't added GoogleSignIn package yet (Step 2)

**Firestore permission denied**
→ You haven't created Firestore database (Step 3) or set rules (Step 4)

---

## 📝 Quick Reference

- **Firebase Rules**: Copy from `FIRESTORE_RULES.txt` file
- **Package URLs**: 
  - Firebase: `https://github.com/firebase/firebase-ios-sdk`
  - GoogleSignIn: `https://github.com/google/GoogleSignIn-iOS`

