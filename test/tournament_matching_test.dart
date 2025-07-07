import 'package:flutter_test/flutter_test.dart';
import 'package:picklematch/models/player.dart';
import 'package:picklematch/models/game.dart';
import 'package:picklematch/services/tournament_matching_isolate.dart';

void main() {
  group('Tournament Matching Tests', () {
    test('should create balanced teams from players with ratings', () async {
      // Create test players with different ratings
      final players = [
        Player(uid: 'player1', email: 'player1@test.com', rating: 1500.0, name: 'High Player 1'),
        Player(uid: 'player2', email: 'player2@test.com', rating: 1000.0, name: 'Low Player 1'),
        Player(uid: 'player3', email: 'player3@test.com', rating: 1400.0, name: 'High Player 2'),
        Player(uid: 'player4', email: 'player4@test.com', rating: 1100.0, name: 'Low Player 2'),
        Player(uid: 'player5', email: 'player5@test.com', rating: 1300.0, name: 'Mid Player 1'),
        Player(uid: 'player6', email: 'player6@test.com', rating: 1200.0, name: 'Mid Player 2'),
      ];

      print('[DEBUG_LOG] Testing tournament matching with ${players.length} players');
      for (final player in players) {
        print('[DEBUG_LOG] Player: ${player.name} - Rating: ${player.rating}');
      }

      // Generate teams
      final teams = await TournamentMatchingService.generateTeams(players);

      print('[DEBUG_LOG] Generated ${teams.length} teams');
      for (int i = 0; i < teams.length; i++) {
        final team = teams[i];
        print('[DEBUG_LOG] Team ${i + 1}: Player1=${team.player1}, Player2=${team.player2}');
      }

      // Verify teams were created
      expect(teams.isNotEmpty, true);
      expect(teams.length, greaterThanOrEqualTo(2)); // Should create at least 2 teams from 6 players

      // Verify all teams have 2 players
      for (final team in teams) {
        expect(team.player1, isNotNull);
        expect(team.player2, isNotNull);
        expect(team.isFull, true);
      }

      // Verify no player appears in multiple teams
      final usedPlayers = <String>{};
      for (final team in teams) {
        expect(usedPlayers.contains(team.player1), false, reason: 'Player ${team.player1} appears in multiple teams');
        expect(usedPlayers.contains(team.player2), false, reason: 'Player ${team.player2} appears in multiple teams');
        usedPlayers.add(team.player1!);
        usedPlayers.add(team.player2!);
      }

      print('[DEBUG_LOG] Tournament matching test completed successfully');
    });

    test('should handle players without ratings', () async {
      final players = [
        Player(uid: 'player1', email: 'player1@test.com', rating: 1500.0, name: 'Rated Player 1'),
        Player(uid: 'player2', email: 'player2@test.com', rating: null, name: 'Unrated Player 1'),
        Player(uid: 'player3', email: 'player3@test.com', rating: 1200.0, name: 'Rated Player 2'),
        Player(uid: 'player4', email: 'player4@test.com', rating: null, name: 'Unrated Player 2'),
      ];

      print('[DEBUG_LOG] Testing with mixed rated/unrated players');

      final teams = await TournamentMatchingService.generateTeams(players);

      print('[DEBUG_LOG] Generated ${teams.length} teams from mixed players');

      expect(teams.isNotEmpty, true);
      expect(teams.length, greaterThanOrEqualTo(1));

      // Verify all teams are properly formed
      for (final team in teams) {
        expect(team.player1, isNotNull);
        expect(team.player2, isNotNull);
      }

      print('[DEBUG_LOG] Mixed player test completed successfully');
    });

    test('should return empty list for insufficient players', () async {
      final players = [
        Player(uid: 'player1', email: 'player1@test.com', rating: 1500.0, name: 'Only Player 1'),
        Player(uid: 'player2', email: 'player2@test.com', rating: 1200.0, name: 'Only Player 2'),
      ];

      print('[DEBUG_LOG] Testing with insufficient players (${players.length})');

      final teams = await TournamentMatchingService.generateTeams(players);

      print('[DEBUG_LOG] Generated ${teams.length} teams from insufficient players');

      expect(teams.isEmpty, true, reason: 'Should return empty list when less than 4 players');

      print('[DEBUG_LOG] Insufficient players test completed successfully');
    });

    test('should generate games from teams', () {
      final teams = [
        Team(player1: 'player1', player2: 'player2'),
        Team(player1: 'player3', player2: 'player4'),
        Team(player1: 'player5', player2: 'player6'),
      ];

      final timeSlots = ['09:00', '10:00', '11:00'];
      final numberOfCourts = 2;
      final tournamentId = 'test_tournament';

      print('[DEBUG_LOG] Testing game generation with ${teams.length} teams');

      final games = TournamentMatchingService.generateGamesFromTeams(
        teams,
        timeSlots,
        numberOfCourts,
        tournamentId,
      );

      print('[DEBUG_LOG] Generated ${games.length} games');

      expect(games.isNotEmpty, true);

      // Verify game structure
      for (final game in games) {
        expect(game['id'], isNotNull);
        expect(game['tournament_id'], equals(tournamentId));
        expect(game['time_slot'], isNotNull);
        expect(game['court_number'], isNotNull);
        expect(game['team1'], isNotNull);
        expect(game['team2'], isNotNull);
        expect(game['status'], equals('scheduled'));

        print('[DEBUG_LOG] Game: ${game['id']} - Time: ${game['time_slot']}, Court: ${game['court_number']}');
      }

      print('[DEBUG_LOG] Game generation test completed successfully');
    });
  });
}
