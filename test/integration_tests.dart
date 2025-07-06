import 'package:flutter_test/flutter_test.dart';
import 'package:picklematch/models/game.dart';
import 'package:picklematch/models/location.dart';
import 'package:picklematch/models/player.dart';

void main() {
  group('PickleMatch Integration Tests', () {

    group('Game Model Tests', () {
      test('Game.fromJson should handle valid data correctly', () {
        // Test the null validation fix for join game issue
        final validGameData = {
          'id': 'game-123',
          'time': '14:30',
          'location_id': 'location-456',
          'team1': {'player1': null, 'player2': null},
          'team2': {'player1': null, 'player2': null},
          'team1_score1': 0,
          'team1_score2': 0,
          'team2_score1': 0,
          'team2_score2': 0,
          'date': '2024-01-15',
        };

        final game = Game.fromJson(validGameData);

        expect(game.id, equals('game-123'));
        expect(game.time, equals('14:30'));
        expect(game.locationId, equals('location-456'));
        expect(game.team1.isEmpty, isTrue);
        expect(game.team2.isEmpty, isTrue);
        expect(game.date, equals(DateTime.parse('2024-01-15')));
      });

      test('Game.fromJson should throw exception when required fields are null', () {
        final invalidGameData = {
          'id': null, // This should cause an error
          'time': '14:30',
          'location_id': 'location-456',
          'team1': {'player1': null, 'player2': null},
          'team2': {'player1': null, 'player2': null},
          'date': '2024-01-15',
        };

        expect(
          () => Game.fromJson(invalidGameData),
          throwsA(predicate((e) => e.toString().contains('Game id cannot be null'))),
        );
      });
    });

    group('Player Model Tests', () {
      test('Player.getDisplayName should return email prefix', () {
        final player = Player(
          uid: 'user-123',
          email: 'john.doe@example.com',
          rating: 1200.0,
          active: true,
        );

        expect(player.getDisplayName(), equals('john.doe'));
      });

      test('Player.getDisplayName should return Anonymous for null email', () {
        final player = Player(
          uid: 'user-123',
          email: null,
          rating: 1200.0,
          active: true,
        );

        expect(player.getDisplayName(), equals('Anonymous'));
      });
    });

    group('Location Model Tests', () {
      test('Location should be created with all required fields', () {
        final location = Location(
          id: 'loc-123',
          name: 'Tennis Court A',
          address: '123 Main St',
          description: 'Outdoor court',
        );

        expect(location.id, equals('loc-123'));
        expect(location.name, equals('Tennis Court A'));
        expect(location.address, equals('123 Main St'));
        expect(location.description, equals('Outdoor court'));
      });
    });

    group('Team Model Tests', () {
      test('Team.isEmpty should return true when no players', () {
        final team = Team();
        expect(team.isEmpty, isTrue);
        expect(team.isFull, isFalse);
      });

      test('Team.isFull should return true when both players assigned', () {
        final team = Team(
          player1: 'player1@example.com',
          player2: 'player2@example.com',
        );
        expect(team.isEmpty, isFalse);
        expect(team.isFull, isTrue);
      });
    });
  });
}
