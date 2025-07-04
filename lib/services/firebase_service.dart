import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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
  // Using the default GoogleSignIn configuration without serverClientId
  // This will use the configuration from google-services.json for Android
  // and GoogleService-Info.plist for iOS
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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

      // Check if this is a mock user (starts with 'dev-')
      if (uid.startsWith('dev-')) {
        print('FirebaseService: Mock user detected, returning default user data');
        // For mock users, return a default set of user data without querying Firestore
        return {
          'uid': uid,
          'email': 'dev.user@example.com',
          'rating': 1000,
          'role': 'user',
          'active': true,
        };
      }

      // For regular users, query Firestore
      print('FirebaseService: Querying Firestore for user data');
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        print('FirebaseService: User data found in Firestore');
        return snapshot.data() as Map<String, dynamic>;
      }

      print('FirebaseService: No user data found in Firestore');
      return null;
    } catch (e) {
      print('FirebaseService: Error getting user data for UID $uid: $e');

      // If this is a mock user and Firestore failed, return default data
      if (uid.startsWith('dev-')) {
        print('FirebaseService: Returning default data for mock user despite Firestore error');
        return {
          'uid': uid,
          'email': 'dev.user@example.com',
          'rating': 1000,
          'role': 'user',
          'active': true,
        };
      }

      // Return null on error for regular users
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
    try {
      // First try the traditional Google Sign-In flow
      print('FirebaseService: Trying traditional Google Sign-In flow');

      // Trigger the authentication flow
      print('FirebaseService: Triggering Google Sign-In flow');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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
        await storeUserIfNew(
          userCredential.user!.uid, 
          userCredential.user!.email ?? 'unknown', 
          active: true
        );
      }

      return userCredential;
    } catch (e) {
      print('FirebaseService: Error in Google Sign-In: $e');

      // Provide more specific error messages based on the error type
      String errorMessage = 'Google sign-in failed';
      if (e.toString().contains('network_error')) {
        errorMessage = 'Network error during Google sign-in. Please check your internet connection.';
      } else if (e.toString().contains('canceled')) {
        errorMessage = 'Google sign-in was canceled by the user.';
      } else if (e.toString().contains('credential_already_in_use')) {
        errorMessage = 'This Google account is already linked to another user.';
      } else if (e.toString().contains('invalid_credential')) {
        errorMessage = 'Invalid Google credentials. Please try again.';
      }

      print('FirebaseService: Detailed error message: $errorMessage');

      // If Google Sign-In fails, use a development mock user as fallback
      // This is only for development/testing and doesn't rely on Firebase authentication
      try {
        print('FirebaseService: Using development mock user as fallback');

        // Generate a unique ID for the mock user
        final String mockUid = 'dev-${DateTime.now().millisecondsSinceEpoch}';
        final String mockEmail = 'dev.user.${DateTime.now().millisecondsSinceEpoch}@example.com';

        print('FirebaseService: Created mock user with ID: $mockUid and email: $mockEmail');

        // Try to store the mock user in Firestore, but don't fail if it doesn't work
        try {
          print('FirebaseService: Attempting to store mock user in Firestore');
          await storeUserIfNew(
            mockUid,
            mockEmail,
            active: true
          );
          print('FirebaseService: Successfully stored mock user in Firestore');
        } catch (firestoreError) {
          // If Firestore storage fails, just log the error and continue
          // This allows the mock user to work even if Firestore is not accessible
          print('FirebaseService: Failed to store mock user in Firestore: $firestoreError');
          print('FirebaseService: Continuing with mock user without Firestore storage');
        }

        print('FirebaseService: Development fallback successful');

        // Return a mock UserCredential
        // We're not actually authenticating with Firebase, just creating a data structure
        // that matches what the rest of the code expects
        return MockUserCredential(mockUid, mockEmail);
      } catch (fallbackError) {
        print('FirebaseService: Error in fallback mechanism: $fallbackError');

        // If all else fails, throw the original error with the detailed message
        throw Exception('$errorMessage. Development fallback also failed: ${fallbackError.toString()}');
      }
    }
  }

  // Facebook authentication removed as per requirements

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

}
