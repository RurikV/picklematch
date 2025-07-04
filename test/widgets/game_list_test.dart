import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picklematch/models/game.dart';
import 'package:picklematch/models/location.dart';
import 'package:picklematch/widgets/game_list.dart';

void main() {
  final testLocations = [
    Location(id: 'location-1', name: 'Location 1'),
    Location(id: 'location-2', name: 'Location 2'),
  ];

  final testDate = DateTime(2023, 1, 1);

  final testGames = [
    Game(
      id: 'game-1',
      time: '10:00 AM',
      locationId: 'location-1',
      team1: Team(player1: 'player1@example.com', player2: 'player2@example.com'),
      team2: Team(player1: 'player3@example.com'),
      date: testDate,
    ),
    Game(
      id: 'game-2',
      time: '11:00 AM',
      locationId: 'location-2',
      team1: Team(player1: 'player4@example.com'),
      team2: Team(player2: 'player5@example.com'),
      date: testDate,
      team1Score1: 11,
      team1Score2: 9,
      team2Score1: 5,
      team2Score2: 11,
    ),
  ];

  Widget createWidgetUnderTest({
    required List<Game> games,
    required List<Location> locations,
    required Function(Game) onGameTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GameList(
          games: games,
          locations: locations,
          onGameTap: onGameTap,
        ),
      ),
    );
  }

  testWidgets('GameList shows empty state when no games', (WidgetTester tester) async {
    // Act
    await tester.pumpWidget(createWidgetUnderTest(
      games: [],
      locations: testLocations,
      onGameTap: (game) {
        // No need to track taps in this test
      },
    ));

    // Assert
    expect(find.text('No games found'), findsOneWidget);
    expect(find.text('Try selecting a different date or location'), findsOneWidget);
  });

  testWidgets('GameList shows games when available', (WidgetTester tester) async {
    // Act
    await tester.pumpWidget(createWidgetUnderTest(
      games: testGames,
      locations: testLocations,
      onGameTap: (game) {
        // No need to track taps in this test
      },
    ));

    // Assert
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.text('11:00 AM'), findsOneWidget);
    expect(find.text('Location 1'), findsOneWidget);
    expect(find.text('Location 2'), findsOneWidget);

    // Check team names are displayed correctly
    expect(find.text('player1 / player2'), findsOneWidget);
    expect(find.text('player3 / Empty'), findsOneWidget);
    expect(find.text('player4 / Empty'), findsOneWidget);
    expect(find.text('Empty / player5'), findsOneWidget);

    // Check scores are displayed for game with scores
    expect(find.text('11-5, 9-11'), findsOneWidget);

    // Check available slots indicator
    expect(find.text('Slots available'), findsNWidgets(2));
  });

  testWidgets('GameList calls onGameTap when game is tapped', (WidgetTester tester) async {
    // Arrange
    Game? tappedGame;

    // Act
    await tester.pumpWidget(createWidgetUnderTest(
      games: testGames,
      locations: testLocations,
      onGameTap: (game) {
        tappedGame = game;
      },
    ));

    // Tap on the first game
    await tester.tap(find.text('10:00 AM'));

    // Assert
    expect(tappedGame, testGames[0]);
  });

  testWidgets('GameList handles unknown location gracefully', (WidgetTester tester) async {
    // Arrange
    final gameWithUnknownLocation = Game(
      id: 'game-3',
      time: '12:00 PM',
      locationId: 'unknown-location',
      team1: Team(),
      team2: Team(),
      date: testDate,
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest(
      games: [gameWithUnknownLocation],
      locations: testLocations,
      onGameTap: (game) {},
    ));

    // Assert
    expect(find.text('12:00 PM'), findsOneWidget);
    expect(find.text('Unknown Location'), findsOneWidget);
  });

  testWidgets('GameList shows VS between teams', (WidgetTester tester) async {
    // Act
    await tester.pumpWidget(createWidgetUnderTest(
      games: testGames,
      locations: testLocations,
      onGameTap: (game) {},
    ));

    // Assert
    expect(find.text('VS'), findsNWidgets(2));
  });

  testWidgets('GameList shows Team 1 and Team 2 labels', (WidgetTester tester) async {
    // Act
    await tester.pumpWidget(createWidgetUnderTest(
      games: testGames,
      locations: testLocations,
      onGameTap: (game) {},
    ));

    // Assert
    expect(find.text('Team 1'), findsNWidgets(2));
    expect(find.text('Team 2'), findsNWidgets(2));
  });
}
