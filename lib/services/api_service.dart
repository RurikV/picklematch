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
        );
      }

      // Return user from Firestore data
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: userData['role'] ?? 'user',
        isActive: userData['active'] ?? false,
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

      final email = firebaseUser.email ?? 'unknown';
      print('ApiService: Google Sign-In successful for user: $email');

      // Get user data from Firestore
      print('ApiService: Getting user data from Firestore');
      final userData = await _firebaseService.getUserData(firebaseUser.uid);

      if (userData == null) {
        print('ApiService: No user data found, creating new user document');
        // Create user document if it doesn't exist (social login users are active by default)
        await _firebaseService.storeUserIfNew(firebaseUser.uid, email, active: true);

        print('ApiService: Returning new user');
        // Return basic user
        return app_models.User(
          uid: firebaseUser.uid,
          email: email,
          role: 'user',
          isActive: true, // Google-authenticated users are considered active
        );
      }

      print('ApiService: Returning existing user');
      // Return user from Firestore data
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: userData['role'] ?? 'user',
        isActive: userData['active'] ?? true,
      );
    } catch (e) {
      print('ApiService: Google login error: $e');
      // For errors, throw the original exception
      throw Exception('Google login error: $e');
    }
  }

  Future<app_models.User> loginWithFacebook() async {
    print('ApiService: loginWithFacebook called');
    try {
      // Sign in with Facebook
      print('ApiService: Calling FirebaseService.signInWithFacebook');
      final userCredential = await _firebaseService.signInWithFacebook();
      print('ApiService: FirebaseService.signInWithFacebook returned');
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('ApiService: No user returned from Facebook Sign-In');
        throw Exception('Failed to login with Facebook: No user returned');
      }

      final email = firebaseUser.email ?? 'unknown';
      print('ApiService: Facebook Sign-In successful for user: $email');

      // Get user data from Firestore
      print('ApiService: Getting user data from Firestore');
      final userData = await _firebaseService.getUserData(firebaseUser.uid);

      if (userData == null) {
        print('ApiService: No user data found, creating new user document');
        // Create user document if it doesn't exist (social login users are active by default)
        await _firebaseService.storeUserIfNew(firebaseUser.uid, email, active: true);

        print('ApiService: Returning new user');
        // Return basic user
        return app_models.User(
          uid: firebaseUser.uid,
          email: email,
          role: 'user',
          isActive: true, // Facebook-authenticated users are considered active
        );
      }

      print('ApiService: Returning existing user');
      // Return user from Firestore data
      return app_models.User(
        uid: firebaseUser.uid,
        email: email,
        role: userData['role'] ?? 'user',
        isActive: userData['active'] ?? true,
      );
    } catch (e) {
      print('ApiService: Facebook login error: $e');
      // For errors, throw the original exception
      throw Exception('Facebook login error: $e');
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
    try {
      List<Map<String, dynamic>> gamesData;

      if (date != null) {
        gamesData = await _firebaseService.getGamesForDate(date);
      } else {
        // If no date is provided, get all games
        // This is a simplification - in a real app, you might want to limit this
        final allDates = await _firebaseService.getAllGameDates();
        gamesData = [];

        for (final dateStr in allDates) {
          final dateGames = await _firebaseService.getGamesForDate(dateStr);
          gamesData.addAll(dateGames);
        }
      }

      // Filter by location if provided
      if (locationId != null) {
        gamesData = gamesData.where((game) => game['location_id'] == locationId).toList();
      }

      // Convert to Game objects
      return gamesData.map((data) {
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
    } catch (e) {
      print('ApiService: Error in _fetchGames: $e');
      print('ApiService: Returning empty games list');
      return [];
    }
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

      // Set user as active in Firestore
      await _firebaseService.setUserActive(currentUser.uid, true);
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
          );
        }

        return app_models.User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? 'unknown',
          role: userData['role'] ?? 'user',
          isActive: userData['active'] ?? false,
        );
      } catch (e) {
        print('Error getting user data: $e');
        return null;
      }
    });
  }
}
