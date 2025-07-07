import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/game.dart';
import '../models/location.dart';
import '../models/player.dart';

class StorageService {
  // Keys for encrypted storage
  static const String _userKey = 'user';
  static const String _tokenKey = 'token';
  static const String _gamesKey = 'games';
  static const String _locationsKey = 'locations';
  static const String _playersKey = 'players';
  static const String _selectedDateKey = 'selected_date';
  static const String _selectedLocationIdKey = 'selected_location_id';
  static const String _themeKey = 'theme';
  static const String _emailForSignInKey = 'email_for_sign_in';

  // Flutter Secure Storage instance
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Secure storage wrapper methods
  Future<void> _setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> _getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> _removeSecureKey(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> _clearAllSecure() async {
    await _secureStorage.deleteAll();
  }


  // Save user data
  Future<void> saveUser(User user) async {
    await _setSecureString(_userKey, jsonEncode(user.toJson()));
  }

  // Get user data
  Future<User?> getUser() async {
    final userJson = await _getSecureString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  // Save auth token
  Future<void> saveToken(String token) async {
    await _setSecureString(_tokenKey, token);
  }

  // Get auth token
  Future<String?> getToken() async {
    return await _getSecureString(_tokenKey);
  }

  // Clear auth data (for logout)
  Future<void> clearAuthData() async {
    await _removeSecureKey(_userKey);
    await _removeSecureKey(_tokenKey);
  }

  // Save games
  Future<void> saveGames(List<Game> games) async {
    final gamesJson = games.map((game) => game.toJson()).toList();
    await _setSecureString(_gamesKey, jsonEncode(gamesJson));
  }

  // Get games
  Future<List<Game>> getGames() async {
    final gamesJson = await _getSecureString(_gamesKey);
    if (gamesJson == null) return [];
    final List<dynamic> gamesData = jsonDecode(gamesJson);
    return gamesData.map((gameData) => Game.fromJson(gameData)).toList();
  }

  // Save locations
  Future<void> saveLocations(List<Location> locations) async {
    print('StorageService: saveLocations called with ${locations.length} locations');
    print('StorageService: Locations to save: ${locations.map((loc) => loc.name).join(', ')}');

    final locationsJson = locations.map((location) => location.toJson()).toList();
    await _setSecureString(_locationsKey, jsonEncode(locationsJson));

    print('StorageService: Locations saved to secure storage');
  }

  // Get locations
  Future<List<Location>> getLocations() async {
    print('StorageService: getLocations called');

    final locationsJson = await _getSecureString(_locationsKey);

    if (locationsJson == null) {
      print('StorageService: No locations found in secure storage');
      return [];
    }

    final List<dynamic> locationsData = jsonDecode(locationsJson);
    final locations = locationsData.map((locationData) => Location.fromJson(locationData)).toList();

    print('StorageService: Retrieved ${locations.length} locations from secure storage');
    print('StorageService: Retrieved locations: ${locations.map((loc) => loc.name).join(', ')}');

    return locations;
  }

  // Save players
  Future<void> savePlayers(Map<String, Player> players) async {
    final Map<String, dynamic> playersJson = {};
    players.forEach((key, player) {
      playersJson[key] = player.toJson();
    });
    await _setSecureString(_playersKey, jsonEncode(playersJson));
  }

  // Get players
  Future<Map<String, Player>> getPlayers() async {
    final playersJson = await _getSecureString(_playersKey);
    if (playersJson == null) return {};
    final Map<String, dynamic> playersData = jsonDecode(playersJson);
    final Map<String, Player> players = {};
    playersData.forEach((key, value) {
      players[key] = Player.fromJson({...value, 'uid': key});
    });
    return players;
  }

  // Save selected date
  Future<void> saveSelectedDate(DateTime date) async {
    await _setSecureString(_selectedDateKey, date.toIso8601String());
  }

  // Get selected date
  Future<DateTime?> getSelectedDate() async {
    final dateString = await _getSecureString(_selectedDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  // Save selected location ID
  Future<void> saveSelectedLocationId(String? locationId) async {
    if (locationId != null) {
      await _setSecureString(_selectedLocationIdKey, locationId);
    } else {
      await _removeSecureKey(_selectedLocationIdKey);
    }
  }

  // Get selected location ID
  Future<String?> getSelectedLocationId() async {
    return await _getSecureString(_selectedLocationIdKey);
  }

  // Save theme preference
  Future<void> saveTheme(String theme) async {
    await _setSecureString(_themeKey, theme);
  }

  // Get theme preference
  Future<String?> getTheme() async {
    return await _getSecureString(_themeKey);
  }

  // Save email for sign-in with email link
  Future<void> saveEmailForSignIn(String email) async {
    await _setSecureString(_emailForSignInKey, email);
  }

  // Get email for sign-in with email link
  Future<String?> getEmailForSignIn() async {
    return await _getSecureString(_emailForSignInKey);
  }

  // Clear email for sign-in
  Future<void> clearEmailForSignIn() async {
    await _removeSecureKey(_emailForSignInKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _clearAllSecure();
  }
}
