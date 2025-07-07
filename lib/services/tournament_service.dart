import 'dart:convert';
import '../models/tournament.dart';
import '../models/player.dart';
import '../models/user.dart';
import '../models/location.dart';
import 'tournament_matching_isolate.dart';
import 'firebase_service.dart';

class TournamentService {
  final FirebaseService _firebaseService;

  TournamentService(this._firebaseService);

  /// Create a new tournament (admin only)
  Future<Tournament?> createTournament({
    required String name,
    required String description,
    required String locationId,
    required DateTime date,
    required List<String> timeSlots,
    required int numberOfCourts,
    required String adminUserId,
    double? minRating,
    double? maxRating,
  }) async {
    try {
      // Verify user is admin
      final user = await _firebaseService.getUser(adminUserId);
      if (user?.role != 'admin') {
        throw Exception('Only admin users can create tournaments');
      }

      final tournament = Tournament(
        id: 'tournament_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        locationId: locationId,
        date: date,
        timeSlots: timeSlots,
        numberOfCourts: numberOfCourts,
        createdBy: adminUserId,
        createdAt: DateTime.now(),
        minRating: minRating,
        maxRating: maxRating,
      );

      final success = await _firebaseService.saveTournament(tournament);
      return success ? tournament : null;
    } catch (e) {
      print('Error creating tournament: $e');
      return null;
    }
  }

  /// Get all tournaments
  Future<List<Tournament>> getAllTournaments() async {
    try {
      return await _firebaseService.getAllTournaments();
    } catch (e) {
      print('Error getting tournaments: $e');
      return [];
    }
  }

  /// Get tournament by ID
  Future<Tournament?> getTournament(String tournamentId) async {
    try {
      return await _firebaseService.getTournament(tournamentId);
    } catch (e) {
      print('Error getting tournament: $e');
      return null;
    }
  }

  /// Get tournaments created by a specific admin
  Future<List<Tournament>> getTournamentsByAdmin(String adminUserId) async {
    try {
      final tournaments = await _firebaseService.getAllTournaments();
      return tournaments.where((t) => t.createdBy == adminUserId).toList();
    } catch (e) {
      print('Error getting tournaments by admin: $e');
      return [];
    }
  }

  /// Get open tournaments that a player can register for
  Future<List<Tournament>> getOpenTournaments(String playerId) async {
    try {
      final tournaments = await _firebaseService.getAllTournaments();
      final player = await _firebaseService.getPlayer(playerId);
      
      return tournaments.where((tournament) {
        return tournament.status == TournamentStatus.open &&
               tournament.canRegister(player?.rating) &&
               !tournament.registeredPlayers.contains(playerId);
      }).toList();
    } catch (e) {
      print('Error getting open tournaments: $e');
      return [];
    }
  }

  /// Register a player for a tournament
  Future<bool> registerPlayer(String tournamentId, String playerId) async {
    try {
      final tournament = await _firebaseService.getTournament(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      final player = await _firebaseService.getPlayer(playerId);
      if (player == null) {
        throw Exception('Player not found');
      }

      // Check if player can register
      if (!tournament.canRegister(player.rating)) {
        throw Exception('Player cannot register for this tournament');
      }

      // Check if player is already registered
      if (tournament.registeredPlayers.contains(playerId)) {
        throw Exception('Player is already registered');
      }

      // Add player to tournament
      final updatedTournament = tournament.copyWith(
        registeredPlayers: [...tournament.registeredPlayers, playerId],
      );

      return await _firebaseService.saveTournament(updatedTournament);
    } catch (e) {
      print('Error registering player: $e');
      return false;
    }
  }

  /// Unregister a player from a tournament
  Future<bool> unregisterPlayer(String tournamentId, String playerId) async {
    try {
      final tournament = await _firebaseService.getTournament(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      if (tournament.status != TournamentStatus.open) {
        throw Exception('Cannot unregister from closed tournament');
      }

      final updatedPlayers = tournament.registeredPlayers
          .where((id) => id != playerId)
          .toList();

      final updatedTournament = tournament.copyWith(
        registeredPlayers: updatedPlayers,
      );

      return await _firebaseService.saveTournament(updatedTournament);
    } catch (e) {
      print('Error unregistering player: $e');
      return false;
    }
  }

  /// Generate teams and games for a tournament (admin only)
  Future<bool> generateTournamentMatches(String tournamentId, String adminUserId) async {
    try {
      final tournament = await _firebaseService.getTournament(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      // Verify user is admin or tournament creator
      final user = await _firebaseService.getUser(adminUserId);
      if (user?.role != 'admin' && tournament.createdBy != adminUserId) {
        throw Exception('Only admin users can generate matches');
      }

      if (tournament.registeredPlayers.length < 4) {
        throw Exception('Need at least 4 players to generate matches');
      }

      // Get all registered players
      final players = <Player>[];
      for (final playerId in tournament.registeredPlayers) {
        final player = await _firebaseService.getPlayer(playerId);
        if (player != null) {
          players.add(player);
        }
      }

      // Generate teams using the isolate
      final teams = await TournamentMatchingService.generateTeams(players);
      
      if (teams.isEmpty) {
        throw Exception('Could not generate teams from registered players');
      }

      // Generate games from teams
      final gamesJson = TournamentMatchingService.generateGamesFromTeams(
        teams,
        tournament.timeSlots,
        tournament.numberOfCourts,
        tournament.id,
      );

      final tournamentGames = gamesJson
          .map((gameJson) => TournamentGame.fromJson(gameJson))
          .toList();

      // Update tournament with generated games and close registration
      final updatedTournament = tournament.copyWith(
        games: tournamentGames,
        status: TournamentStatus.closed,
      );

      return await _firebaseService.saveTournament(updatedTournament);
    } catch (e) {
      print('Error generating tournament matches: $e');
      return false;
    }
  }

  /// Start a tournament (change status to in progress)
  Future<bool> startTournament(String tournamentId, String adminUserId) async {
    try {
      final tournament = await _firebaseService.getTournament(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      // Verify user is admin or tournament creator
      final user = await _firebaseService.getUser(adminUserId);
      if (user?.role != 'admin' && tournament.createdBy != adminUserId) {
        throw Exception('Only admin users can start tournaments');
      }

      if (tournament.status != TournamentStatus.closed) {
        throw Exception('Tournament must be closed before starting');
      }

      final updatedTournament = tournament.copyWith(
        status: TournamentStatus.inProgress,
      );

      return await _firebaseService.saveTournament(updatedTournament);
    } catch (e) {
      print('Error starting tournament: $e');
      return false;
    }
  }

  /// Complete a tournament
  Future<bool> completeTournament(String tournamentId, String adminUserId) async {
    try {
      final tournament = await _firebaseService.getTournament(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      // Verify user is admin or tournament creator
      final user = await _firebaseService.getUser(adminUserId);
      if (user?.role != 'admin' && tournament.createdBy != adminUserId) {
        throw Exception('Only admin users can complete tournaments');
      }

      final updatedTournament = tournament.copyWith(
        status: TournamentStatus.completed,
      );

      return await _firebaseService.saveTournament(updatedTournament);
    } catch (e) {
      print('Error completing tournament: $e');
      return false;
    }
  }

  /// Cancel a tournament
  Future<bool> cancelTournament(String tournamentId, String adminUserId) async {
    try {
      final tournament = await _firebaseService.getTournament(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      // Verify user is admin or tournament creator
      final user = await _firebaseService.getUser(adminUserId);
      if (user?.role != 'admin' && tournament.createdBy != adminUserId) {
        throw Exception('Only admin users can cancel tournaments');
      }

      final updatedTournament = tournament.copyWith(
        status: TournamentStatus.cancelled,
      );

      return await _firebaseService.saveTournament(updatedTournament);
    } catch (e) {
      print('Error cancelling tournament: $e');
      return false;
    }
  }

  /// Get tournaments a player is registered for
  Future<List<Tournament>> getPlayerTournaments(String playerId) async {
    try {
      final tournaments = await _firebaseService.getAllTournaments();
      return tournaments
          .where((tournament) => tournament.registeredPlayers.contains(playerId))
          .toList();
    } catch (e) {
      print('Error getting player tournaments: $e');
      return [];
    }
  }

  /// Update tournament details (admin only)
  Future<bool> updateTournament(Tournament tournament, String adminUserId) async {
    try {
      // Verify user is admin or tournament creator
      final user = await _firebaseService.getUser(adminUserId);
      if (user?.role != 'admin' && tournament.createdBy != adminUserId) {
        throw Exception('Only admin users can update tournaments');
      }

      return await _firebaseService.saveTournament(tournament);
    } catch (e) {
      print('Error updating tournament: $e');
      return false;
    }
  }
}