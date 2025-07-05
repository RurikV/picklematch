import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_config.dart';

// Mock classes for development fallback
class MockUser implements User {
  final String _uid;
  final String _email;

  MockUser(this._uid, this._email);

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  // Implement other required methods and properties with default values
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements UserCredential {
  final MockUser _user;

  MockUserCredential(String uid, String email) : _user = MockUser(uid, email);

  @override
  User? get user => _user;

  // Implement other required methods and properties with default values
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  bool _initialized = false;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  bool get isInitialized => _initialized;

  // Social sign-in instances
  // Using a platform-specific configuration to handle different environments
  // For Android, we rely on the configuration in google-services.json
  // For iOS, we rely on the configuration in GoogleService-Info.plist
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Don't specify clientId for mobile platforms as it's configured in the respective platform files
    // For web, a clientId would be needed, but this is a mobile app
  );

  // Debug method to log GoogleSignIn configuration
  void _logGoogleSignInConfig() {
    print('\n======== GOOGLE SIGN-IN CONFIGURATION ========');
    print('FirebaseService: GoogleSignIn Configuration:');
    print('FirebaseService: Scopes: ${_googleSignIn.scopes}');
    print('FirebaseService: SignInOption: ${_googleSignIn.signInOption}');

    // Log platform information
    if (kIsWeb) {
      print('FirebaseService: Running on Web platform');
    } else if (Platform.isAndroid) {
      print('FirebaseService: Running on Android platform');
      // Package name is not directly accessible from Platform class
      print('FirebaseService: Android version: ${Platform.version}');
      print('FirebaseService: Android locale: ${Platform.localeName}');

      // Log the expected package name from google-services.json
      print('FirebaseService: Expected package name: app.vercel.picklematch.picklematch');
      print('FirebaseService: Verify this matches your app\'s actual package name in build.gradle');
    } else if (Platform.isIOS) {
      print('FirebaseService: Running on iOS platform');
      print('FirebaseService: iOS locale: ${Platform.localeName}');
    } else {
      print('FirebaseService: Running on ${Platform.operatingSystem} platform');
    }

    // Log Firebase configuration
    print('FirebaseService: Firebase Configuration:');
    print('FirebaseService: Project ID: ${FirebaseConfig.projectId}');
    print('FirebaseService: Auth Domain: ${FirebaseConfig.authDomain}');
    print('FirebaseService: App ID: ${FirebaseConfig.appId}');

    // Log SHA-1 certificate fingerprint information
    print('FirebaseService: SHA-1 Certificate Fingerprint:');
    print('FirebaseService: For error code 10, verify that the SHA-1 fingerprint in the Firebase console matches the one used to sign your app.');
    print('FirebaseService: You can find your app\'s SHA-1 fingerprint using:');
    print('FirebaseService: - For debug builds: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android');
    print('FirebaseService: - For release builds: keytool -list -v -keystore your-release-key.keystore -alias your-key-alias');
    print('FirebaseService: Then add this fingerprint to the Firebase console under Project Settings > Your Apps > SHA certificate fingerprints.');

    // Add more detailed instructions for fixing error code 10
    print('FirebaseService: ');
    print('FirebaseService: === HOW TO FIX ERROR CODE 10 ===');
    print('FirebaseService: 1. Run this command in your terminal to get your debug SHA-1:');
    print('FirebaseService:    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android');
    print('FirebaseService: 2. Look for "SHA1:" in the output and copy the fingerprint');
    print('FirebaseService: 3. Go to Firebase Console > Project Settings > Your Apps > Android App');
    print('FirebaseService: 4. Add the SHA-1 fingerprint you copied');
    print('FirebaseService: 5. Download the updated google-services.json file');
    print('FirebaseService: 6. Replace the existing file in your project\'s android/app/ directory');
    print('FirebaseService: 7. Rebuild your app');
    print('FirebaseService: ');

    print('======== END GOOGLE SIGN-IN CONFIGURATION ========\n');
  }

  // Initialize Firebase
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          authDomain: FirebaseConfig.authDomain,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          appId: FirebaseConfig.appId,
        ),
      );

      // Get instances
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      _initialized = true;
      debugPrint('Firebase initialized successfully');

      // Log GoogleSignIn configuration for debugging
      _logGoogleSignInConfig();

      // Verify Google Sign-In configuration
      await verifyGoogleSignInConfiguration();
    } catch (e) {
      // Check if the error is because Firebase is already initialized
      if (e.toString().contains('core/duplicate-app') && e.toString().contains('already exists')) {
        debugPrint('Firebase app already exists, using existing instance');

        // Get instances from existing Firebase app
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;

        _initialized = true;
        debugPrint('Using existing Firebase instance');

        // Log GoogleSignIn configuration for debugging
        _logGoogleSignInConfig();

        // No need to verify configuration as it's already initialized
      } else {
        // For other errors, log and rethrow
        debugPrint('Error initializing Firebase: $e');
        debugPrint('Error details: ${e.toString()}');
        rethrow;
      }
    }
  }

  // Verify Google Sign-In configuration
  Future<bool> verifyGoogleSignInConfiguration() async {
    print('FirebaseService: Verifying Google Sign-In configuration...');
    bool isConfigValid = true;

    try {
      // Check if we're on Android (the platform where SHA-1 is required)
      if (!kIsWeb && Platform.isAndroid) {
        print('FirebaseService: Running on Android, checking configuration...');

        // Check if the app ID is valid
        if (FirebaseConfig.appId.isEmpty || FirebaseConfig.appId.contains('YOUR_APP_ID')) {
          print('FirebaseService: WARNING - Invalid or missing Firebase App ID');
          isConfigValid = false;
        }

        // Check if the API key is valid
        if (FirebaseConfig.apiKey.isEmpty || FirebaseConfig.apiKey.contains('YOUR_API_KEY')) {
          print('FirebaseService: WARNING - Invalid or missing Firebase API key');
          isConfigValid = false;
        }

        // Try a simple Firebase operation to verify connectivity
        try {
          await _auth.fetchSignInMethodsForEmail('test@example.com');
          print('FirebaseService: Firebase connectivity test successful');
        } catch (e) {
          print('FirebaseService: WARNING - Firebase connectivity test failed: $e');
          if (e.toString().contains('INVALID_API_KEY')) {
            print('FirebaseService: API key is invalid or restricted');
            isConfigValid = false;
          }
        }

        print('FirebaseService: Configuration verification complete');
        if (isConfigValid) {
          print('FirebaseService: Google Sign-In configuration appears valid');
          print('FirebaseService: If you still encounter error code 10, please follow the steps above to add your SHA-1 fingerprint to Firebase console');
        } else {
          print('FirebaseService: Google Sign-In configuration has issues that need to be fixed');
          print('FirebaseService: Please follow the steps in the HOW TO FIX ERROR CODE 10 section above');
        }
      } else {
        print('FirebaseService: Not running on Android, skipping SHA-1 verification');
      }
    } catch (e) {
      print('FirebaseService: Error during configuration verification: $e');
      isConfigValid = false;
    }

    return isConfigValid;
  }


  // Authentication methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendSignInLinkToEmail(String email) async {
    print('FirebaseService: Sending sign-in link to email: $email');
    try {
      var actionCodeSettings = ActionCodeSettings(
        url: 'https://picklematch.vercel.app/emailSignIn',
        handleCodeInApp: true,
        androidPackageName: 'app.vercel.picklematch.picklematch',
        androidInstallApp: true,
        androidMinimumVersion: '12',
        iOSBundleId: 'app.vercel.picklematch.picklematch',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      print('FirebaseService: Sign-in link sent successfully');
    } catch (e) {
      print('FirebaseService: Error sending sign-in link: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailLink(String email, String emailLink) async {
    print('FirebaseService: Signing in with email link');
    try {
      if (_auth.isSignInWithEmailLink(emailLink)) {
        print('FirebaseService: Valid email link, attempting sign in');
        return await _auth.signInWithEmailLink(
          email: email,
          emailLink: emailLink,
        );
      } else {
        print('FirebaseService: Invalid email link');
        throw Exception('Invalid email link');
      }
    } catch (e) {
      print('FirebaseService: Error signing in with email link: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // User methods
  Future<void> storeUserIfNew(String uid, String email, {bool active = false}) async {
    DocumentReference userRef = _firestore.collection('users').doc(uid);
    DocumentSnapshot snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'uid': uid,
        'email': email,
        'rating': 1000,
        'role': 'user',
        'active': active,
      });
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning null for user data');
        return null;
      }

      // Query Firestore for user data
      print('FirebaseService: Querying Firestore for user data');
      try {
        DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
        if (snapshot.exists) {
          print('FirebaseService: User data found in Firestore');
          return snapshot.data() as Map<String, dynamic>;
        } else {
          print('FirebaseService: No user document found in Firestore for UID: $uid');
        }
      } catch (firestoreError) {
        print('FirebaseService: Error querying Firestore: $firestoreError');
        print('FirebaseService: Continuing with basic user data');
        // Continue with basic user data if Firestore query fails
      }

      // If we get here, either no user data was found in Firestore or there was an error
      // Get the current Firebase user to extract basic information
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        print('FirebaseService: Creating basic user data from Firebase Auth');
        // Create basic user data from Firebase Auth
        return {
          'uid': uid,
          'email': currentUser.email ?? 'unknown',
          'rating': 1000,
          'role': 'user',
          'active': true,
          'name': currentUser.displayName ?? (currentUser.email?.split('@').first ?? 'User'),
        };
      }

      print('FirebaseService: No user data found in Firestore or Firebase Auth');
      return null;
    } catch (e) {
      print('FirebaseService: Error getting user data for UID $uid: $e');

      // Try to get basic data from Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        print('FirebaseService: Creating basic user data from Firebase Auth after error');
        // Create basic user data from Firebase Auth
        return {
          'uid': uid,
          'email': currentUser.email ?? 'unknown',
          'rating': 1000,
          'role': 'user',
          'active': true,
          'name': currentUser.displayName ?? (currentUser.email?.split('@').first ?? 'User'),
        };
      }

      // Return null if all else fails
      return null;
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Future<void> updateUserRating(String uid, int rating) async {
    await _firestore.collection('users').doc(uid).update({'rating': rating});
  }

  Future<void> setUserActive(String uid, bool active) async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, cannot set user active status');
        return;
      }

      print('FirebaseService: Setting user $uid active status to $active');
      await _firestore.collection('users').doc(uid).update({'active': active});
      print('FirebaseService: Successfully updated user active status');
    } catch (e) {
      print('FirebaseService: Error setting user active status: $e');
      // Don't rethrow the exception, just log it
      // This allows the verification process to continue even if Firestore access fails
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning empty users map');
        return {};
      }

      QuerySnapshot snapshot = await _firestore.collection('users').get();
      Map<String, dynamic> users = {};

      for (var doc in snapshot.docs) {
        users[doc.id] = doc.data();
      }

      return users;
    } catch (e) {
      print('FirebaseService: Error getting all users: $e');
      // Return empty map on error
      return {};
    }
  }

  // Game methods
  Future<String> addGame(String dateStr, String timeStr, String locationId) async {
    DocumentReference docRef = await _firestore.collection('games').add({
      'date': dateStr,
      'time': timeStr,
      'location_id': locationId,
      'team1': {'player1': null, 'player2': null},
      'team2': {'player1': null, 'player2': null},
      'team1_score1': 0,
      'team1_score2': 0,
      'team2_score1': 0,
      'team2_score2': 0,
    });

    return docRef.id;
  }

  Future<List<Map<String, dynamic>>> getGamesForDate(String dateStr) async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning empty games list');
        return [];
      }

      QuerySnapshot snapshot = await _firestore.collection('games')
          .where('date', isEqualTo: dateStr)
          .orderBy('time')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('FirebaseService: Error getting games for date $dateStr: $e');
      // Return empty list on error
      return [];
    }
  }

  Future<void> registerForGame(String gameId, String teamKey, String uid, String email) async {
    DocumentReference gameRef = _firestore.collection('games').doc(gameId);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(gameRef);

      if (!snapshot.exists) {
        throw Exception('Game does not exist');
      }

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> team = data[teamKey] as Map<String, dynamic>;

      if (team['player1'] == null) {
        transaction.update(gameRef, {
          '$teamKey.player1': uid,
          '$teamKey.player1_email': email,
        });
      } else if (team['player2'] == null) {
        transaction.update(gameRef, {
          '$teamKey.player2': uid,
          '$teamKey.player2_email': email,
        });
      } else {
        throw Exception('Team is full');
      }
    });
  }

  Future<void> updateGameScore(String gameId, int team1Score1, int team1Score2, int team2Score1, int team2Score2) async {
    await _firestore.collection('games').doc(gameId).update({
      'team1_score1': team1Score1,
      'team1_score2': team1Score2,
      'team2_score1': team2Score1,
      'team2_score2': team2Score2,
    });
  }

  Future<void> deleteGame(String gameId) async {
    await _firestore.collection('games').doc(gameId).delete();
  }

  Future<Set<String>> getAllGameDates() async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning empty game dates');
        return {};
      }

      QuerySnapshot snapshot = await _firestore.collection('games').get();
      Set<String> dates = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        dates.add(data['date'] as String);
      }

      return dates;
    } catch (e) {
      print('FirebaseService: Error getting all game dates: $e');
      // Return empty set on error
      return {};
    }
  }

  Future<Set<String>> getGameDatesForLocation(String locationId) async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning empty game dates for location');
        return {};
      }

      QuerySnapshot snapshot = await _firestore.collection('games')
          .where('location_id', isEqualTo: locationId)
          .get();

      Set<String> dates = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        dates.add(data['date'] as String);
      }

      return dates;
    } catch (e) {
      print('FirebaseService: Error getting game dates for location $locationId: $e');
      // Return empty set on error
      return {};
    }
  }

  // Location methods
  Future<String> addLocation(String name) async {
    DocumentReference docRef = await _firestore.collection('locations').add({
      'name': name,
    });

    return docRef.id;
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    print('FirebaseService: getAllLocations called');
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning empty locations list');
        return [];
      }

      QuerySnapshot snapshot = await _firestore.collection('locations').get();
      print('FirebaseService: Got ${snapshot.docs.length} location documents from Firestore');

      final locations = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      print('FirebaseService: Returning ${locations.length} locations: ${locations.map((loc) => loc['name']).join(', ')}');
      return locations;
    } catch (e) {
      print('FirebaseService: Error getting locations: $e');
      // Return empty list on error, let the API service handle fallback
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLocationById(String locationId) async {
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning null for location');
        return null;
      }

      DocumentSnapshot snapshot = await _firestore.collection('locations').doc(locationId).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data['id'] = snapshot.id;
        return data;
      }

      return null;
    } catch (e) {
      print('FirebaseService: Error getting location by ID $locationId: $e');
      // Return null on error
      return null;
    }
  }

  Future<void> initializeDefaultLocations() async {
    print('FirebaseService: initializeDefaultLocations called');
    List<String> defaultLocations = [
      "Tondiraba Indoor", 
      "Tondiraba Outdoor", 
      "Koorti", 
      "Golden Club", 
      "Pirita"
    ];
    print('FirebaseService: Default locations: ${defaultLocations.join(', ')}');

    print('FirebaseService: Getting existing locations');
    List<Map<String, dynamic>> existingLocations = await getAllLocations();
    Set<String> existingNames = existingLocations.map((loc) => loc['name'] as String).toSet();
    print('FirebaseService: Existing location names: ${existingNames.join(', ')}');

    int addedCount = 0;
    for (String name in defaultLocations) {
      if (!existingNames.contains(name)) {
        print('FirebaseService: Adding new location: $name');
        await addLocation(name);
        addedCount++;
      }
    }
    print('FirebaseService: Added $addedCount new locations');
  }

  // Social sign-in methods
  Future<UserCredential> signInWithGoogle() async {
    print('FirebaseService: signInWithGoogle called');

    // Log GoogleSignIn configuration
    _logGoogleSignInConfig();

    try {
      // Trigger the authentication flow
      print('FirebaseService: Triggering Google Sign-In flow');
      GoogleSignInAccount? googleUser;
      try {
        print('FirebaseService: Calling _googleSignIn.signIn()');
        googleUser = await _googleSignIn.signIn();
        print('FirebaseService: GoogleSignIn.signIn() completed successfully');
      } catch (signInError) {
        print('FirebaseService: Error during GoogleSignIn.signIn(): $signInError');

        // Extract more detailed error information if it's an ApiException
        if (signInError.toString().contains('ApiException')) {
          print('FirebaseService: Detected ApiException in error');

          // Try to extract error code
          final errorString = signInError.toString();
          final codeMatch = RegExp(r'ApiException: (\d+)').firstMatch(errorString);
          if (codeMatch != null) {
            final errorCode = codeMatch.group(1);
            print('FirebaseService: ApiException error code: $errorCode');

            // Provide more information about specific error codes
            switch (errorCode) {
              case '10':
                print('FirebaseService: Error code 10 - Developer error: The application is misconfigured.');
                print('FirebaseService: This could be due to:');
                print('FirebaseService: 1. Incorrect package name in google-services.json');
                print('FirebaseService: 2. Missing SHA-1 certificate fingerprint in Firebase console');
                print('FirebaseService: 3. Incorrect OAuth client ID');

                // Print detailed instructions for fixing error code 10
                print('FirebaseService: ');
                print('FirebaseService: === HOW TO FIX ERROR CODE 10 ===');
                print('FirebaseService: 1. Run this command in your terminal to get your debug SHA-1:');
                print('FirebaseService:    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android');
                print('FirebaseService: 2. Look for "SHA1:" in the output and copy the fingerprint');
                print('FirebaseService: 3. Go to Firebase Console > Project Settings > Your Apps > Android App');
                print('FirebaseService: 4. Add the SHA-1 fingerprint you copied');
                print('FirebaseService: 5. Download the updated google-services.json file');
                print('FirebaseService: 6. Replace the existing file in your project\'s android/app/ directory');
                print('FirebaseService: 7. Rebuild your app');
                print('FirebaseService: ');
                break;
              case '12500':
                print('FirebaseService: Error code 12500 - Play Services is out of date');
                break;
              case '8':
                print('FirebaseService: Error code 8 - Internal error');
                break;
              case '5':
                print('FirebaseService: Error code 5 - Invalid account');
                break;
              case '7':
                print('FirebaseService: Error code 7 - Network error');
                break;
              case '4':
                print('FirebaseService: Error code 4 - Sign in required');
                break;
              default:
                print('FirebaseService: Unknown error code: $errorCode');
            }
          }
        }

        throw Exception('Error during Google Sign-In process: $signInError');
      }

      if (googleUser == null) {
        print('FirebaseService: Google Sign-In was cancelled by user');
        throw Exception('Google sign-in was cancelled by user');
      }

      print('FirebaseService: Google Sign-In successful for user: ${googleUser.email}');

      // Obtain the auth details from the request
      print('FirebaseService: Getting authentication details');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('FirebaseService: Got authentication details');

      // Create a new credential
      print('FirebaseService: Creating credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('FirebaseService: Credential created');

      // Sign in to Firebase with the Google credential
      print('FirebaseService: Signing in to Firebase with credential');
      final userCredential = await _auth.signInWithCredential(credential);
      print('FirebaseService: Signed in to Firebase successfully');

      // Store the user in Firestore if it's new
      if (userCredential.user != null) {
        print('FirebaseService: Storing Google user in Firestore');
        try {
          // Get display name and photo URL from Google account
          String? displayName = userCredential.user!.displayName;
          String? photoURL = userCredential.user!.photoURL;
          String email = userCredential.user!.email ?? 'unknown';

          // Create a map with user data
          Map<String, dynamic> userData = {
            'uid': userCredential.user!.uid,
            'email': email,
            'rating': 1000,
            'role': 'user',
            'active': true,
          };

          // Add name if available
          if (displayName != null && displayName.isNotEmpty) {
            userData['name'] = displayName;
          } else {
            userData['name'] = email.split('@').first;
          }

          // Add photo URL if available
          if (photoURL != null && photoURL.isNotEmpty) {
            userData['photoURL'] = photoURL;
          }

          // Store user data in Firestore
          DocumentReference userRef = _firestore.collection('users').doc(userCredential.user!.uid);
          DocumentSnapshot snapshot = await userRef.get();

          if (!snapshot.exists) {
            // Create new user document
            await userRef.set(userData);
            print('FirebaseService: Created new user document in Firestore');
          } else {
            // Update existing user document with new data from Google
            // but preserve existing data like rating
            Map<String, dynamic> existingData = snapshot.data() as Map<String, dynamic>;

            // Merge existing data with new data, prioritizing existing values for certain fields
            userData['rating'] = existingData['rating'] ?? userData['rating'];
            userData['role'] = existingData['role'] ?? userData['role'];

            await userRef.update(userData);
            print('FirebaseService: Updated existing user document in Firestore');
          }

          print('FirebaseService: Successfully stored user in Firestore');
        } catch (firestoreError) {
          print('FirebaseService: Error storing user in Firestore: $firestoreError');
          print('FirebaseService: Continuing with authentication process');
          // Continue even if Firestore storage fails
        }
      }

      return userCredential;
    } catch (e) {
      print('FirebaseService: Error in Google Sign-In: $e');
      print('FirebaseService: Error type: ${e.runtimeType}');
      print('FirebaseService: Full error details: ${e.toString()}');

      // Provide more specific error messages based on the error type
      String errorMessage = 'Google sign-in failed';

      // Check for network errors
      if (e.toString().contains('network_error')) {
        errorMessage = 'Network error during Google sign-in. Please check your internet connection.';
        print('FirebaseService: Detected network error');
      } 
      // Check for user cancellation
      else if (e.toString().contains('canceled')) {
        errorMessage = 'Google sign-in was canceled by the user.';
        print('FirebaseService: Detected user cancellation');
      } 
      // Check for credential already in use
      else if (e.toString().contains('credential_already_in_use')) {
        errorMessage = 'This Google account is already linked to another user.';
        print('FirebaseService: Detected credential already in use');
      } 
      // Check for invalid credentials
      else if (e.toString().contains('invalid_credential')) {
        errorMessage = 'Invalid Google credentials. Please try again.';
        print('FirebaseService: Detected invalid credentials');
      } 
      // Check for package name mismatch
      else if (e.toString().contains('Unknown calling package name')) {
        errorMessage = 'Authentication configuration issue. Please try again or contact support.';
        print('FirebaseService: Detected "Unknown calling package name" error.');
        print('FirebaseService: This is likely due to a mismatch between the package name in google-services.json and the actual package name used by the app.');
        print('FirebaseService: Check that the package name in your google-services.json matches your app\'s package name.');
        print('FirebaseService: Also verify that the SHA-1 fingerprint is correctly added to the Firebase console.');
      }
      // Check for API exceptions not caught earlier
      else if (e.toString().contains('ApiException')) {
        print('FirebaseService: Detected ApiException in main catch block');

        // Try to extract error code
        final errorString = e.toString();
        final codeMatch = RegExp(r'ApiException: (\d+)').firstMatch(errorString);
        if (codeMatch != null) {
          final errorCode = codeMatch.group(1);
          print('FirebaseService: ApiException error code: $errorCode');

          // Special handling for error code 10
          if (errorCode == '10') {
            print('FirebaseService: Error code 10 - Developer error: The application is misconfigured.');
            print('FirebaseService: This could be due to:');
            print('FirebaseService: 1. Incorrect package name in google-services.json');
            print('FirebaseService: 2. Missing SHA-1 certificate fingerprint in Firebase console');
            print('FirebaseService: 3. Incorrect OAuth client ID');

            // Print detailed instructions for fixing error code 10
            print('FirebaseService: ');
            print('FirebaseService: === HOW TO FIX ERROR CODE 10 ===');
            print('FirebaseService: 1. Run this command in your terminal to get your debug SHA-1:');
            print('FirebaseService:    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android');
            print('FirebaseService: 2. Look for "SHA1:" in the output and copy the fingerprint');
            print('FirebaseService: 3. Go to Firebase Console > Project Settings > Your Apps > Android App');
            print('FirebaseService: 4. Add the SHA-1 fingerprint you copied');
            print('FirebaseService: 5. Download the updated google-services.json file');
            print('FirebaseService: 6. Replace the existing file in your project\'s android/app/ directory');
            print('FirebaseService: 7. Rebuild your app');
            print('FirebaseService: ');

            errorMessage = 'Google Sign-In configuration error (code 10). Please add your SHA-1 fingerprint to Firebase console.';
          } else {
            errorMessage = 'Google Sign-In API error (code $errorCode). Please try again or contact support.';
          }
        } else {
          print('FirebaseService: Could not extract error code from ApiException');
          errorMessage = 'Google Sign-In API error. Please try again or contact support.';
        }
      }
      // Check for Firebase auth errors
      else if (e.toString().contains('FirebaseAuth')) {
        print('FirebaseService: Detected FirebaseAuth error');
        errorMessage = 'Firebase authentication error. Please try again or contact support.';
      }

      print('FirebaseService: Detailed error message: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  // Facebook authentication removed as per requirements

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

}
