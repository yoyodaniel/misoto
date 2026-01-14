# Subscription Testing Summary

## 🎯 What You Need to Do

### Step 1: Set Up Subscriptions in App Store Connect (REQUIRED FIRST)

**This is the most important step** - subscriptions must be created in App Store Connect before testing:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Features** → **In-App Purchases**
3. Create a **Subscription Group** named: `Misoto Premium`
4. Create **Monthly Subscription**:
   - Product ID: `com.misoto.premium.monthly` ⚠️ **Must match exactly**
   - Duration: 1 Month
   - Price: $4.99 USD
5. Create **Yearly Subscription**:
   - Product ID: `com.misoto.premium.yearly` ⚠️ **Must match exactly**
   - Duration: 1 Year
   - Price: $49.99 USD
6. Set both to **"Ready to Submit"** status
7. **Wait 24-48 hours** for Apple to propagate the subscriptions

### Step 2: Create Sandbox Test Accounts

1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Create 2-3 test accounts (use emails without existing Apple IDs)

### Step 3: Prepare Your Device

1. **Sign out** of your regular Apple ID:
   - Settings → App Store → Sign Out
2. Connect your iPhone/iPad to your Mac
3. Build and run the app from Xcode (not Simulator)

### Step 4: Test the Subscription Flow

1. **Launch the app** and sign in
2. Go to **Settings** → **Subscription** → **Upgrade Now**
3. Verify products load (Monthly & Yearly)
4. Select a subscription and tap **Subscribe**
5. Sign in with a **sandbox test account** when prompted
6. Complete the purchase

### Step 5: Verify Everything Works

**In the App**:
- ✅ Settings shows "Premium" account type
- ✅ Can create more than 15 recipes
- ✅ Can perform more than 5 AI extractions
- ✅ Usage limits show "Unlimited"

**In Firestore Console**:
- ✅ `subscriptions/{userId}` document exists with:
  - `tier` = "premium"
  - `isActive` = true
  - `expiresAt` = future date
  - `productID` = correct product ID
- ✅ `users/{userId}` document has:
  - `premiumUser` = true

---

## 📋 Quick Testing Checklist

- [ ] Subscriptions created in App Store Connect
- [ ] Product IDs match exactly: `com.misoto.premium.monthly` and `com.misoto.premium.yearly`
- [ ] Subscriptions in "Ready to Submit" status
- [ ] Waited 24-48 hours for propagation
- [ ] Sandbox test accounts created
- [ ] Signed out of regular Apple ID on device
- [ ] App running from Xcode on real device
- [ ] Products load successfully
- [ ] Purchase completes successfully
- [ ] Premium status updates in app
- [ ] Firestore documents updated correctly
- [ ] Premium features unlocked
- [ ] Restore purchases works

---

## 🔍 What to Check

### Product IDs (CRITICAL)
Your code uses:
- `com.misoto.premium.monthly`
- `com.misoto.premium.yearly`

These **must match exactly** in App Store Connect (case-sensitive).

### Firestore Rules
Your Firestore rules are already configured correctly:
- ✅ `subscriptions` collection allows authenticated users to write their own subscription
- ✅ `users` collection allows users to update their own document (includes `premiumUser` field)

### Code Implementation
Your subscription code is complete and ready:
- ✅ `SubscriptionService.swift` - Full StoreKit 2 implementation
- ✅ `SubscriptionViewModel.swift` - UI state management
- ✅ `PremiumView.swift` - Purchase UI
- ✅ Transaction listener for automatic updates
- ✅ Firestore sync for subscription status
- ✅ Premium status updates user document

---

## 🐛 Common Issues

### "Product Not Found"
- **Cause**: Product IDs don't match or subscriptions not ready
- **Fix**: Verify product IDs match exactly, ensure "Ready to Submit" status, wait 24-48 hours

### Can't Sign In Sandbox Account
- **Cause**: Still signed in to regular Apple ID
- **Fix**: Sign out in Settings → App Store

### Purchase Succeeds But No Update
- **Cause**: Firestore rules or network issue
- **Fix**: Check Firestore rules, check console logs, wait a few seconds

---

## 📚 Detailed Guides

For comprehensive testing instructions, see:
- **`SUBSCRIPTION_TESTING_GUIDE.md`** - Complete step-by-step testing guide
- **`SUBSCRIPTION_TESTING_CHECKLIST.md`** - Quick reference checklist
- **`APP_STORE_CONNECT_SETUP.md`** - App Store Connect setup instructions

---

## ✅ Success Criteria

Your subscription is working when:
1. Products load from App Store Connect
2. Purchase completes successfully
3. Premium status updates immediately
4. Firestore documents are created/updated
5. Premium features are unlocked
6. Free tier limits are bypassed
7. Restore purchases works

---

## 🚀 Next Steps

After successful testing:
1. Submit your app with subscriptions for App Store review
2. Subscriptions will be reviewed together with your app
3. Once approved, subscriptions will be available to users

---

**Important**: You **cannot** test subscriptions until they are created in App Store Connect and in "Ready to Submit" status. This is the first and most critical step.
