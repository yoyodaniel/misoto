# App Store EULA & Subscription Requirements Checklist

## ✅ What's Already Implemented in the App (Binary)

### Required Subscription Information in App UI:
- ✅ **Subscription Title**: Displayed via `product.displayName` in `SubscriptionCardView`
- ✅ **Subscription Length**: Displayed via `subscriptionPeriod` in `SubscriptionCardView` (e.g., "1 month", "1 year")
- ✅ **Price**: Displayed via `product.displayPrice` in `SubscriptionCardView`
- ✅ **Auto-Renewal Notice**: Text shown in footer: "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period."
- ✅ **Cancellation Info**: Button to "Manage subscriptions in Settings" that opens iOS Settings
- ✅ **Privacy Policy Link**: Functional button in `footerLinksSection` that opens `PrivacyPolicyView` sheet
- ✅ **Terms of Use (EULA) Link**: Functional button in `footerLinksSection` that opens `TermsOfServiceView` sheet

**Location**: All required information is visible in `PremiumView.swift` before users can subscribe.

---

## ⚠️ What Still Needs to Be Done in App Store Connect

### 1. Privacy Policy Link
- **Action Required**: Add your Privacy Policy URL in App Store Connect
- **Location**: App Store Connect → Your App → App Information → Privacy Policy URL
- **URL Format**: `https://misoto.app/privacy-policy` (or wherever you host it)
- **Status**: ⚠️ **NOT YET DONE** - You need to add this

### 2. Terms of Use (EULA) Link - Using Apple's Standard EULA ✅
- **Action Required**: 
  1. **In App Store Connect**: 
     - Go to App Store Connect → Your App → App Information → License Agreement
     - Ensure "Standard Apple EULA" is selected (this is the default)
     - No custom text needed
  
  2. **In App Description** (REQUIRED):
     - Add a functional link to Apple's standard EULA in your App Description
     - Apple's standard EULA link: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
     - Or reference: "This app uses Apple's Standard End User License Agreement (EULA). For more information, visit: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

- **Important Note**: 
  - Even though you're using Apple's standard EULA, you MUST include a link to it in your App Description
  - This is what Apple reviewers check for - they need to see the EULA link in metadata
  - The link must be functional and accessible

---

## 📋 Using Apple's Standard EULA

### ✅ What Apple's Standard EULA Covers:

Apple's Standard EULA is a basic license agreement that covers:
- Basic licensing terms between you and the user
- Intellectual property rights
- Usage restrictions
- Limitation of liability (basic)
- Termination rights

### ⚠️ Important for Subscription Apps:

Since you're using Apple's Standard EULA, make sure:
- ✅ All subscription-specific information (pricing, duration, auto-renewal) is clearly shown in your **app UI** (already done)
- ✅ Subscription details are also mentioned in your **App Description** (recommended)
- ✅ The app UI includes auto-renewal notice and cancellation instructions (already done)
- ✅ Privacy Policy link is functional (needs to be added in App Store Connect)

**Note**: Apple's Standard EULA doesn't include subscription-specific terms, but that's okay because:
- All subscription details are required to be shown in the app UI (which you've done)
- The subscription information in your app UI satisfies Apple's requirements
- Apple's standard EULA covers the basic licensing relationship

---

## 🎯 Action Items Summary

### Immediate Actions Required:

1. **Add Privacy Policy URL in App Store Connect**
   - Location: App Store Connect → App Information → Privacy Policy URL
   - Use: `https://misoto.app/privacy-policy` (or your actual URL)
   - Status: ⚠️ **NOT YET DONE**

2. **Verify Standard EULA is Selected**
   - Location: App Store Connect → App Information → License Agreement
   - Ensure "Standard Apple EULA" is selected (this is the default)
   - Status: ✅ Should already be set

3. **Add EULA Link in App Description** (REQUIRED)
   - In your App Description field, add a link to Apple's Standard EULA
   - Use: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
   - Status: ⚠️ **NOT YET DONE** - This is critical!

4. **Verify Links Are Functional**
   - Test that Privacy Policy link works
   - Test that Apple's Standard EULA link works
   - Ensure links are accessible without login

---

## 📝 App Description Template

Add this to your App Description in App Store Connect:

```
[Your existing app description]

---

Privacy Policy: https://misoto.app/privacy-policy
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

Subscriptions:
- Premium Monthly: $4.99/month
- Premium Yearly: $49.99/year
- Auto-renewable subscriptions
- Cancel anytime in Settings
```

**Important**: The EULA link must be functional and clickable. You can format it as:
- Plain URL: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Or as text: "This app uses Apple's Standard End User License Agreement. View terms: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

---

## ✅ Final Checklist Before Resubmission

- [ ] Privacy Policy URL added in App Store Connect (App Information → Privacy Policy URL)
- [ ] Standard Apple EULA selected in App Store Connect (should be default)
- [ ] EULA link added in App Description (link to Apple's Standard EULA)
- [ ] All links are functional and accessible
- [ ] App binary includes all required subscription information (✅ Already done)
- [ ] App binary includes Privacy Policy and Terms links (✅ Already done)
- [ ] Auto-renewal notice visible in app (✅ Already done)

---

## 🎯 Summary

**You're using Apple's Standard EULA** - which is perfectly fine! Just make sure to:

1. ✅ **Verify** "Standard Apple EULA" is selected in App Store Connect (should be default)
2. ⚠️ **Add** Privacy Policy URL in App Store Connect → App Information → Privacy Policy URL
3. ⚠️ **Add** EULA link in your App Description: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

The app binary already has all required subscription information, so once you complete the App Store Connect metadata (Privacy Policy URL + EULA link in description), you should be good to resubmit!
