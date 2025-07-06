import 'dart:isolate';
import '../models/user.dart' as app_models;
import '../models/player.dart';
import '../models/game.dart';
import '../models/location.dart';
import 'firebase_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Firebase service
  final FirebaseService _firebaseService = FirebaseService();

  // Run a task in an isolate
  Future<T> _runInIsolate<T>(Function task, List<dynamic> args) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_isolateFunction, [receivePort.sendPort, task, args]);
    return await receivePort.first as T;
  }

  // Isolate function
  static void _isolateFunction(List<dynamic> args) {
    final SendPort sendPort = args[0];
    final Function task = args[1];
    final List<dynamic> taskArgs = args[2];

    try {
      // Apply the function to get the result
      final result = Function.apply(task, taskArgs);

      // Check if the result is a Future
      if (result is Future) {
        // For async functions, we need to handle the Future differently
        // We can't send the Future directly across isolates
        print('ApiService: Result is a Future, this is not supported in isolates');
        sendPort.send(null);
      } else {
        // For synchronous functions, we can send the result directly
        sendPort.send(result);
      }
    } catch (e) {
      print('ApiService: Error in isolate: $e');
      sendPort.send(null);
    }
  }

  // Initialize Firebase
  Future<void> initialize() async {
    await _firebaseService.initialize();
  }

  // Authentication methods
  Future<app_models.User> login(String email, String password) async {
    try {
      // Sign in with Firebase
      final userCredential = await _firebaseService.signInWithEmailAndPassword(email, password);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to login: No user returned');
      }

      // Get user data from Firestore
      final userData = await _firebaseService.getUserData(firebaseUser.uid);

      if (userData == null) {
        // Create user document if it doesn't exist
        await _firebaseService.storeUserIfNew(firebaseUser.uid, email);

        // Return basic user
        return app_models.User(
          uid: firebaseUser.uid,
          email: email,
          role: 'user',
          isActive: firebaseUser.emailVerified,
          rating: 1000.0, // Default rating for new users
          name: email.split('@').first, // Use the part before @ as the name
        );
      }

      // Return user from Firestore data
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: userData['role'] ?? 'user',
        isActive: userData['active'] ?? false,
        rating: userData['rating'] != null ? double.parse(userData['rating'].toString()) : 1000.0,
        name: userData['name'] ?? email.split('@').first,
      );
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<app_models.User> loginWithGoogle() async {
    print('ApiService: loginWithGoogle called');
    try {
      // Sign in with Google
      print('ApiService: Calling FirebaseService.signInWithGoogle');
      final userCredential = await _firebaseService.signInWithGoogle();
      print('ApiService: FirebaseService.signInWithGoogle returned');
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('ApiService: No user returned from Google Sign-In');
        throw Exception('Failed to login with Google: No user returned');
      }

      // Get the email from the user object
      String email = firebaseUser.email ?? 'unknown';
      print('ApiService: User email: $email');

      // Get user data from Firestore
      print('ApiService: Getting user data from Firestore');
      final userData = await _firebaseService.getUserData(firebaseUser.uid);

      if (userData == null) {
        print('ApiService: No user data found in Firestore, this should not happen as we store user data during sign-in');
        print('ApiService: Attempting to store user data again');

        // Try to store user data again
        try {
          await _firebaseService.storeUserIfNew(firebaseUser.uid, email, active: true);
          print('ApiService: Successfully stored user in Firestore');

          // Try to get user data again
          final retryUserData = await _firebaseService.getUserData(firebaseUser.uid);

          if (retryUserData != null) {
            print('ApiService: Successfully retrieved user data after retry');
            return app_models.User(
              uid: firebaseUser.uid,
              email: email,
              role: retryUserData['role'] ?? 'user',
              isActive: retryUserData['active'] ?? true,
              rating: retryUserData['rating'] != null ? double.parse(retryUserData['rating'].toString()) : 1000.0,
              name: retryUserData['name'] ?? email.split('@').first,
            );
          }
        } catch (firestoreError) {
          print('ApiService: Failed to store user in Firestore: $firestoreError');
        }

        // If we still don't have user data, create a basic user object
        print('ApiService: Creating basic user object from Firebase Auth data');
        return app_models.User(
          uid: firebaseUser.uid,
          email: email,
          role: 'user',
          isActive: true,
          rating: 1000.0,
          name: firebaseUser.displayName ?? email.split('@').first,
        );
      }

      print('ApiService: Returning user with data from Firestore');
      // Return user from Firestore data
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: userData['role'] ?? 'user',
        isActive: userData['active'] ?? true,
        rating: userData['rating'] != null ? double.parse(userData['rating'].toString()) : 1000.0,
        name: userData['name'] ?? email.split('@').first,
      );
    } catch (e) {
      print('ApiService: Google login error: $e');
      print('ApiService: Error type: ${e.runtimeType}');
      print('ApiService: Full error details: ${e.toString()}');

      // Extract the most user-friendly error message
      String errorMessage = 'Google login failed';

      // Check for specific error types and provide more detailed messages
      if (e.toString().contains('Network error')) {
        errorMessage = 'Network error during sign-in. Please check your internet connection.';
        print('ApiService: Detected network error');
      } else if (e.toString().contains('canceled by the user')) {
        errorMessage = 'Sign-in was canceled. Please try again.';
        print('ApiService: Detected user cancellation');
      } else if (e.toString().contains('already linked')) {
        errorMessage = 'This account is already linked to another user.';
        print('ApiService: Detected account already linked');
      } else if (e.toString().contains('Invalid')) {
        errorMessage = 'Invalid credentials. Please try again.';
        print('ApiService: Detected invalid credentials');
      } else if (e.toString().contains('ApiException: 10')) {
        errorMessage = 'Developer error: The application is misconfigured. Please contact support.';
        print('ApiService: Detected ApiException with error code 10');
        print('ApiService: This is likely due to a configuration issue with the Google Sign-In setup.');
        print('ApiService: Check the package name in google-services.json and SHA-1 fingerprint in Firebase console.');
      } else if (e.toString().contains('ApiException')) {
        // Try to extract error code for other API exceptions
        final errorString = e.toString();
        final codeMatch = RegExp(r'ApiException: (\d+)').firstMatch(errorString);
        if (codeMatch != null) {
          final errorCode = codeMatch.group(1);
          print('ApiService: Detected ApiException with error code: $errorCode');
          errorMessage = 'Google Sign-In API error (code $errorCode). Please try again or contact support.';
        } else {
          print('ApiService: Detected ApiException but could not extract error code');
          errorMessage = 'Google Sign-In API error. Please try again or contact support.';
        }
      } else if (e.toString().contains('Unknown calling package name')) {
        errorMessage = 'Authentication configuration issue. Please contact support.';
        print('ApiService: Detected "Unknown calling package name" error');
        print('ApiService: This is likely due to a mismatch between the package name in google-services.json and the actual package name used by the app.');
      } else if (e.toString().contains('FirebaseAuth')) {
        errorMessage = 'Firebase authentication error. Please try again or contact support.';
        print('ApiService: Detected FirebaseAuth error');
      }

      print('ApiService: User-friendly error message: $errorMessage');

      // For other errors, throw a user-friendly exception
      throw Exception('Google login error: $errorMessage');
    }
  }

  // Facebook authentication removed as per requirements

  Future<void> sendEmailLink(String email) async {
    print('ApiService: sendEmailLink called for email: $email');
    try {
      // Send email link
      await _firebaseService.sendSignInLinkToEmail(email);

      // Store the email locally to be used when completing sign-in
      // This would typically be done in a storage service
      // For simplicity, we'll assume this is handled elsewhere

      print('ApiService: Email link sent successfully');
    } catch (e) {
      print('ApiService: Error sending email link: $e');
      throw Exception('Error sending email link: $e');
    }
  }

  Future<app_models.User> loginWithEmailLink(String email, String emailLink) async {
    print('ApiService: loginWithEmailLink called');
    try {
      // Sign in with email link
      print('ApiService: Calling FirebaseService.signInWithEmailLink');
      final userCredential = await _firebaseService.signInWithEmailLink(email, emailLink);
      print('ApiService: FirebaseService.signInWithEmailLink returned');
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('ApiService: No user returned from Email Link Sign-In');
        throw Exception('Failed to login with Email Link: No user returned');
      }

      print('ApiService: Email Link Sign-In successful for user: $email');

      // Get user data from Firestore
      print('ApiService: Getting user data from Firestore');
      final userData = await _firebaseService.getUserData(firebaseUser.uid);

      if (userData == null) {
        print('ApiService: No user data found, creating new user document');
        // Create user document if it doesn't exist (email link users are active by default)
        await _firebaseService.storeUserIfNew(firebaseUser.uid, email, active: true);

        print('ApiService: Returning new user');
        // Return basic user
        return app_models.User(
          uid: firebaseUser.uid,
          email: email,
          role: 'user',
          isActive: true, // Email link authenticated users are considered active
          rating: 1000.0, // Default rating for new users
          name: email.split('@').first, // Use the part before @ as the name
        );
      }

      print('ApiService: Returning existing user');
      // Return user from Firestore data
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: userData['role'] ?? 'user',
        isActive: userData['active'] ?? true,
        rating: userData['rating'] != null ? double.parse(userData['rating'].toString()) : 1000.0,
        name: userData['name'] ?? email.split('@').first,
      );
    } catch (e) {
      print('ApiService: Email link login error: $e');
      throw Exception('Email link login error: $e');
    }
  }

  Future<void> logout(String token) async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      throw Exception('Logout error: $e');
    }
  }

  Future<app_models.User> register(String email, String password) async {
    try {
      // Create user with Firebase
      final userCredential = await _firebaseService.createUserWithEmailAndPassword(email, password);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to register: No user returned');
      }

      // Send verification email
      await _firebaseService.sendEmailVerification();

      // Store user in Firestore
      await _firebaseService.storeUserIfNew(firebaseUser.uid, email, active: false);

      // Return user
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: 'user',
        isActive: false,
        rating: 1000.0, // Default rating for new users
        name: email.split('@').first, // Use the part before @ as the name
      );
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  // Game methods
  Future<List<Game>> getGames(String token, {String? date, String? locationId}) async {
    try {
      // Direct call instead of using isolate
      print('ApiService: Calling _fetchGames directly without isolate');
      return await _fetchGames(date, locationId);
    } catch (e) {
      print('ApiService: Error in getGames: $e');
      throw Exception('Error fetching games: $e');
    }
  }

  Future<List<Game>> _fetchGames(String? date, String? locationId) async {
    print('ApiService: _fetchGames called with date: $date, locationId: $locationId');

    List<Map<String, dynamic>> gamesData;

    if (date != null) {
      print('ApiService: Fetching games for specific date: $date');
      gamesData = await _firebaseService.getGamesForDate(date);
    } else {
      print('ApiService: Fetching all games (no date specified)');
      // If no date is provided, get all games
      // This is a simplification - in a real app, you might want to limit this
      final allDates = await _firebaseService.getAllGameDates();
      gamesData = [];

      for (final dateStr in allDates) {
        final dateGames = await _firebaseService.getGamesForDate(dateStr);
        gamesData.addAll(dateGames);
      }
    }

    print('ApiService: Retrieved ${gamesData.length} games from Firebase');

    // Filter by location if provided
    if (locationId != null) {
      print('ApiService: Filtering games by location: $locationId');
      final originalCount = gamesData.length;
      gamesData = gamesData.where((game) => game['location_id'] == locationId).toList();
      print('ApiService: After location filter: ${gamesData.length} games (was $originalCount)');
    }

    // Convert to Game objects
    print('ApiService: Converting ${gamesData.length} games to Game objects');
    final games = gamesData.map((data) {
      // Convert Firestore data format to our Game model format
      final gameData = {
        'id': data['id'],
        'time': data['time'],
        'location_id': data['location_id'],
        'team1': data['team1'],
        'team2': data['team2'],
        'team1_score1': data['team1_score1'],
        'team1_score2': data['team1_score2'],
        'team2_score1': data['team2_score1'],
        'team2_score2': data['team2_score2'],
        'date': data['date'],
      };

      return Game.fromJson(gameData);
    }).toList();

    print('ApiService: Successfully converted to ${games.length} Game objects');
    return games;
  }

  Future<Game> createGame(String token, Game game) async {
    try {
      // Extract game data
      final dateStr = '${game.date.year}-${game.date.month.toString().padLeft(2, '0')}-${game.date.day.toString().padLeft(2, '0')}';

      // Create game in Firestore
      final gameId = await _firebaseService.addGame(
        dateStr,
        game.time,
        game.locationId,
      );

      // Return the created game with the new ID
      return game.copyWith(id: gameId);
    } catch (e) {
      throw Exception('Error creating game: $e');
    }
  }

  Future<Game> updateGameResult(
    String token,
    String gameId,
    int team1Score1,
    int team1Score2,
    int team2Score1,
    int team2Score2,
  ) async {
    try {
      // Update game scores in Firestore
      await _firebaseService.updateGameScore(
        gameId,
        team1Score1,
        team1Score2,
        team2Score1,
        team2Score2,
      );

      // Get the updated game
      final games = await getGames(token, date: null);
      final updatedGame = games.firstWhere((g) => g.id == gameId);

      return updatedGame;
    } catch (e) {
      throw Exception('Error updating game result: $e');
    }
  }

  Future<Game> joinGame(String token, String gameId, String team) async {
    try {
      // Get current user
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Register for game in Firestore
      await _firebaseService.registerForGame(
        gameId,
        team,
        currentUser.uid,
        currentUser.email ?? 'unknown',
      );

      // Get the updated game
      final games = await getGames(token, date: null);
      final updatedGame = games.firstWhere((g) => g.id == gameId);

      return updatedGame;
    } catch (e) {
      throw Exception('Error joining game: $e');
    }
  }

  Future<void> deleteGame(String token, String gameId) async {
    try {
      await _firebaseService.deleteGame(gameId);
    } catch (e) {
      throw Exception('Error deleting game: $e');
    }
  }

  Future<Game> removePlayerFromGame(String token, String gameId, String team, String playerPosition) async {
    try {
      // Remove player from Firestore
      await _firebaseService.removePlayerFromGame(gameId, team, playerPosition);

      // Get the updated game
      final games = await getGames(token, date: null);
      final updatedGame = games.firstWhere((g) => g.id == gameId);

      return updatedGame;
    } catch (e) {
      throw Exception('Error removing player from game: $e');
    }
  }

  // Location methods
  Future<List<Location>> getLocations(String token) async {
    try {
      print('ApiService: getLocations called');

      // Initialize default locations if needed
      print('ApiService: Initializing default locations');
      await _firebaseService.initializeDefaultLocations();

      // Get locations from Firestore
      print('ApiService: Getting locations from Firestore');
      final locationsData = await _firebaseService.getAllLocations();
      print('ApiService: Got ${locationsData.length} locations from Firestore');

      // Convert to Location objects
      final locations = locationsData.map((data) {
        return Location(
          id: data['id'],
          name: data['name'],
          address: data['address'],
          description: data['description'],
        );
      }).toList();

      print('ApiService: Returning ${locations.length} locations: ${locations.map((loc) => loc.name).join(', ')}');
      return locations;
    } catch (e) {
      print('ApiService: Error fetching locations: $e');
      print('ApiService: Falling back to default locations');
      return _getDefaultLocations();
    }
  }

  // Get default locations when Firestore access fails
  List<Location> _getDefaultLocations() {
    print('ApiService: Creating default locations');
    final defaultLocations = [
      Location(id: 'default-1', name: 'Tondiraba Indoor', address: '123 Main St', description: 'Indoor courts'),
      Location(id: 'default-2', name: 'Tondiraba Outdoor', address: '123 Main St', description: 'Outdoor courts'),
      Location(id: 'default-3', name: 'Koorti', address: '456 Park Ave', description: 'Premium courts'),
      Location(id: 'default-4', name: 'Golden Club', address: '789 Oak St', description: 'Club courts'),
      Location(id: 'default-5', name: 'Pirita', address: '321 Beach Rd', description: 'Beach courts'),
    ];
    print('ApiService: Created ${defaultLocations.length} default locations: ${defaultLocations.map((loc) => loc.name).join(', ')}');
    return defaultLocations;
  }

  // Player methods
  Future<Map<String, Player>> getPlayers(String token) async {
    try {
      // Direct call instead of using isolate
      print('ApiService: Calling _fetchPlayers directly without isolate');
      return await _fetchPlayers();
    } catch (e) {
      print('ApiService: Error in getPlayers: $e');
      throw Exception('Error fetching players: $e');
    }
  }

  Future<Map<String, Player>> _fetchPlayers() async {
    try {
      // Get all users from Firestore
      final usersData = await _firebaseService.getAllUsers();
      final Map<String, Player> players = {};

      usersData.forEach((uid, userData) {
        players[uid] = Player(
          uid: uid,
          email: userData['email'],
          rating: userData['rating'] != null ? double.parse(userData['rating'].toString()) : null,
          active: userData['active'] ?? false,
        );
      });

      return players;
    } catch (e) {
      throw Exception('Failed to fetch players: $e');
    }
  }

  // Verify email
  Future<void> verifyEmail(String token) async {
    try {
      // Get current user
      final currentUser = _firebaseService.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      try {
        // Try to set user as active in Firestore
        await _firebaseService.setUserActive(currentUser.uid, true);
      } catch (firestoreError) {
        // If Firestore update fails, log the error but don't throw an exception
        // This allows the verification process to continue even if Firestore access fails
        print('ApiService: Error updating user active status in Firestore: $firestoreError');
        print('ApiService: Continuing with verification process despite Firestore error');
      }

      // Return successfully even if Firestore update failed
      // This ensures the verification process completes and the user can proceed
      print('ApiService: Email verification completed successfully');
    } catch (e) {
      throw Exception('Error verifying email: $e');
    }
  }

  // Get auth state changes stream
  Stream<app_models.User?> get authStateChanges {
    return _firebaseService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      try {
        // Get user data from Firestore
        final userData = await _firebaseService.getUserData(firebaseUser.uid);

        if (userData == null) {
          return app_models.User(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? 'unknown',
            role: 'user',
            isActive: firebaseUser.emailVerified,
            rating: 1000.0, // Default rating for new users
            name: (firebaseUser.email ?? 'unknown').split('@').first, // Use the part before @ as the name
          );
        }

        return app_models.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? 'unknown',
          role: userData['role'] ?? 'user',
          isActive: userData['active'] ?? false,
          rating: userData['rating'] != null ? double.parse(userData['rating'].toString()) : 1000.0,
          name: userData['name'] ?? (firebaseUser.email ?? 'unknown').split('@').first,
        );
      } catch (e) {
        print('Error getting user data: $e');
        return null;
      }
    });
  }
}
