# PickleMatch

A Flutter application for scheduling and managing pickle ball games. This app is a port of the original Clojure application to Flutter, with Firebase integration for authentication and data storage.

## Features

- User authentication (email/password)
- Game scheduling and management
- Player registration for games
- Score tracking
- Location management
- Power saving mode detection (platform-specific code)

## Getting Started

### Prerequisites

- Flutter SDK (version 3.8.1 or higher)
- Firebase account
- Android Studio or VS Code with Flutter extensions

### Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app to your Firebase project
   - Package name: `app.vercel.picklematch`
   - Download the `google-services.json` file and place it in the `android/app` directory
   - **IMPORTANT**: This file contains sensitive API keys and should not be committed to version control
   - Use the provided `google-services.json.template` file as a reference
3. Add an iOS app to your Firebase project (if needed)
   - Bundle ID: `app.vercel.picklematch`
   - Download the `GoogleService-Info.plist` file and place it in the `ios/Runner` directory
   - **IMPORTANT**: This file contains sensitive API keys and should not be committed to version control
4. Enable Authentication in Firebase Console
   - Go to Authentication > Sign-in method
   - Enable Email/Password authentication
5. Create Firestore Database
   - Go to Firestore Database > Create database
   - Start in production mode
   - Choose a location close to your users

### Configuration

1. Copy the `.env.template` file to create a new `.env` file in the root of your project:

```bash
cp .env.template .env
```

2. Update the `.env` file with your Firebase configuration. You can find these values in your Firebase project settings or in the `google-services.json` file:

```
PUBLIC_FIREBASE_API_KEY=your_api_key
PUBLIC_FIREBASE_AUTH_DOMAIN=your_auth_domain
PUBLIC_FIREBASE_PROJECT_ID=your_project_id
PUBLIC_FIREBASE_STORAGE_BUCKET=your_storage_bucket
PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
PUBLIC_FIREBASE_APP_ID=your_app_id
```

> **IMPORTANT**: The `.env` file is included in `.gitignore` to prevent sensitive credentials from being committed to version control. The `.env.template` file serves as a template and does not contain actual credentials.

> **SECURITY NOTE**: If you believe your API keys have been exposed in version control history, you should rotate them immediately in the Firebase Console and update your local configuration files.

3. Install dependencies:

```bash
flutter pub get
```

4. Run the app:

```bash
flutter run
```

## Architecture

The app uses the BLoC (Business Logic Component) pattern for state management:

- **Models**: Data models for users, games, locations, etc.
- **BLoCs**: Business logic components for authentication, game management, etc.
- **Screens**: UI screens for login, home, game details, etc.
- **Services**: API service for Firebase interaction, storage service for local storage, etc.
- **Widgets**: Reusable UI components

## Testing

Run the tests with:

```bash
flutter test
```

## Security Best Practices

This project handles sensitive API keys and credentials. Follow these best practices to keep your app secure:

1. **Never commit sensitive files to version control**:
   - `google-services.json`
   - `GoogleService-Info.plist`
   - `.env`
   - Any files containing API keys, passwords, or secrets

2. **Use environment variables** for sensitive information:
   - Store API keys in the `.env` file
   - Access them through the `FirebaseConfig` class

3. **Rotate compromised credentials immediately**:
   - If you suspect API keys have been exposed, rotate them in the Firebase Console
   - Update all local configurations with the new keys

4. **Restrict API key usage** in the Firebase Console:
   - Limit API key usage to specific Android applications
   - Set up API key restrictions based on IP addresses or referrers

## Building for Production

Generate an AAB (Android App Bundle) for release:

```bash
flutter build appbundle
```

Generate an IPA for iOS:

```bash
flutter build ipa
```
