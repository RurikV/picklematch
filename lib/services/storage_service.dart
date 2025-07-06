import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/game.dart';
import '../models/location.dart';
import '../models/player.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _userKey = 'user';
  static const String _tokenKey = 'token';
  static const String _gamesKey = 'games';
  static const String _locationsKey = 'locations';
  static const String _playersKey = 'players';
  static const String _selectedDateKey = 'selected_date';
  static const String _selectedLocationIdKey = 'selected_location_id';
  static const String _themeKey = 'theme';
  static const String _emailForSignInKey = 'email_for_sign_in';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Save user data
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get user data
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  // Save auth token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear auth data (for logout)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  // Save games
  Future<void> saveGames(List<Game> games) async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = games.map((game) => game.toJson()).toList();
    await prefs.setString(_gamesKey, jsonEncode(gamesJson));
  }

  // Get games
  Future<List<Game>> getGames() async {
    final prefs = await SharedPreferences.getInstance();
    final gamesJson = prefs.getString(_gamesKey);
    if (gamesJson == null) return [];
    final List<dynamic> gamesData = jsonDecode(gamesJson);
    return gamesData.map((gameData) => Game.fromJson(gameData)).toList();
  }

  // Save locations
  Future<void> saveLocations(List<Location> locations) async {
    print('StorageService: saveLocations called with ${locations.length} locations');
    print('StorageService: Locations to save: ${locations.map((loc) => loc.name).join(', ')}');

    final prefs = await SharedPreferences.getInstance();
    final locationsJson = locations.map((location) => location.toJson()).toList();
    await prefs.setString(_locationsKey, jsonEncode(locationsJson));

    print('StorageService: Locations saved to SharedPreferences');
  }

  // Get locations
  Future<List<Location>> getLocations() async {
    print('StorageService: getLocations called');

    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString(_locationsKey);

    if (locationsJson == null) {
      print('StorageService: No locations found in SharedPreferences');
      return [];
    }

    final List<dynamic> locationsData = jsonDecode(locationsJson);
    final locations = locationsData.map((locationData) => Location.fromJson(locationData)).toList();

    print('StorageService: Retrieved ${locations.length} locations from SharedPreferences');
    print('StorageService: Retrieved locations: ${locations.map((loc) => loc.name).join(', ')}');

    return locations;
  }

  // Save players
  Future<void> savePlayers(Map<String, Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> playersJson = {};
    players.forEach((key, player) {
      playersJson[key] = player.toJson();
    });
    await prefs.setString(_playersKey, jsonEncode(playersJson));
  }

  // Get players
  Future<Map<String, Player>> getPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final playersJson = prefs.getString(_playersKey);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedDateKey, date.toIso8601String());
  }

  // Get selected date
  Future<DateTime?> getSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_selectedDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  // Save selected location ID
  Future<void> saveSelectedLocationId(String? locationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (locationId != null) {
      await prefs.setString(_selectedLocationIdKey, locationId);
    } else {
      await prefs.remove(_selectedLocationIdKey);
    }
  }

  // Get selected location ID
  Future<String?> getSelectedLocationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLocationIdKey);
  }

  // Save theme preference
  Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  // Get theme preference
  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  // Save email for sign-in with email link
  Future<void> saveEmailForSignIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailForSignInKey, email);
  }

  // Get email for sign-in with email link
  Future<String?> getEmailForSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailForSignInKey);
  }

  // Clear email for sign-in
  Future<void> clearEmailForSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailForSignInKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
