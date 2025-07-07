import 'dart:isolate';
import 'dart:math';
import '../models/player.dart';
import '../models/game.dart';

class TournamentMatchingService {
  static Future<List<Team>> generateTeams(List<Player> players) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _generateTeamsIsolate,
      {
        'sendPort': receivePort.sendPort,
        'players': players.map((p) => p.toJson()).toList(),
      },
    );

    final result = await receivePort.first as List<Map<String, dynamic>>;
    receivePort.close();
    
    return result.map((teamJson) => Team.fromJson(teamJson)).toList();
  }

  static void _generateTeamsIsolate(Map<String, dynamic> params) {
    final SendPort sendPort = params['sendPort'];
    final List<dynamic> playersJson = params['players'];
    
    try {
      final players = playersJson
          .map((json) => Player.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final teams = _createBalancedTeams(players);
      final teamsJson = teams.map((team) => team.toJson()).toList();
      
      sendPort.send(teamsJson);
    } catch (e) {
      sendPort.send(<Map<String, dynamic>>[]);
    }
  }

  static List<Team> _createBalancedTeams(List<Player> players) {
    // Filter out players without ratings and sort by rating
    final playersWithRatings = players
        .where((player) => player.rating != null)
        .toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    
    final playersWithoutRatings = players
        .where((player) => player.rating == null)
        .toList();

    // If we don't have enough players for teams, return empty list
    if (playersWithRatings.length + playersWithoutRatings.length < 4) {
      return [];
    }

    final teams = <Team>[];
    final usedPlayers = <String>{};

    // Strategy 1: Create balanced teams by pairing high and low rated players
    final balancedTeams = _createRatingBalancedTeams(
      playersWithRatings, 
      usedPlayers
    );
    teams.addAll(balancedTeams);

    // Strategy 2: Handle remaining players with ratings
    final remainingRatedPlayers = playersWithRatings
        .where((player) => !usedPlayers.contains(player.uid))
        .toList();
    
    final additionalTeams = _createTeamsFromRemainingPlayers(
      remainingRatedPlayers,
      playersWithoutRatings,
      usedPlayers,
    );
    teams.addAll(additionalTeams);

    return teams;
  }

  static List<Team> _createRatingBalancedTeams(
    List<Player> sortedPlayers,
    Set<String> usedPlayers,
  ) {
    final teams = <Team>[];
    final playersList = List<Player>.from(sortedPlayers);
    
    while (playersList.length >= 4) {
      // Take highest rated player
      final highPlayer1 = playersList.removeAt(0);
      usedPlayers.add(highPlayer1.uid);
      
      // Take lowest rated player to balance
      final lowPlayer1 = playersList.removeLast();
      usedPlayers.add(lowPlayer1.uid);
      
      // Create first team
      final team1 = Team(
        player1: highPlayer1.uid,
        player2: lowPlayer1.uid,
      );
      
      if (playersList.length >= 2) {
        // Take next highest rated player
        final highPlayer2 = playersList.removeAt(0);
        usedPlayers.add(highPlayer2.uid);
        
        // Take next lowest rated player
        final lowPlayer2 = playersList.removeLast();
        usedPlayers.add(lowPlayer2.uid);
        
        // Create second team
        final team2 = Team(
          player1: highPlayer2.uid,
          player2: lowPlayer2.uid,
        );
        
        teams.addAll([team1, team2]);
      } else {
        // Put the single team back for later processing
        usedPlayers.remove(highPlayer1.uid);
        usedPlayers.remove(lowPlayer1.uid);
        playersList.insert(0, highPlayer1);
        playersList.add(lowPlayer1);
        break;
      }
    }
    
    return teams;
  }

  static List<Team> _createTeamsFromRemainingPlayers(
    List<Player> remainingRatedPlayers,
    List<Player> playersWithoutRatings,
    Set<String> usedPlayers,
  ) {
    final teams = <Team>[];
    final allRemainingPlayers = [
      ...remainingRatedPlayers,
      ...playersWithoutRatings,
    ];
    
    // Shuffle players without ratings for random distribution
    final random = Random();
    final shuffledUnratedPlayers = List<Player>.from(playersWithoutRatings)
      ..shuffle(random);
    
    // Create teams from remaining players
    for (int i = 0; i < allRemainingPlayers.length - 1; i += 2) {
      if (!usedPlayers.contains(allRemainingPlayers[i].uid) &&
          !usedPlayers.contains(allRemainingPlayers[i + 1].uid)) {
        
        final team = Team(
          player1: allRemainingPlayers[i].uid,
          player2: allRemainingPlayers[i + 1].uid,
        );
        
        teams.add(team);
        usedPlayers.add(allRemainingPlayers[i].uid);
        usedPlayers.add(allRemainingPlayers[i + 1].uid);
      }
    }
    
    return teams;
  }

  /// Calculate team average rating for balancing
  static double _calculateTeamRating(Team team, Map<String, Player> playerMap) {
    final player1Rating = playerMap[team.player1]?.rating ?? 0.0;
    final player2Rating = playerMap[team.player2]?.rating ?? 0.0;
    return (player1Rating + player2Rating) / 2;
  }

  /// Generate games from teams with time slots and courts
  static List<Map<String, dynamic>> generateGamesFromTeams(
    List<Team> teams,
    List<String> timeSlots,
    int numberOfCourts,
    String tournamentId,
  ) {
    final games = <Map<String, dynamic>>[];
    final random = Random();
    
    // Create all possible team matchups
    final matchups = <List<Team>>[];
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matchups.add([teams[i], teams[j]]);
      }
    }
    
    // Shuffle matchups for variety
    matchups.shuffle(random);
    
    int gameIndex = 0;
    for (final timeSlot in timeSlots) {
      for (int court = 1; court <= numberOfCourts; court++) {
        if (gameIndex < matchups.length) {
          final matchup = matchups[gameIndex];
          games.add({
            'id': 'game_${tournamentId}_${timeSlot}_$court',
            'tournament_id': tournamentId,
            'time_slot': timeSlot,
            'court_number': court,
            'team1': matchup[0].toJson(),
            'team2': matchup[1].toJson(),
            'status': 'scheduled',
          });
          gameIndex++;
        }
      }
    }
    
    return games;
  }
}