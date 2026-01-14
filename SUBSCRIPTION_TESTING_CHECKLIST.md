# Subscription Testing Quick Checklist

Quick reference checklist for testing subscriptions.

## ✅ Pre-Testing Setup

### App Store Connect
- [ ] Subscription group created: "Misoto Premium"
- [ ] Monthly subscription created: `com.misoto.premium.monthly`
- [ ] Yearly subscription created: `com.misoto.premium.yearly`
- [ ] Both subscriptions in "Ready to Submit" status
- [ ] Waited 24-48 hours for propagation
- [ ] Sandbox test accounts created (2-3 accounts)

### Device Setup
- [ ] Signed out of regular Apple ID (Settings → App Store)
- [ ] Device connected to Xcode
- [ ] App built and running from Xcode (not TestFlight)

### Firestore Rules
- [ ] `subscriptions` collection rules allow authenticated writes
- [ ] `users` collection allows `premiumUser` field updates
- [ ] Rules deployed to Firestore

---

## 🧪 Testing Checklist

### Basic Functionality
- [ ] Products load successfully (Monthly & Yearly)
- [ ] Prices display correctly
- [ ] No "Product not found" errors

### Purchase Flow
- [ ] Monthly purchase completes successfully
- [ ] Yearly purchase completes successfully
- [ ] Sandbox account sign-in works
- [ ] Purchase dialog appears correctly

### Data Verification
- [ ] Firestore `subscriptions/{userId}` document created
- [ ] `tier` = "premium"
- [ ] `expiresAt` = correct future date
- [ ] `productID` = correct product ID
- [ ] `isActive` = true
- [ ] Firestore `users/{userId}` document updated
- [ ] `premiumUser` = true

### App Verification
- [ ] Settings shows "Premium" account type
- [ ] Usage limits show "Unlimited" or -1
- [ ] Can create more than 15 recipes
- [ ] Can perform more than 5 AI extractions
- [ ] No upgrade prompts appear

### Additional Tests
- [ ] Restore purchases works
- [ ] Subscription status persists after app restart
- [ ] Free tier limits enforced for non-premium users
- [ ] Transaction listener processes purchases

---

## 🐛 Common Issues Quick Fix

| Issue | Quick Fix |
|-------|-----------|
| Products don't load | Check product IDs match exactly, wait 24-48h, verify "Ready to Submit" status |
| Can't sign in sandbox | Sign out of regular Apple ID, create new sandbox account |
| Purchase succeeds but no update | Check Firestore rules, check console logs, wait a few seconds |
| Status doesn't persist | Check `loadSubscriptionStatus()` is called, verify Firestore data |

---

## 📊 Success Criteria

All tests pass when:
- ✅ Products load
- ✅ Purchase completes
- ✅ Premium status updates
- ✅ Features unlock
- ✅ Limits removed
- ✅ Restore works
- ✅ Status persists

---

## 📝 Notes

Date: ___________
Tester: ___________
Device: ___________

Issues: 
_________________________________
_________________________________
