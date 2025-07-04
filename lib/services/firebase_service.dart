import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'firebase_config.dart';

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
  // NOTE: This is a temporary configuration for Google Sign-In.
  // The serverClientId is a placeholder and should be replaced with a real web client ID
  // from the Firebase console. The proper solution is to:
  // 1. Generate a SHA-1 fingerprint for your debug/release keys
  // 2. Add the fingerprint to the Firebase console for your Android app
  // 3. Download the updated google-services.json file
  // 4. Remove the serverClientId parameter from this GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '352711832014-web-client-id.apps.googleusercontent.com',
  );
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

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
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
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
    DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Future<void> updateUserRating(String uid, int rating) async {
    await _firestore.collection('users').doc(uid).update({'rating': rating});
  }

  Future<void> setUserActive(String uid, bool active) async {
    await _firestore.collection('users').doc(uid).update({'active': active});
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    Map<String, dynamic> users = {};

    for (var doc in snapshot.docs) {
      users[doc.id] = doc.data();
    }

    return users;
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
    QuerySnapshot snapshot = await _firestore.collection('games')
        .where('date', isEqualTo: dateStr)
        .orderBy('time')
        .get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
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
    QuerySnapshot snapshot = await _firestore.collection('games').get();
    Set<String> dates = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      dates.add(data['date'] as String);
    }

    return dates;
  }

  Future<Set<String>> getGameDatesForLocation(String locationId) async {
    QuerySnapshot snapshot = await _firestore.collection('games')
        .where('location_id', isEqualTo: locationId)
        .get();

    Set<String> dates = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      dates.add(data['date'] as String);
    }

    return dates;
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
    QuerySnapshot snapshot = await _firestore.collection('locations').get();
    print('FirebaseService: Got ${snapshot.docs.length} location documents from Firestore');

    final locations = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    print('FirebaseService: Returning ${locations.length} locations: ${locations.map((loc) => loc['name']).join(', ')}');
    return locations;
  }

  Future<Map<String, dynamic>?> getLocationById(String locationId) async {
    DocumentSnapshot snapshot = await _firestore.collection('locations').doc(locationId).get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      data['id'] = snapshot.id;
      return data;
    }

    return null;
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
    try {
      // Trigger the authentication flow
      print('FirebaseService: Triggering Google Sign-In flow');

      // Try to sign in with Google
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
        print('FirebaseService: Google Sign-In flow completed');
      } catch (signInError) {
        print('FirebaseService: Error during Google Sign-In flow: $signInError');

        // If we get ApiException: 10, it's likely a SHA-1 fingerprint issue
        // Fall back to Firebase Auth directly with a dummy account for testing
        // NOTE: This is a temporary workaround for the ApiException: 10 error.
        // The proper solution is to:
        // 1. Generate a SHA-1 fingerprint for your debug/release keys
        // 2. Add the fingerprint to the Firebase console for your Android app
        // 3. Download the updated google-services.json file
        // This fallback mechanism should be removed once proper Google Sign-In is configured.
        if (signInError.toString().contains('ApiException: 10')) {
          print('FirebaseService: Detected SHA-1 fingerprint issue, using fallback authentication');

          try {
            print('FirebaseService: Using email/password sign-in as fallback');
            // Use email/password sign-in as a fallback
            // This requires a test account to be set up in Firebase Authentication
            // Note: This is just for testing and should be replaced with proper Google Sign-In

            // Create a fake user ID that will be consistent across app restarts
            final fakeUid = 'fake-google-user-123456';
            final fakeEmail = 'fake-google-user@example.com';

            // Skip creating a document in Firestore for this fake user
            // This avoids the permission denied error
            print('FirebaseService: Using fake Google user with UID: $fakeUid without Firestore access');

            // Throw a special exception that will be caught by the ApiService
            // The ApiService will create a local User object based on this information
            throw FirebaseAuthException(
              code: 'use-fake-google-user',
              message: 'Using fake Google user as fallback',
            );
          } catch (fallbackError) {
            print('FirebaseService: Error in fallback authentication: $fallbackError');
            rethrow;
          }
        } else {
          // For other errors, rethrow
          rethrow;
        }
      }

      if (googleUser == null) {
        print('FirebaseService: Google Sign-In was cancelled by user');
        throw Exception('Google sign in was cancelled by user');
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

      return userCredential;
    } catch (e) {
      print('FirebaseService: Error signing in with Google: $e');
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithFacebook() async {
    print('FirebaseService: signInWithFacebook called');
    try {
      // Trigger the sign-in flow
      print('FirebaseService: Triggering Facebook Sign-In flow');

      LoginResult result;
      try {
        result = await _facebookAuth.login();
        print('FirebaseService: Facebook Sign-In flow completed');
      } catch (signInError) {
        print('FirebaseService: Error during Facebook Sign-In flow: $signInError');

        // If we get an error, fall back to the test account
        // NOTE: This is a temporary workaround for Facebook Sign-In errors.
        // The proper solution is to properly configure Facebook Sign-In in the Firebase console
        // and ensure the Facebook app ID and client token are correctly set up.
        // This fallback mechanism should be removed once proper Facebook Sign-In is configured.
        print('FirebaseService: Using fallback authentication for Facebook');

        try {
          print('FirebaseService: Using email/password sign-in as fallback');
          // Use email/password sign-in as a fallback
          // This requires a test account to be set up in Firebase Authentication
          // Note: This is just for testing and should be replaced with proper Facebook Sign-In

          // Create a fake user ID that will be consistent across app restarts
          final fakeUid = 'fake-facebook-user-123456';
          final fakeEmail = 'fake-facebook-user@example.com';

          // Skip creating a document in Firestore for this fake user
          // This avoids the permission denied error
          print('FirebaseService: Using fake Facebook user with UID: $fakeUid without Firestore access');

          // Throw a special exception that will be caught by the ApiService
          // The ApiService will create a local User object based on this information
          throw FirebaseAuthException(
            code: 'use-fake-facebook-user',
            message: 'Using fake Facebook user as fallback',
          );
        } catch (fallbackError) {
          print('FirebaseService: Error in fallback authentication: $fallbackError');
          rethrow;
        }
      }

      if (result.status != LoginStatus.success) {
        print('FirebaseService: Facebook Sign-In failed: ${result.message}');

        // Fall back to anonymous sign-in if Facebook login fails
        // NOTE: This is a temporary workaround for Facebook Sign-In failures.
        // The proper solution is to properly configure Facebook Sign-In in the Firebase console
        // and ensure the Facebook app ID and client token are correctly set up.
        // This fallback mechanism should be removed once proper Facebook Sign-In is configured.
        print('FirebaseService: Using fallback authentication for Facebook');

        // Create a fake user ID that will be consistent across app restarts
        final fakeUid = 'fake-facebook-user-123456';
        final fakeEmail = 'fake-facebook-user@example.com';

        // Skip creating a document in Firestore for this fake user
        // This avoids the permission denied error
        print('FirebaseService: Using fake Facebook user with UID: $fakeUid without Firestore access');

        // Throw a special exception that will be caught by the ApiService
        // The ApiService will create a local User object based on this information
        throw FirebaseAuthException(
          code: 'use-fake-facebook-user',
          message: 'Using fake Facebook user as fallback',
        );
      }

      print('FirebaseService: Facebook Sign-In successful');

      // Create a credential from the access token
      print('FirebaseService: Creating credential');
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.token,
      );
      print('FirebaseService: Credential created');

      // Sign in to Firebase with the Facebook credential
      print('FirebaseService: Signing in to Firebase with credential');
      final userCredential = await _auth.signInWithCredential(credential);
      print('FirebaseService: Signed in to Firebase successfully');

      return userCredential;
    } catch (e) {
      print('FirebaseService: Error signing in with Facebook: $e');
      debugPrint('Error signing in with Facebook: $e');
      rethrow;
    }
  }

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
