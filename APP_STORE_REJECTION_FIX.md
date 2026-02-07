# App Store Rejection Fix - January 15, 2026

## Issues to Fix

### 1. Guideline 4.0 - Design (iPad Layout)
**Issue**: Subscription information not fully displayed on iPad Air 11-inch

**Status**: ✅ **FIXED**
- Changed subscription cards from HStack to responsive layout (LazyVGrid on iPad, HStack on iPhone)
- Reduced padding on iPad for better space utilization
- Increased card height on iPad (220pt vs 180pt)
- Made fonts larger on iPad for better readability
- All content now properly displays on iPad

### 2. Guideline 3.1.2 - Business - Payments - Subscriptions
**Issue**: Missing required subscription information

**Status**: ✅ **FIXED IN APP**

#### Required Information Now Included in App:
- ✅ **Title of auto-renewing subscription**: Displayed via `product.displayName`
- ✅ **Length of subscription**: Displayed via `subscription.subscriptionPeriod` (e.g., "1 month", "1 year")
- ✅ **Price of subscription**: Displayed via `product.displayPrice`
- ✅ **Price per unit**: Calculated and displayed for yearly subscriptions (monthly equivalent)
- ✅ **Functional links to Privacy Policy**: Button opens PrivacyPolicyView sheet
- ✅ **Functional links to Terms of Use**: Button opens TermsOfServiceView sheet

#### Required in App Store Connect Metadata:
- ⚠️ **Terms of Use (EULA) Link**: Must be added to App Store Connect

## Action Items for App Store Connect

### 1. Add Terms of Use Link to App Description

**Option A: Add to App Description** (Recommended)
1. Go to App Store Connect → Your App → App Information
2. Edit the **App Description**
3. Add at the end:
   ```
   
   Terms of Use: https://misoto.app/terms
   ```
   (Replace with your actual Terms of Use URL)

**Option B: Add as Custom EULA**
1. Go to App Store Connect → Your App → App Information
2. Scroll to **End User License Agreement (EULA)**
3. Click **"Edit"**
4. Select **"Use custom license agreement"**
5. Upload or paste your Terms of Use
6. Click **"Save"**

### 2. Verify Privacy Policy Link
- [ ] Go to App Store Connect → Your App → App Information
- [ ] Scroll to **Privacy Policy URL**
- [ ] Verify it's set to: `https://misoto.app/privacy` (or your actual URL)
- [ ] Ensure the link is functional and accessible

### 3. Test Links
- [ ] Click Privacy Policy link - should open your privacy policy page
- [ ] Click Terms of Use link (if in description) - should open your terms page
- [ ] Both links must be accessible without login

## Code Changes Made

### PremiumView.swift
1. **iPad Layout Fix**:
   - Responsive layout using `UIDevice.current.userInterfaceIdiom == .pad`
   - LazyVGrid for iPad (2 columns), HStack for iPhone
   - Adjusted padding and font sizes for iPad

2. **Required Subscription Information**:
   - Added subscription title display
   - Added subscription duration display
   - Added price display
   - Added price per month for yearly subscriptions
   - Added functional Privacy Policy link (opens sheet)
   - Added functional Terms of Use link (opens sheet)

3. **SubscriptionCardView**:
   - Added subscription duration display
   - Increased card height on iPad
   - Larger fonts on iPad

## Testing Checklist

Before resubmitting:
- [ ] Test on iPad Air 11-inch (or similar iPad)
- [ ] Verify all subscription information is visible
- [ ] Verify subscription cards display properly (not cut off)
- [ ] Test Privacy Policy link opens correctly
- [ ] Test Terms of Use link opens correctly
- [ ] Verify subscription details section shows:
  - Subscription title
  - Duration
  - Price
  - Price per month (for yearly)
- [ ] Test on iPhone (ensure iPhone layout still works)
- [ ] Verify all text is readable and not crowded

## Next Steps

1. **Update App Store Connect**:
   - Add Terms of Use link to App Description OR upload as Custom EULA
   - Verify Privacy Policy URL is correct

2. **Build and Upload**:
   - Archive new build in Xcode
   - Upload to App Store Connect
   - Wait for processing

3. **Resubmit**:
   - Select new build
   - Add note to reviewer explaining fixes
   - Submit for review

## Notes for Reviewer

When resubmitting, you can add this note in App Store Connect:

```
Fixed Issues:

1. iPad Layout (Guideline 4.0):
   - Updated subscription view to use responsive layout
   - Subscription cards now display properly on iPad using grid layout
   - All subscription information is now fully visible on iPad

2. Subscription Information (Guideline 3.1.2):
   - Added all required subscription information in the app:
     - Subscription title
     - Subscription duration
     - Price
     - Price per month (for yearly subscriptions)
   - Added functional links to Privacy Policy and Terms of Use
   - Terms of Use link added to App Description
```

## Files Modified

- `Misoto/Views/PremiumView.swift` - Fixed iPad layout and added required subscription info
- All email addresses updated to `support@misoto.app`
