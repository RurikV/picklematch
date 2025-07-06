import '../models/game.dart';

/// Validation rules for game operations
class ValidationRules {
  /// Validates if a player can join a specific team in a game
  /// Returns null if valid, or an error message if invalid
  static String? validatePlayerJoinGame(Game game, String playerId, String team) {
    // Check if the player is already in the game (either team)
    if (_isPlayerInGame(game, playerId)) {
      return 'Player is already part of this game';
    }

    // Check if the specified team is full
    final targetTeam = team == 'team1' ? game.team1 : game.team2;
    if (targetTeam.isFull) {
      return 'Team is already full';
    }

    return null; // Valid to join
  }

  /// Checks if a player is already part of a game (in either team)
  static bool _isPlayerInGame(Game game, String playerId) {
    // Check team1
    if (game.team1.player1 == playerId || game.team1.player2 == playerId) {
      return true;
    }

    // Check team2
    if (game.team2.player1 == playerId || game.team2.player2 == playerId) {
      return true;
    }

    return false;
  }

  /// Validates if a player can create a game
  /// Returns null if valid, or an error message if invalid
  static String? validateGameCreation(DateTime gameDate, String time, String locationId) {
    // Check if the game date is not in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(gameDate.year, gameDate.month, gameDate.day);
    
    if (selectedDate.isBefore(today)) {
      return 'Cannot create games for past dates';
    }

    // Validate time format (basic validation)
    if (time.isEmpty || !RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      return 'Invalid time format. Use HH:MM format';
    }

    // Validate location
    if (locationId.isEmpty) {
      return 'Location must be selected';
    }

    return null; // Valid to create
  }

  /// Validates if a player can update game scores
  /// Returns null if valid, or an error message if invalid
  static String? validateScoreUpdate(Game game, String playerId) {
    // Check if the player is part of the game
    if (!_isPlayerInGame(game, playerId)) {
      return 'Only players in the game can update scores';
    }

    // Check if both teams are full (game should be complete to update scores)
    if (!game.team1.isFull || !game.team2.isFull) {
      return 'Game must have all players before scores can be updated';
    }

    return null; // Valid to update scores
  }

  /// Validates score values
  /// Returns null if valid, or an error message if invalid
  static String? validateScoreValues(int team1Score1, int team1Score2, int team2Score1, int team2Score2) {
    // Check for negative scores
    if (team1Score1 < 0 || team1Score2 < 0 || team2Score1 < 0 || team2Score2 < 0) {
      return 'Scores cannot be negative';
    }

    // Check for reasonable score limits (e.g., max 21 for pickleball)
    const maxScore = 21;
    if (team1Score1 > maxScore || team1Score2 > maxScore || 
        team2Score1 > maxScore || team2Score2 > maxScore) {
      return 'Scores cannot exceed $maxScore';
    }

    return null; // Valid scores
  }

  /// Validates if a player can delete a game
  /// Returns null if valid, or an error message if invalid
  static String? validateGameDeletion(Game game, String playerId, String userRole) {
    // Only admins can delete games
    if (userRole != 'admin') {
      return 'Only administrators can delete games';
    }

    return null; // Valid to delete
  }

  /// Gets a user-friendly error message for common validation scenarios
  static String getJoinGameErrorMessage(Game game, String playerId, String team) {
    final validationResult = validatePlayerJoinGame(game, playerId, team);
    
    if (validationResult != null) {
      return validationResult;
    }

    return 'Unable to join game. Please try again.';
  }
}