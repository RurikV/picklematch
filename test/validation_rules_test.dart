import 'package:flutter_test/flutter_test.dart';
import 'package:picklematch/models/game.dart';
import 'package:picklematch/utils/validation_rules.dart';

void main() {
  group('ValidationRules Tests', () {
    late Game testGame;

    setUp(() {
      testGame = Game(
        id: 'test-game-1',
        time: '14:30',
        locationId: 'location-1',
        team1: Team(player1: 'player1@example.com', player2: null),
        team2: Team(player1: null, player2: null),
        date: DateTime.now().add(Duration(days: 1)), // Tomorrow
      );
    });

    test('should allow player to join empty team slot', () {
      final result = ValidationRules.validatePlayerJoinGame(
        testGame,
        'newplayer@example.com',
        'team1',
      );

      expect(result, isNull); // No error means valid
    });

    test('should prevent player from joining same game twice', () {
      final result = ValidationRules.validatePlayerJoinGame(
        testGame,
        'player1@example.com', // Already in team1
        'team2',
      );

      expect(result, equals('Player is already part of this game'));
    });

    test('should prevent joining full team', () {
      final fullTeamGame = testGame.copyWith(
        team1: Team(player1: 'player1@example.com', player2: 'player2@example.com'),
      );

      final result = ValidationRules.validatePlayerJoinGame(
        fullTeamGame,
        'newplayer@example.com',
        'team1',
      );

      expect(result, equals('Team is already full'));
    });

    test('should validate game creation for future dates', () {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final result = ValidationRules.validateGameCreation(
        tomorrow,
        '14:30',
        'location-1',
      );

      expect(result, isNull); // Valid
    });

    test('should reject game creation for past dates', () {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final result = ValidationRules.validateGameCreation(
        yesterday,
        '14:30',
        'location-1',
      );

      expect(result, equals('Cannot create games for past dates'));
    });

    test('should validate score values within limits', () {
      final result = ValidationRules.validateScoreValues(11, 9, 8, 11);

      expect(result, isNull); // Valid scores
    });

    test('should reject negative scores', () {
      final result = ValidationRules.validateScoreValues(-1, 9, 8, 11);

      expect(result, equals('Scores cannot be negative'));
    });

    test('should reject scores exceeding maximum', () {
      final result = ValidationRules.validateScoreValues(25, 9, 8, 11);

      expect(result, equals('Scores cannot exceed 21'));
    });

    test('should allow admin to delete games', () {
      final result = ValidationRules.validateGameDeletion(
        testGame,
        'admin@example.com',
        'admin',
      );

      expect(result, isNull); // Valid
    });

    test('should prevent non-admin from deleting games', () {
      final result = ValidationRules.validateGameDeletion(
        testGame,
        'user@example.com',
        'user',
      );

      expect(result, equals('Only administrators can delete games'));
    });

    test('should provide user-friendly error messages', () {
      final errorMessage = ValidationRules.getJoinGameErrorMessage(
        testGame,
        'player1@example.com', // Already in game
        'team2',
      );

      expect(errorMessage, equals('Player is already part of this game'));
    });
  });
}