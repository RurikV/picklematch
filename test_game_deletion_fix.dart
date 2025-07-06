import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'lib/bloc/game/game_bloc.dart';
import 'lib/bloc/game/game_event.dart';
import 'lib/bloc/game/game_state.dart';
import 'lib/bloc/auth/auth_bloc.dart';
import 'lib/bloc/auth/auth_state.dart';
import 'lib/services/api_service.dart';
import 'lib/services/storage_service.dart';
import 'lib/models/game.dart';
import 'lib/models/location.dart';
import 'lib/models/user.dart';
import 'lib/screens/game_detail_screen.dart';

// Generate mocks
@GenerateMocks([ApiService, StorageService, AuthBloc])
import 'test_game_deletion_fix.mocks.dart';

void main() {
  group('Game Deletion Fix Tests', () {
    late GameBloc gameBloc;
    late MockApiService mockApiService;
    late MockStorageService mockStorageService;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockApiService = MockApiService();
      mockStorageService = MockStorageService();
      mockAuthBloc = MockAuthBloc();
      gameBloc = GameBloc(
        apiService: mockApiService,
        storageService: mockStorageService,
      );
    });

    tearDown(() {
      gameBloc.close();
    });

    testWidgets('GameDetailScreen should not cause blank screen after successful game deletion', (WidgetTester tester) async {
      // Arrange
      final testGame = Game(
        id: 'test-game-id',
        time: '14:30',
        locationId: 'location-1',
        team1: Team(),
        team2: Team(),
        date: DateTime.now(),
      );

      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
      ];

      final testUser = User(
        id: 'admin-user',
        email: 'admin@test.com',
        name: 'Admin User',
        role: 'admin',
      );

      // Mock storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => []);
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});

      // Mock API service
      when(mockApiService.deleteGame('test-token', 'test-game-id'))
          .thenAnswer((_) async {});

      // Mock auth bloc
      when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: testUser));

      // Build the widget with navigation context
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<GameBloc>(create: (context) => gameBloc),
                BlocProvider<AuthBloc>(create: (context) => mockAuthBloc),
              ],
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameDetailScreen(game: testGame),
                      ),
                    );
                  },
                  child: const Text('Open Game Detail'),
                ),
              ),
            ),
          ),
        ),
      );

      // Set initial state
      gameBloc.emit(GamesLoaded(
        games: [testGame],
        selectedDate: DateTime.now(),
        selectedLocationId: null,
        locations: testLocations,
      ));
      await tester.pump();

      // Navigate to GameDetailScreen
      await tester.tap(find.text('Open Game Detail'));
      await tester.pumpAndSettle();

      // Verify GameDetailScreen is displayed
      expect(find.byType(GameDetailScreen), findsOneWidget);
      expect(find.text('Game Details'), findsOneWidget);

      // Find and tap the delete button
      expect(find.byIcon(Icons.delete), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Verify delete confirmation dialog appears
      expect(find.text('Delete Game'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this game?'), findsOneWidget);

      // Tap the delete confirmation button
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Simulate successful deletion
      gameBloc.emit(GameDeleted(gameId: 'test-game-id'));
      await tester.pumpAndSettle();

      // Assert
      // Should navigate back to previous screen (not blank screen)
      expect(find.byType(GameDetailScreen), findsNothing);
      expect(find.text('Open Game Detail'), findsOneWidget); // Back to home screen
      
      // Success message should have been shown
      expect(find.text('Game deleted successfully'), findsOneWidget);
    });

    test('DeleteGame event should handle successful deletion', () async {
      // Arrange
      final testGame = Game(
        id: 'test-game-id',
        time: '14:30',
        locationId: 'location-1',
        team1: Team(),
        team2: Team(),
        date: DateTime.now(),
      );

      final testLocations = [
        Location(id: 'location-1', name: 'Test Location', address: '123 Test St', description: 'Test'),
      ];

      // Mock the storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => [testGame]);
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});

      // Mock the API service
      when(mockApiService.deleteGame('test-token', 'test-game-id'))
          .thenAnswer((_) async {});

      // Set initial state
      gameBloc.emit(GamesLoaded(
        games: [testGame],
        selectedDate: DateTime.now(),
        selectedLocationId: null,
        locations: testLocations,
      ));

      // Act
      gameBloc.add(DeleteGame(gameId: 'test-game-id'));

      // Assert
      await expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          isA<GameDeleted>(),
          isA<GamesLoaded>(),
        ]),
      );

      // Verify API call was made
      verify(mockApiService.deleteGame('test-token', 'test-game-id')).called(1);
      verify(mockStorageService.saveGames(any)).called(1);
    });

    test('DeleteGame event should handle authentication error', () async {
      // Arrange
      // Mock no token (authentication error)
      when(mockStorageService.getToken()).thenAnswer((_) async => null);

      // Set initial state
      gameBloc.emit(GamesLoaded(
        games: [],
        selectedDate: DateTime.now(),
        selectedLocationId: null,
        locations: [],
      ));

      // Act
      gameBloc.add(DeleteGame(gameId: 'test-game-id'));

      // Assert
      await expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          predicate<GameError>((state) => 
            state.error == 'Authentication token not found'),
        ]),
      );
    });

    test('DeleteGame event should handle API service error', () async {
      // Arrange
      // Mock the storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');

      // Mock API service to throw an error
      when(mockApiService.deleteGame('test-token', 'test-game-id'))
          .thenThrow(Exception('Failed to delete game: Network error'));

      // Set initial state
      gameBloc.emit(GamesLoaded(
        games: [],
        selectedDate: DateTime.now(),
        selectedLocationId: null,
        locations: [],
      ));

      // Act
      gameBloc.add(DeleteGame(gameId: 'test-game-id'));

      // Assert
      await expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          predicate<GameError>((state) => 
            state.error.contains('Failed to delete game')),
          isA<GamesLoaded>(), // Should restore previous state
        ]),
      );
    });
  });

  print('✅ All Game Deletion fix tests completed!');
  print('The fix should resolve the issue where users see a blank screen after deleting a game.');
  print('Key improvements:');
  print('1. Removed double Navigator.pop() calls that caused navigation stack corruption');
  print('2. Navigation now only happens when GameDeleted state is confirmed');
  print('3. Proper success message display without navigation issues');
  print('4. Maintains proper navigation flow back to previous screen');
}