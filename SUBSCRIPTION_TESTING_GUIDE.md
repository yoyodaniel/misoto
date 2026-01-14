# Subscription Testing Guide

Complete guide for testing subscription functionality in Misoto.

## 📋 Prerequisites

### 1. App Store Connect Setup (Required First)

Before testing, you **must** set up subscriptions in App Store Connect:

1. **Create Subscription Group**:
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Navigate to your app → **Features** → **In-App Purchases**
   - Create a new **Subscription Group** named: `Misoto Premium`

2. **Create Monthly Subscription**:
   - Product ID: `com.misoto.premium.monthly` ⚠️ **Must match exactly**
   - Duration: 1 Month
   - Price: $4.99 USD (or your local equivalent)
   - Status: Must be **"Ready to Submit"** or **"Approved"**

3. **Create Yearly Subscription**:
   - Product ID: `com.misoto.premium.yearly` ⚠️ **Must match exactly**
   - Duration: 1 Year
   - Price: $49.99 USD (or your local equivalent)
   - Status: Must be **"Ready to Submit"** or **"Approved"**

4. **Wait for Propagation**:
   - After creating subscriptions, wait **24-48 hours** for Apple to propagate them
   - Subscriptions must be in "Ready to Submit" status to be testable

### 2. Sandbox Test Accounts

Create sandbox test accounts in App Store Connect:

1. Go to **Users and Access** → **Sandbox Testers**
2. Click **+** to create new test accounts
3. Create at least **2-3 test accounts** for comprehensive testing
4. **Important**: Use email addresses that don't have Apple IDs associated with them

---

## 🧪 Testing Setup

### Step 1: Prepare Your Test Device

1. **Sign Out of Your Apple ID**:
   - Go to **Settings** → **App Store** → **Sign Out**
   - This is critical - you must be signed out to use sandbox accounts

2. **Clear App Data** (Optional but recommended):
   - Delete the app from your device
   - Reinstall from Xcode to start fresh

3. **Ensure Device is Connected**:
   - Connect your iPhone/iPad to your Mac
   - Device should appear in Xcode

### Step 2: Configure Xcode for Testing

1. **Open Project in Xcode**
2. **Select Your Device** as the run destination (not Simulator)
3. **Build and Run** the app from Xcode

---

## ✅ Step-by-Step Testing Procedures

### Test 1: Verify Products Load

**Objective**: Ensure subscription products are correctly loaded from App Store Connect.

**Steps**:
1. Launch the app
2. Sign in with a test account (or create one)
3. Navigate to **Settings** → **Subscription** section
4. Tap **"Upgrade Now"** or navigate to Premium screen

**Expected Results**:
- ✅ Products should load (Monthly and Yearly subscriptions)
- ✅ Prices should display correctly
- ✅ No error messages
- ✅ Loading indicator appears briefly, then products show

**What to Check**:
- [ ] Both monthly and yearly products appear
- [ ] Prices match what you set in App Store Connect
- [ ] Product descriptions are visible
- [ ] No "Product not found" errors

**If Products Don't Load**:
- Verify product IDs match exactly: `com.misoto.premium.monthly` and `com.misoto.premium.yearly`
- Check subscriptions are in "Ready to Submit" status in App Store Connect
- Wait 24-48 hours after creating subscriptions
- Ensure you're testing on a real device (not Simulator)
- Check Xcode console for error messages

---

### Test 2: Purchase Monthly Subscription

**Objective**: Test the complete purchase flow for monthly subscription.

**Steps**:
1. On the Premium screen, select **Monthly** subscription
2. Tap **"Subscribe"** button
3. When prompted, sign in with a **sandbox test account**
4. Confirm the purchase

**Expected Results**:
- ✅ Purchase dialog appears
- ✅ Sandbox account sign-in prompt appears
- ✅ Purchase completes successfully
- ✅ App returns to previous screen
- ✅ Subscription status updates to Premium
- ✅ User's `premiumUser` field in Firestore is set to `true`
- ✅ Subscription document is created in Firestore `subscriptions` collection

**What to Check in Firestore**:
1. Go to Firebase Console → Firestore Database
2. Check `subscriptions/{userId}` document:
   - [ ] `tier` = "premium"
   - [ ] `isActive` = true
   - [ ] `expiresAt` = future date (1 month from now)
   - [ ] `productID` = "com.misoto.premium.monthly"
   - [ ] `transactionID` is present

3. Check `users/{userId}` document:
   - [ ] `premiumUser` = true

**What to Check in App**:
- [ ] Settings shows "Premium" account type
- [ ] Usage limits show "Unlimited" or -1
- [ ] Can create more than 15 recipes
- [ ] Can perform more than 5 AI extractions

**Console Logs to Look For**:
```
✅ Subscription updated: Premium until [date]
✅ User premium status updated: true
```

---

### Test 3: Purchase Yearly Subscription

**Objective**: Test the complete purchase flow for yearly subscription.

**Steps**:
1. Use a **different sandbox test account** (to test fresh purchase)
2. On the Premium screen, select **Yearly** subscription
3. Tap **"Subscribe"** button
4. Sign in with sandbox account and confirm

**Expected Results**:
- ✅ Same as Test 2, but with yearly subscription
- ✅ `expiresAt` = 1 year from purchase date
- ✅ `productID` = "com.misoto.premium.yearly"

**What to Check**:
- [ ] All checks from Test 2
- [ ] Expiration date is 1 year in the future
- [ ] Product ID is correct for yearly

---

### Test 4: Verify Premium Features Unlocked

**Objective**: Ensure premium features are actually unlocked after purchase.

**Steps**:
1. After successful purchase, try to:
   - Create a recipe (should not show limit error)
   - Extract recipe from image (should not show limit error)
   - Generate AI description (should not show limit error)

**Expected Results**:
- ✅ No "limit reached" errors
- ✅ All features work without restrictions
- ✅ Settings shows "Premium" status

**What to Check**:
- [ ] Can create recipe #16, #17, etc. (beyond free tier limit of 15)
- [ ] Can perform AI extraction #6, #7, etc. (beyond free tier limit of 5)
- [ ] No upgrade prompts appear

---

### Test 5: Restore Purchases

**Objective**: Test that users can restore their subscription on a new device.

**Steps**:
1. **On a different device** (or after deleting/reinstalling app):
   - Sign in with the same account that has an active subscription
   - Navigate to Premium screen
   - Tap **"Restore Purchases"**

**Expected Results**:
- ✅ Subscription status is restored
- ✅ Premium features are unlocked
- ✅ Firestore subscription document is updated
- ✅ `premiumUser` field is set to `true`

**What to Check**:
- [ ] Subscription status loads correctly
- [ ] Premium features are unlocked
- [ ] Firestore data is synced

**Note**: In sandbox, you may need to wait a few minutes for StoreKit to sync.

---

### Test 6: Subscription Status Persistence

**Objective**: Verify subscription status persists across app launches.

**Steps**:
1. After successful purchase, **close the app completely**
2. **Reopen the app**
3. Check subscription status

**Expected Results**:
- ✅ Subscription status is still Premium
- ✅ Premium features remain unlocked
- ✅ No need to restore purchases

**What to Check**:
- [ ] Settings still shows "Premium"
- [ ] Usage limits still show "Unlimited"
- [ ] Can still use premium features

---

### Test 7: Free Tier Limits (Negative Test)

**Objective**: Verify free tier limits are enforced for non-premium users.

**Steps**:
1. **Sign out** and create a new account (or use a free tier account)
2. Try to:
   - Create 16th recipe (should show limit error)
   - Perform 6th AI extraction (should show limit error)
   - Generate 4th AI description (should show limit error)

**Expected Results**:
- ✅ Limit errors appear at correct thresholds
- ✅ Upgrade prompts are shown
- ✅ Settings shows "Free" account type

**What to Check**:
- [ ] Recipe limit enforced at 15
- [ ] AI extraction limit enforced at 5
- [ ] AI description limit enforced at 3
- [ ] Error messages are clear and helpful

---

### Test 8: Transaction Listener

**Objective**: Verify that subscription updates are handled automatically.

**Steps**:
1. Make a purchase
2. Check Xcode console for transaction listener logs
3. Verify Firestore is updated automatically

**Expected Results**:
- ✅ Transaction listener processes purchase
- ✅ Firestore is updated without manual refresh
- ✅ No duplicate transactions

**Console Logs to Look For**:
```
✅ Subscription updated: Premium until [date]
✅ User premium status updated: true
```

---

## 🔍 Verification Checklist

After completing all tests, verify:

### Code Verification
- [ ] Product IDs match exactly in code and App Store Connect
- [ ] Subscription service initializes correctly
- [ ] Transaction listener is active
- [ ] Firestore rules allow subscription writes

### Functionality Verification
- [ ] Products load successfully
- [ ] Monthly purchase works
- [ ] Yearly purchase works
- [ ] Premium features unlock immediately
- [ ] Free tier limits enforced correctly
- [ ] Restore purchases works
- [ ] Subscription status persists

### Data Verification
- [ ] Firestore `subscriptions` collection updated correctly
- [ ] Firestore `users` collection `premiumUser` field updated
- [ ] Subscription expiration dates are correct
- [ ] Transaction IDs are stored

### UI Verification
- [ ] Premium screen displays correctly
- [ ] Settings shows correct subscription status
- [ ] Usage limits display correctly (Unlimited for premium)
- [ ] Error messages are user-friendly

---

## 🐛 Common Issues & Troubleshooting

### Issue 1: "Product Not Found" Error

**Symptoms**:
- Products don't load
- Error message: "Product not found"

**Solutions**:
1. ✅ Verify product IDs match exactly (case-sensitive)
2. ✅ Ensure subscriptions are in "Ready to Submit" status
3. ✅ Wait 24-48 hours after creating products
4. ✅ Test on real device (not Simulator)
5. ✅ Sign out of regular Apple ID on device
6. ✅ Check Xcode console for detailed error messages

---

### Issue 2: Can't Sign In with Sandbox Account

**Symptoms**:
- Purchase dialog doesn't appear
- Can't authenticate sandbox account

**Solutions**:
1. ✅ Sign out of regular Apple ID in Settings → App Store
2. ✅ Create new sandbox test account
3. ✅ Use email that doesn't have Apple ID
4. ✅ Ensure device is connected to Xcode
5. ✅ Try signing in when purchase dialog appears (not in Settings)

---

### Issue 3: Purchase Succeeds But Status Doesn't Update

**Symptoms**:
- Purchase completes
- But app still shows "Free" status
- Premium features not unlocked

**Solutions**:
1. ✅ Check Firestore rules allow subscription writes
2. ✅ Verify `updateSubscription` is called after purchase
3. ✅ Check Xcode console for errors
4. ✅ Wait a few seconds and check again (async updates)
5. ✅ Try restoring purchases
6. ✅ Check network connection

**Debug Steps**:
- Check Firestore console for subscription document
- Check Firestore console for user document `premiumUser` field
- Look for error logs in Xcode console

---

### Issue 4: Subscription Not Restoring

**Symptoms**:
- Restore purchases doesn't work
- Subscription status not restored

**Solutions**:
1. ✅ Ensure same Apple ID is used
2. ✅ Wait a few minutes for StoreKit sync
3. ✅ Check Firestore subscription document exists
4. ✅ Verify `verifyStoreKitSubscription` is working
5. ✅ Try signing out and back in

---

### Issue 5: Firestore Permission Errors

**Symptoms**:
- Purchase succeeds
- But Firestore update fails
- Error: "Missing or insufficient permissions"

**Solutions**:
1. ✅ Check Firestore rules for `subscriptions` collection
2. ✅ Verify rules allow authenticated users to write
3. ✅ Check rules for `users` collection updates
4. ✅ Review `FIRESTORE_RULES.txt` file

**Required Firestore Rules**:
```javascript
// Subscriptions collection
match /subscriptions/{userId} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId;
}

// Users collection - allow premiumUser updates
match /users/{userId} {
  allow update: if request.auth != null && 
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['premiumUser']);
}
```

---

## 📊 Testing on Different Scenarios

### Scenario 1: First-Time Purchase
- New user signs up
- Immediately purchases subscription
- Verify everything works

### Scenario 2: Existing Free User Upgrading
- User has been using free tier
- Has created some recipes
- Upgrades to premium
- Verify limits are removed

### Scenario 3: Subscription Expiration (Sandbox)
- Purchase subscription
- Wait for expiration (sandbox subscriptions expire faster)
- Verify status changes to free
- Verify limits are re-enabled

### Scenario 4: Multiple Devices
- Purchase on Device A
- Sign in on Device B
- Restore purchases
- Verify premium status syncs

---

## 🎯 Success Criteria

Your subscription testing is successful when:

1. ✅ **Products Load**: Both monthly and yearly subscriptions appear
2. ✅ **Purchase Works**: Can complete purchase flow successfully
3. ✅ **Status Updates**: Premium status updates immediately in app and Firestore
4. ✅ **Features Unlock**: All premium features are accessible
5. ✅ **Limits Removed**: Free tier limits are bypassed for premium users
6. ✅ **Restore Works**: Can restore purchases on new device/install
7. ✅ **Persistence**: Subscription status persists across app launches
8. ✅ **Free Tier**: Free tier limits are enforced correctly

---

## 📝 Testing Log Template

Use this template to track your testing:

```
Date: ___________
Tester: ___________
Device: ___________
iOS Version: ___________

Test 1: Products Load
[ ] Pass [ ] Fail
Notes: _________________________________

Test 2: Monthly Purchase
[ ] Pass [ ] Fail
Notes: _________________________________

Test 3: Yearly Purchase
[ ] Pass [ ] Fail
Notes: _________________________________

Test 4: Premium Features
[ ] Pass [ ] Fail
Notes: _________________________________

Test 5: Restore Purchases
[ ] Pass [ ] Fail
Notes: _________________________________

Test 6: Status Persistence
[ ] Pass [ ] Fail
Notes: _________________________________

Test 7: Free Tier Limits
[ ] Pass [ ] Fail
Notes: _________________________________

Issues Found:
_________________________________
_________________________________

```

---

## 🚀 Next Steps After Testing

Once all tests pass:

1. **Submit for Review**:
   - Subscriptions are reviewed with your app
   - Ensure all subscription information is accurate
   - Include subscription terms in your app

2. **Monitor After Launch**:
   - Track subscription metrics in App Store Connect
   - Monitor conversion rates
   - Watch for any issues in production

3. **User Support**:
   - Prepare support documentation
   - Know how to help users with subscription issues
   - Understand Apple's subscription management (users manage in Settings app)

---

## 📚 Additional Resources

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)

---

## ⚠️ Important Notes

1. **Sandbox vs Production**: Sandbox testing uses test accounts and doesn't charge real money
2. **Expiration**: Sandbox subscriptions may expire faster for testing
3. **Propagation**: New subscriptions take 24-48 hours to be available for testing
4. **Real Device Required**: Subscriptions cannot be tested in Simulator
5. **Apple ID**: Must sign out of regular Apple ID to use sandbox accounts
6. **Firestore**: Ensure Firestore rules allow subscription writes before testing

---

**Last Updated**: January 2026
**Version**: 1.0
