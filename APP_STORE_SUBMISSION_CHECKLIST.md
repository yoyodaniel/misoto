# App Store Submission Checklist - Misoto

**Version**: 1.0  
**Build**: 1  
**Bundle ID**: com.miniadd.Misoto  
**Date**: December 2025

---

## ✅ Phase 1: Code & Technical Requirements

### Build Configuration
- [ ] **Version Number**: Set to `1.0` in Xcode (MARKETING_VERSION)
- [ ] **Build Number**: Set to `1` in Xcode (CURRENT_PROJECT_VERSION)
- [ ] **Bundle Identifier**: `com.miniadd.Misoto` (verify in Xcode)
- [ ] **Deployment Target**: iOS 18.6+ (verify minimum iOS version)
- [ ] **Code Signing**: Automatic signing enabled with correct Team ID
- [ ] **Provisioning Profile**: Valid and up to date

### Code Quality
- [x] ✅ Memory leaks fixed (all tasks, timers, listeners cleaned up)
- [x] ✅ No force unwraps (safe optional binding used)
- [x] ✅ Error handling implemented throughout
- [x] ✅ Retain cycles prevented (weak self used)
- [ ] **Final Build**: Archive build succeeds without warnings
- [ ] **Linter**: No critical warnings or errors
- [ ] ⚠️ **Security Note**: OPENAI_API_KEY is in Info.plist (visible in app bundle)
  - **Current**: API key is readable from app bundle (common practice)
  - **Recommendation**: Move to backend service in future for better security
  - **Action**: Ensure OpenAI API key has rate limits and usage restrictions

### App Configuration
- [x] ✅ App Icon configured (AppIcon.appiconset)
- [x] ✅ Launch Screen configured
- [x] ✅ Privacy permissions configured (Camera, Photo Library)
- [x] ✅ Entitlements configured (Sign in with Apple, Google Sign In)
- [ ] **App Category**: Food & Drink (verify in Info.plist)

### Firebase & Backend
- [x] ✅ Firebase project configured
- [x] ✅ Firestore database created and rules deployed
- [x] ✅ Firestore indexes created (recipeShares collection)
- [x] ✅ Google Sign In configured
- [x] ✅ Apple Sign In configured
- [ ] **Test**: Verify all Firebase services work in production mode
- [ ] **Backup**: Export Firestore rules and indexes

---

## ✅ Phase 2: App Store Connect Setup

### App Information
- [ ] **App Name**: "Misoto" (30 characters max)
- [ ] **Subtitle**: Create catchy subtitle (30 characters max)
- [ ] **Primary Language**: English (U.S.)
- [ ] **Category**: Food & Drink (Primary)
- [ ] **Secondary Category**: (Optional) Lifestyle or Social Networking
- [ ] **Content Rights**: Confirm you have rights to all content

### App Description & Metadata
- [ ] **Description**: Write compelling description (up to 4000 characters)
  - Use `APP_STORE_PROMPT.md` as reference
  - Highlight key features: AI extraction, recipe sharing, 20 languages
- [ ] **Keywords**: Add relevant keywords (100 characters max, comma-separated)
  - Example: "recipe, cooking, food, AI, photo, sharing, community"
- [ ] **Promotional Text**: Optional (170 characters max)
- [ ] **Support URL**: Your website or support page
- [ ] **Marketing URL**: Optional

### Screenshots (Required)
- [ ] **iPhone 6.7" Display** (iPhone 14 Pro Max, 15 Pro Max):
  - [ ] At least 1 screenshot (up to 10)
  - [ ] Recommended: 3-5 screenshots showing key features
- [ ] **iPhone 6.5" Display** (iPhone 11 Pro Max, XS Max):
  - [ ] At least 1 screenshot (up to 10)
- [ ] **iPhone 5.5" Display** (iPhone 8 Plus):
  - [ ] At least 1 screenshot (up to 10)
- [ ] **iPad Pro 12.9"** (if iPad supported):
  - [ ] At least 1 screenshot (up to 10)

**Screenshot Guidelines**:
- Show key features: Recipe creation, AI extraction, Explore page, Profile
- Use real content (not placeholders)
- No text overlays or callouts
- Must be actual app screenshots (not mockups)

### App Preview Video (Optional but Recommended)
- [ ] Create 15-30 second video showing app in action
- [ ] Upload for iPhone 6.7" display
- [ ] Show key features: Recipe creation, AI extraction, sharing

### App Icon
- [x] ✅ App icon created (1024x1024 pixels)
- [ ] **Upload**: Upload to App Store Connect
- [ ] **Verify**: Icon displays correctly (no transparency, proper padding)

### Age Rating
- [ ] **Age Rating**: Complete questionnaire
  - Suggested: 4+ (no objectionable content)
  - Verify based on your content

### Pricing & Availability
- [ ] **Price**: Free (with in-app purchases)
- [ ] **Availability**: Select countries (or "All Countries")
- [ ] **Subscription Pricing**: Configure in App Store Connect
  - Monthly: $4.99
  - Yearly: $49.99

---

## ✅ Phase 3: In-App Purchases (Subscriptions)

### Subscription Setup
- [ ] **Subscription Group**: "Misoto Premium" created
- [ ] **Monthly Subscription**:
  - [ ] Product ID: `com.misoto.premium.monthly` (must match code)
  - [ ] Price: $4.99 USD
  - [ ] Display Name: "Premium Monthly"
  - [ ] Description: Clear description of benefits
  - [ ] Status: "Ready to Submit"
- [ ] **Yearly Subscription**:
  - [ ] Product ID: `com.misoto.premium.yearly` (must match code)
  - [ ] Price: $49.99 USD
  - [ ] Display Name: "Premium Yearly"
  - [ ] Description: Clear description + savings mention
  - [ ] Status: "Ready to Submit"

### Subscription Testing
- [ ] **Sandbox Accounts**: Create 2-3 test accounts
- [ ] **Test Purchase Flow**: 
  - [ ] Monthly subscription purchase works
  - [ ] Yearly subscription purchase works
  - [ ] Subscription restore works
  - [ ] Free tier limits enforced correctly
  - [ ] Premium features unlock correctly

### Subscription Localization (Optional)
- [ ] Add subscription descriptions in major languages
- [ ] At minimum: English (required)

---

## ✅ Phase 4: Legal & Compliance

### Privacy Policy
- [x] ✅ Privacy Policy created and updated
- [x] ✅ Contact email: support@misoto.app
- [x] ✅ Minimum age: 16
- [ ] **URL**: Host Privacy Policy on your website
- [ ] **Link**: Add Privacy Policy URL to App Store Connect
- [ ] **In-App**: Privacy Policy accessible in app (Settings)

### Terms of Service
- [x] ✅ Terms of Service created and updated
- [x] ✅ Contact email: support@misoto.app
- [x] ✅ Minimum age: 16
- [ ] **URL**: Host Terms of Service on your website
- [ ] **Link**: Add Terms of Service URL to App Store Connect
- [ ] **In-App**: Terms accessible in app (Settings)

### Data Collection Disclosure
- [ ] **App Privacy**: Complete App Privacy questionnaire in App Store Connect
  - [ ] Data types collected (User ID, Email, Recipes, Images)
  - [ ] Data usage (App functionality, Analytics)
  - [ ] Data linked to user (Yes)
  - [ ] Data used for tracking (No, unless using analytics)
  - [ ] Third-party sharing (Firebase, OpenAI)

### GDPR Compliance
- [x] ✅ Privacy Policy includes GDPR rights
- [x] ✅ Data deletion process documented
- [ ] **Verify**: All required GDPR elements present

---

## ✅ Phase 5: Testing & Quality Assurance

### Functional Testing
- [ ] **Authentication**:
  - [ ] Google Sign In works
  - [ ] Apple Sign In works
  - [ ] Sign out works
- [ ] **Recipe Creation**:
  - [ ] Manual recipe entry works
  - [ ] AI photo extraction works (test with limit)
  - [ ] AI link extraction works (test with limit)
  - [ ] AI website extraction works (test with limit)
  - [ ] Recipe editing works
  - [ ] Recipe deletion works
- [ ] **Recipe Sharing**:
  - [ ] Public recipes visible on explore page
  - [ ] Private recipes hidden correctly
  - [ ] Recipe sharing with users works
  - [ ] Shared recipes accessible to recipients
- [ ] **Social Features**:
  - [ ] Follow/unfollow works
  - [ ] Favorite/like works
  - [ ] User profiles display correctly
- [ ] **Subscriptions**:
  - [ ] Free tier limits enforced (15 recipes, 5 AI extractions)
  - [ ] Premium purchase unlocks features
  - [ ] Subscription restore works
  - [ ] Premium status updates correctly
- [ ] **Localization**:
  - [ ] App displays in device language
  - [ ] Language switching works
  - [ ] All UI elements translated (major languages)

### Performance Testing
- [ ] **Memory**: Profile with Instruments - no memory leaks
- [ ] **Network**: Test with slow network connection
- [ ] **Offline**: Test offline behavior (if applicable)
- [ ] **Image Loading**: Verify images load and cache correctly
- [ ] **Large Data**: Test with many recipes loaded

### Device Testing
- [ ] **iPhone**: Test on physical iPhone (latest iOS)
- [ ] **iPad**: Test on iPad if supported
- [ ] **Different Screen Sizes**: Test on various iPhone sizes
- [ ] **iOS Versions**: Test on minimum iOS version (18.6)

### Edge Cases
- [ ] **Empty States**: Test with no recipes, no followers, etc.
- [ ] **Error Handling**: Test network errors, permission denials
- [ ] **Limits**: Test hitting free tier limits
- [ ] **Large Images**: Test with high-resolution images
- [ ] **Long Text**: Test with very long recipe titles/descriptions

---

## ✅ Phase 6: Final Build & Upload

### Archive Build
- [ ] **Clean Build**: Product → Clean Build Folder (⌘+Shift+K)
- [ ] **Archive**: Product → Archive
- [ ] **Verify**: Archive succeeds without errors
- [ ] **Validate**: Validate archive in Organizer
  - [ ] No code signing issues
  - [ ] No missing icons
  - [ ] No missing entitlements

### Upload to App Store Connect
- [ ] **Distribute**: Distribute App in Organizer
- [ ] **Method**: App Store Connect
- [ ] **Upload**: Upload build to App Store Connect
- [ ] **Wait**: Wait for processing (usually 10-30 minutes)
- [ ] **Verify**: Build appears in App Store Connect → TestFlight → Builds

### TestFlight (Optional but Recommended)
- [ ] **Internal Testing**: Add internal testers
- [ ] **External Testing**: Set up external testing group (optional)
- [ ] **Test**: Install and test via TestFlight
- [ ] **Feedback**: Collect feedback from testers

---

## ✅ Phase 7: App Store Connect Submission

### Version Information
- [ ] **Version**: 1.0
- [ ] **Build**: Select uploaded build
- [ ] **What's New**: Write release notes (up to 4000 characters)
  - First version: "Initial release of Misoto - Share and discover amazing recipes"

### App Review Information
- [ ] **Contact Information**: 
  - [ ] First Name, Last Name
  - [ ] Phone Number
  - [ ] Email: support@misoto.app
- [ ] **Demo Account**: 
  - [ ] Create test account for reviewers
  - [ ] Provide credentials (if login required)
  - [ ] Note: App allows sign in, so may not need demo account
- [ ] **Notes**: Add any notes for reviewers
  - Mention: "App uses Firebase for backend, OpenAI for AI features"
  - Mention: "Subscriptions available via in-app purchase"

### Export Compliance
- [ ] **Export Compliance**: Answer questions
  - Uses encryption: Yes (HTTPS, Firebase)
  - Uses standard encryption: Yes
  - No special export restrictions

### Advertising Identifier (IDFA)
- [ ] **Advertising**: Select "No" (unless using ads)
- [ ] **Tracking**: Select "No" (unless tracking users)

### Content Rights
- [ ] **Content Rights**: Confirm you have rights to all content
- [ ] **Third-Party Content**: List any third-party content/licenses

---

## ✅ Phase 8: Pre-Submission Verification

### Final Checks
- [ ] **All Screenshots**: Uploaded and correct
- [ ] **App Description**: Complete and accurate
- [ ] **Keywords**: Relevant and optimized
- [ ] **Privacy Policy**: URL accessible and up to date
- [ ] **Terms of Service**: URL accessible and up to date
- [ ] **Subscriptions**: Configured and ready
- [ ] **Build**: Uploaded and processing complete
- [ ] **TestFlight**: Tested (if using)

### Code Verification
- [ ] **Product IDs**: Match exactly in code and App Store Connect
- [ ] **Bundle ID**: Matches App Store Connect
- [ ] **Version**: Matches App Store Connect
- [ ] **Firestore Rules**: Deployed to production
- [ ] **Firestore Indexes**: Created and building

### Legal Verification
- [ ] **Privacy Policy**: Accessible, includes all required info
- [ ] **Terms of Service**: Accessible, includes subscription terms
- [ ] **Contact Email**: support@misoto.app (consistent everywhere)
- [ ] **Age Rating**: Appropriate for content

---

## ✅ Phase 9: Submit for Review

### Final Submission
- [ ] **Review All Information**: Double-check everything
- [ ] **Submit for Review**: Click "Submit for Review" button
- [ ] **Confirmation**: Note submission date and time
- [ ] **Status**: Monitor status in App Store Connect

### After Submission
- [ ] **Wait for Review**: Usually 24-48 hours
- [ ] **Monitor**: Check App Store Connect for status updates
- [ ] **Respond**: If rejected, address feedback and resubmit

---

## 📋 Quick Reference

### Key Information
- **App Name**: Misoto
- **Bundle ID**: com.miniadd.Misoto
- **Version**: 1.0
- **Build**: 1
- **Category**: Food & Drink
- **Price**: Free (with in-app purchases)
- **Contact**: support@misoto.app
- **Minimum Age**: 16

### Product IDs (Must Match Exactly)
- Monthly: `com.misoto.premium.monthly`
- Yearly: `com.misoto.premium.yearly`

### Required URLs
- Privacy Policy: [Your URL]
- Terms of Service: [Your URL]
- Support URL: [Your URL]

### Testing Accounts
- Sandbox Testers: Create in App Store Connect
- TestFlight: Optional but recommended

---

## 🚨 Common Issues & Solutions

### Build Upload Fails
- **Issue**: Code signing errors
- **Solution**: Verify provisioning profile and certificates in Xcode

### Subscriptions Not Found
- **Issue**: Product IDs don't match
- **Solution**: Verify Product IDs match exactly (case-sensitive)

### Screenshots Rejected
- **Issue**: Screenshots don't match app
- **Solution**: Use actual app screenshots, not mockups

### Privacy Policy Required
- **Issue**: App Store requires Privacy Policy URL
- **Solution**: Host Privacy Policy on your website and add URL

### Review Rejection
- **Issue**: App crashes or doesn't work
- **Solution**: Test thoroughly before submission, fix issues

---

## ✅ Final Checklist Before Clicking "Submit"

- [ ] All screenshots uploaded
- [ ] App description complete
- [ ] Keywords added
- [ ] Privacy Policy URL added and accessible
- [ ] Terms of Service URL added and accessible
- [ ] Subscriptions configured and ready
- [ ] Build uploaded and processing complete
- [ ] TestFlight tested (if using)
- [ ] All information reviewed and accurate
- [ ] Contact information correct
- [ ] Demo account provided (if needed)

---

**Good luck with your App Store submission! 🚀**
