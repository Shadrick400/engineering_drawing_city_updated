# Google Sign-In setup

Google Sign-In is implemented for student accounts. A first-time Google sign-in creates a Firestore `users/{uid}` profile with the `student` role. Existing student profiles are reused. Google sign-in does not grant administrator access.

The Flutter dependency `google_sign_in` is already present in `pubspec.yaml`; no dependency change is required.

## 1. Enable Google in Firebase Authentication

1. Open the Firebase project for Engineering Drawing City.
2. Go to **Authentication → Sign-in method**.
3. Enable **Google** and save the provider.
4. Confirm the project's support email is configured.

## 2. Configure Android OAuth

1. In Firebase Console, open **Project settings → Your apps** and select the Android app whose package name is `com.example.engineering_drawing_city`.
2. From the app's `android` directory, run `./gradlew signingReport` and copy the SHA-1 and SHA-256 fingerprints for the signing configuration you use.
3. Add those fingerprints to the Android app in Firebase Console.
4. Download the refreshed `google-services.json` and replace `android/app/google-services.json`.
5. Repeat the fingerprint registration for the release signing key before publishing a release build.

The current checked-in Android Firebase configuration does not yet contain OAuth client entries, so this Firebase Console step is required before Google sign-in can return a Firebase credential.

## 3. Configure iOS OAuth

1. In Firebase Console, select the iOS app and download the refreshed `GoogleService-Info.plist` after enabling Google as a provider.
2. Replace `ios/Runner/GoogleService-Info.plist` with that downloaded file.
3. Copy the value of `REVERSED_CLIENT_ID` from the refreshed plist.
4. Add that value as a URL scheme under `CFBundleURLTypes` in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the exact value from Firebase. The current checked-in iOS plist does not include the Google OAuth client identifiers, so this setup is required for iOS.

## 4. Build and test

From the Flutter project directory:

```bash
flutter pub get
flutter analyze
flutter test
```

Then test on a physical Android device (and an iOS device if available):

- A new Google account creates a student profile.
- A returning student Google account signs in and keeps their existing profile.
- A suspended student account is denied access.
- An administrator profile cannot use the student Google sign-in button.
- Email/password login, registration, and password reset still work.

Do not commit private signing keys or service-account credentials. Firebase client configuration files are app configuration, not substitutes for keeping signing keys private.
