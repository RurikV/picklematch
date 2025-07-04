import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  // Firebase configuration loaded from .env file
  static String get apiKey => dotenv.env['PUBLIC_FIREBASE_API_KEY'] ?? '';
  static String get authDomain => dotenv.env['PUBLIC_FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get projectId => dotenv.env['PUBLIC_FIREBASE_PROJECT_ID'] ?? '';
  static String get storageBucket => dotenv.env['PUBLIC_FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get messagingSenderId => dotenv.env['PUBLIC_FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get appId => dotenv.env['PUBLIC_FIREBASE_APP_ID'] ?? '';

  // Note: These values are loaded from a .env file which should be added to .gitignore
  // to keep credentials secure and not committed to version control.
}
