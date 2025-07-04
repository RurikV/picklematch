import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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
    QuerySnapshot snapshot = await _firestore.collection('locations').get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
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
    List<String> defaultLocations = [
      "Tondiraba Indoor", 
      "Tondiraba Outdoor", 
      "Koorti", 
      "Golden Club", 
      "Pirita"
    ];

    List<Map<String, dynamic>> existingLocations = await getAllLocations();
    Set<String> existingNames = existingLocations.map((loc) => loc['name'] as String).toSet();

    for (String name in defaultLocations) {
      if (!existingNames.contains(name)) {
        await addLocation(name);
      }
    }
  }

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
