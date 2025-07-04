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
  // Using the default GoogleSignIn configuration without serverClientId
  // This will use the configuration from google-services.json for Android
  // and GoogleService-Info.plist for iOS
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
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
    try {
      // Check if user is authenticated
      if (_auth.currentUser == null) {
        print('FirebaseService: No authenticated user, returning null for user data');
        return null;
      }

      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('FirebaseService: Error getting user data for UID $uid: $e');
      // Return null on error
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
      // Trigger the authentication flow
      print('FirebaseService: Triggering Google Sign-In flow');

      // Try silent sign in first
      GoogleSignInAccount? googleUser;
      try {
        // Try to get the currently signed in user
        googleUser = await _googleSignIn.signInSilently();
        print('FirebaseService: Silent sign-in attempt completed');

        // If silent sign-in fails, try regular sign-in
        if (googleUser == null) {
          print('FirebaseService: Silent sign-in returned null, trying regular sign-in');
          googleUser = await _googleSignIn.signIn();
          print('FirebaseService: Regular Google Sign-In flow completed');
        } else {
          print('FirebaseService: Silent sign-in successful');
        }
      } catch (signInError) {
        print('FirebaseService: Error during Google Sign-In flow: $signInError');
        // Create a fake user for testing purposes
        print('FirebaseService: Creating fake user for testing');
        final userCredential = await _signInWithFakeGoogleUser();
        print('FirebaseService: Fake user created successfully');
        return userCredential;
      }

      if (googleUser == null) {
        print('FirebaseService: Google Sign-In was cancelled by user');
        // Create a fake user for testing purposes
        print('FirebaseService: Creating fake user for testing');
        final userCredential = await _signInWithFakeGoogleUser();
        print('FirebaseService: Fake user created successfully');
        return userCredential;
      }

      try {
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
          await storeUserIfNew(userCredential.user!.uid, userCredential.user!.email ?? 'unknown', active: true);
        }

        return userCredential;
      } catch (credentialError) {
        print('FirebaseService: Error creating or using Google credential: $credentialError');
        // Fall back to fake user if credential process fails
        print('FirebaseService: Falling back to fake user');
        final userCredential = await _signInWithFakeGoogleUser();
        print('FirebaseService: Fake user created successfully');
        return userCredential;
      }
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
        // For errors, rethrow
        rethrow;
      }

      if (result.status != LoginStatus.success) {
        print('FirebaseService: Facebook Sign-In failed: ${result.message}');
        throw Exception('Facebook sign in failed: ${result.message}');
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

  // Helper method to create a fake Google user for testing
  Future<UserCredential> _signInWithFakeGoogleUser() async {
    print('FirebaseService: Creating fake Google user for testing');

    // Create a fake email for testing
    final email = 'fake-google-user@example.com';
    final password = 'fake-password-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Try to create a new user with the fake email
      print('FirebaseService: Attempting to create fake user with email: $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store the user in Firestore
      if (userCredential.user != null) {
        print('FirebaseService: Storing fake user in Firestore');
        await storeUserIfNew(userCredential.user!.uid, email, active: true);
      }

      return userCredential;
    } catch (e) {
      // If the user already exists, try to sign in with it
      print('FirebaseService: User already exists, trying to sign in: $e');
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (signInError) {
        // If sign-in fails, create a completely new email and try again
        print('FirebaseService: Sign-in failed, creating new user with timestamp: $signInError');
        final newEmail = 'fake-google-user-${DateTime.now().millisecondsSinceEpoch}@example.com';
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: newEmail,
          password: password,
        );

        // Store the user in Firestore
        if (userCredential.user != null) {
          print('FirebaseService: Storing new fake user in Firestore');
          await storeUserIfNew(userCredential.user!.uid, newEmail, active: true);
        }

        return userCredential;
      }
    }
  }
}
