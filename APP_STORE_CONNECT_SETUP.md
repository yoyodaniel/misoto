# App Store Connect Setup Guide - Subscription Implementation

This guide explains how to set up subscriptions in App Store Connect for the Misoto app.

## Overview

Misoto uses a freemium model with:
- **Free Tier**: Limited features (5 recipes/month, 3 AI descriptions/month, 2 AI image extractions/month)
- **Premium Subscription**: Unlimited features ($4.99/month or $49.99/year)

## Step-by-Step Setup Instructions

### Step 1: Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Select your app (Misoto)

### Step 2: Create In-App Purchase Products

1. Navigate to **Features** → **In-App Purchases**
2. Click the **+** button to create a new in-app purchase
3. Select **Auto-Renewable Subscription**
4. Click **Create**

### Step 3: Create Subscription Group

1. If this is your first subscription, create a **Subscription Group**:
   - Click **Create Subscription Group**
   - Name it: **"Misoto Premium"**
   - Click **Create**

### Step 4: Add Monthly Subscription

1. Click **Create Subscription** in your subscription group
2. Fill in the details:
   - **Reference Name**: `Misoto Premium Monthly`
   - **Product ID**: `com.misoto.premium.monthly` ⚠️ **IMPORTANT**: Must match the product ID in `SubscriptionService.swift`
   - **Subscription Duration**: `1 Month`
   - **Price**: Select `$4.99 USD` (or your local equivalent)
   - **Subscription Display Name**: `Premium Monthly`
   - **Description**: `Unlimited recipe creation, AI descriptions, and image extractions. Cancel anytime.`

3. Add **Subscription Localizations**:
   - Click **Add Localization**
   - Select **English (U.S.)**
   - **Display Name**: `Premium Monthly`
   - **Description**: `Unlock unlimited recipes, AI-powered descriptions, and image extractions. Cancel anytime.`

4. Click **Save**

### Step 5: Add Yearly Subscription

1. Click **Create Subscription** again in the same subscription group
2. Fill in the details:
   - **Reference Name**: `Misoto Premium Yearly`
   - **Product ID**: `com.misoto.premium.yearly` ⚠️ **IMPORTANT**: Must match the product ID in `SubscriptionService.swift`
   - **Subscription Duration**: `1 Year`
   - **Price**: Select `$49.99 USD` (or your local equivalent - this gives ~17% discount vs monthly)
   - **Subscription Display Name**: `Premium Yearly`
   - **Description**: `Unlimited recipe creation, AI descriptions, and image extractions. Save 17% compared to monthly billing. Cancel anytime.`

3. Add **Subscription Localizations**:
   - Click **Add Localization**
   - Select **English (U.S.)**
   - **Display Name**: `Premium Yearly`
   - **Description**: `Unlock unlimited recipes, AI-powered descriptions, and image extractions. Save 17% compared to monthly billing. Cancel anytime.`

4. Click **Save**

### Step 6: Review and Submit

1. Ensure both subscriptions are in **"Ready to Submit"** status
2. Review all details (product IDs, prices, descriptions)
3. Click **Submit for Review** (subscriptions are reviewed with your app submission)

### Step 7: Test in Sandbox

Before submitting to the App Store:

1. Create **Sandbox Test Accounts**:
   - Go to **Users and Access** → **Sandbox Testers**
   - Click **+** to create test accounts
   - Create at least 2-3 test accounts for testing

2. Test on device:
   - Sign out of your Apple ID on your test device
   - Run the app from Xcode
   - When prompted, sign in with a sandbox tester account
   - Test subscription purchase flow

## Product IDs Configuration

**IMPORTANT**: The product IDs in `SubscriptionService.swift` must exactly match the Product IDs in App Store Connect:

```swift
// In SubscriptionService.swift
static let premiumMonthlyProductID = "com.misoto.premium.monthly"
static let premiumYearlyProductID = "com.misoto.premium.yearly"
```

## Pricing Recommendations

- **Monthly**: $4.99 USD (standard pricing)
- **Yearly**: $49.99 USD (17% discount = $59.88/year if paid monthly)

### Pricing Strategy

- Yearly subscription should be ~17% cheaper than 12 months of monthly (industry standard)
- Consider regional pricing adjustments for international markets
- Apple handles currency conversion automatically

## Subscription Terms

### Free Trial (Optional)

You can add a free trial period:
1. In App Store Connect, set **Free Trial Period** to `7 days` or `1 month`
2. This is optional but recommended for conversion

### Promotional Offers (Optional)

You can create promotional offers for:
- New users (introductory pricing)
- Lapsed subscribers (win-back offers)

Set these up later after launch.

## Testing Checklist

Before submitting to App Store:

- [ ] Both product IDs match exactly in code and App Store Connect
- [ ] Subscription prices are set correctly
- [ ] Subscription descriptions are clear and accurate
- [ ] Test subscription purchase flow in Sandbox
- [ ] Test subscription restore flow
- [ ] Test subscription cancellation flow (in Settings app)
- [ ] Verify subscription status updates correctly
- [ ] Test free tier limits are enforced
- [ ] Test premium features are unlocked

## App Review Guidelines

Apple will review:
1. **Subscription Value**: Ensure Premium features provide clear value
2. **Pricing**: Reasonable pricing for the features provided
3. **Terms**: Clear subscription terms and cancellation info
4. **Functionality**: Subscriptions work as described

### Required Information in App

Make sure your app includes:
- Clear explanation of what Premium includes
- Pricing information
- Link to Terms of Service (subscription terms)
- Link to Privacy Policy
- Easy way to manage/cancel subscription (via Settings app)

## Troubleshooting

### Product IDs Not Found

- **Issue**: StoreKit returns "product not found"
- **Solution**: 
  1. Verify product IDs match exactly (case-sensitive)
  2. Ensure subscriptions are in "Ready to Submit" status
  3. Wait 24 hours after creating products (Apple propagation delay)
  4. Use Sandbox environment for testing

### Sandbox Testing Issues

- **Issue**: Can't sign in with Sandbox account
- **Solution**: 
  1. Sign out of regular Apple ID on device
  2. Create new Sandbox tester account
  3. Sign in with Sandbox account when prompted
  4. Use Sandbox environment (automatic in TestFlight/Xcode)

### Subscription Not Updating

- **Issue**: Purchase successful but subscription status not updating
- **Solution**:
  1. Check `SubscriptionService.loadSubscriptionStatus()` is called after purchase
  2. Verify Firestore rules allow subscription updates
  3. Check transaction verification is working
  4. Ensure `updateSubscription` is called after purchase

## Post-Launch

After launch:
1. Monitor subscription metrics in App Store Connect
2. Track conversion rates (free to premium)
3. Monitor churn rates
4. Consider promotional offers for user acquisition
5. Review and optimize pricing based on data

## Additional Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)

## Support

If you encounter issues:
1. Check Apple's App Store Connect status page
2. Review StoreKit 2 documentation
3. Test with Sandbox accounts first
4. Contact Apple Developer Support if needed

