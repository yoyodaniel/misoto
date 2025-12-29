# Google Sign In - Additional Setup

After enabling Google Sign In in Firebase Console, you need to configure the URL scheme in Xcode.

## Step 1: Get Your Reversed Client ID

1. Open `GoogleService-Info.plist` in Xcode (it's in your project)
2. Find the key `REVERSED_CLIENT_ID`
3. Copy the value (it looks like: `com.googleusercontent.apps.123456789-abcdefg`)

## Step 2: Add URL Scheme in Xcode

1. In Xcode, select your **project** (blue icon at top)
2. Select the **"Misoto"** target
3. Click the **"Info"** tab
4. Expand **"URL Types"** section
5. Click the **"+"** button to add a new URL Type
6. Fill in:
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Paste the `REVERSED_CLIENT_ID` value you copied
7. Click outside to save

## Step 3: Verify

Your URL Types should now show:
- **Identifier**: GoogleSignIn
- **URL Schemes**: com.googleusercontent.apps.XXXXX-XXXXX

## That's it!

Now Google Sign In should work properly. The URL scheme allows Google to redirect back to your app after authentication.

