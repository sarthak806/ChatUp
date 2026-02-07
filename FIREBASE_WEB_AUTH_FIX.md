# Firebase Google Sign-In Web Configuration Fix

## Issue
You're getting "Auth Error: Error" when trying to sign in with Google on the web platform.

## Root Causes
1. **OAuth Consent Screen not configured** in Google Cloud Console
2. **Authorized JavaScript Origins not added** to Firebase Console
3. **Web Client ID not properly linked** to Flutter Firebase config

## Solution Steps

### Step 1: Configure OAuth Consent Screen
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **chatrealnotfake**
3. Go to **APIs & Services** → **OAuth consent screen**
4. Select **External** as the user type and click **Create**
5. Fill in:
   - **App name**: ChatUp
   - **User support email**: Your email
   - **Developer contact info**: Your email
6. Click **Save and Continue**
7. Skip **Scopes** and click **Save and Continue**
8. Click **Save and Continue** again on the test users page
9. Go back to the **OAuth consent screen** tab and verify it shows "In production" or "Testing"

### Step 2: Create/Update Web OAuth 2.0 Client ID
1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Choose **Web application**
4. Name it: **ChatUp Web Client**
5. Under **Authorized JavaScript origins**, add:
   - `http://localhost:5000` (your current dev URL)
   - `http://localhost:5000/` (with trailing slash)
   - `http://127.0.0.1:5000`
   - `http://127.0.0.1:5000/`
   - **Later**: Your production domain when deployed
6. Leave **Authorized redirect URIs** empty
7. Click **Create**
8. Copy the **Client ID**

### Step 3: Update Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **chatrealnotfake** project
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google**
5. Make sure it's **Enabled**
6. Under **Public-facing name**: Enter "ChatUp"
7. Click **Save**
8. In the same section, look for **Authorized domains**
9. Add:
   - `localhost` (this should already be there)
   - `127.0.0.1`
   - `chatrealnotfake.firebaseapp.com` (your Firebase domain)

### Step 4: Update web/index.html
Replace the Google Sign-In Client ID with the new one from Step 2:

```html
<meta name="google-signin-client_id" content="YOUR_NEW_CLIENT_ID.apps.googleusercontent.com">
```

### Step 5: Test the Fix
1. Stop your Flutter web app (`Ctrl+C` in terminal)
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. Run: `flutter run -d chrome --web-port=5000`
5. Click "Sign in with Google" and test

## If Still Getting Errors

### Check Browser Console
1. Press **F12** in your browser to open Developer Tools
2. Go to **Console** tab
3. Look for error messages that will give you more details

### Common Errors and Fixes

**"popup_blocked_by_browser"**
- Solution: The popup was blocked. Make sure your browser allows popups for localhost:5000

**"redirect_mismatch"**
- Solution: The redirect URI doesn't match. Make sure you added `http://localhost:5000` to authorized origins in Step 2

**"idpiframe_initialization_failed"**
- Solution: Check that OAuth consent screen is configured (Step 1)

## Debugging Tips

Add better error handling in LoginScreen_.dart:
```dart
Future<UserCredential?> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    if (googleUser == null) {
      Dialogs.showSnackbar(context, 'Sign in cancelled');
      return null;
    }
    
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await APIs.auth.signInWithCredential(credential);
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error: ${e.code} - ${e.message}');
    Dialogs.showSnackbar(context, 'Auth Error: ${e.message}');
    return null;
  } catch (e) {
    print('Sign In Error: $e');
    print('Error Type: ${e.runtimeType}');
    Dialogs.showSnackbar(context, 'Error: $e');
    return null;
  }
}
```

## References
- [Firebase Web Setup Guide](https://firebase.google.com/docs/auth/web/google-signin)
- [Google Cloud OAuth Configuration](https://cloud.google.com/docs/authentication/oauth2)
- [Flutter Firebase Web Documentation](https://firebase.flutter.dev/docs/overview/)
