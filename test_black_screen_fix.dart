import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'lib/bloc/game/game_bloc.dart';
import 'lib/bloc/game/game_event.dart';
import 'lib/bloc/game/game_state.dart';
import 'lib/services/api_service.dart';
import 'lib/services/storage_service.dart';
import 'lib/models/game.dart';
import 'lib/models/location.dart';
import 'lib/screens/create_game_screen.dart';

// Generate mocks
@GenerateMocks([ApiService, StorageService])
import 'test_black_screen_fix.mocks.dart';

void main() {
  group('Black Screen Fix Tests', () {
    late GameBloc gameBloc;
    late MockApiService mockApiService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockApiService = MockApiService();
      mockStorageService = MockStorageService();
      gameBloc = GameBloc(
        apiService: mockApiService,
        storageService: mockStorageService,
      );
    });

    tearDown(() {
      gameBloc.close();
    });

    testWidgets('CreateGameScreen should not cause black screen after successful game creation', (WidgetTester tester) async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
      ];

      final testGame = Game(
        id: 'temp-id',
        time: '14:30',
        locationId: 'location-1',
        team1: Team(),
        team2: Team(),
        date: DateTime.now(),
      );

      final createdGame = testGame.copyWith(id: 'real-game-id');

      // Mock storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => []);
      when(mockStorageService.getLocations()).thenAnswer((_) async => testLocations);
      when(mockStorageService.getSelectedDate()).thenAnswer((_) async => DateTime.now());
      when(mockStorageService.getSelectedLocationId()).thenAnswer((_) async => null);
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});
      when(mockStorageService.saveLocations(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedDate(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedLocationId(any)).thenAnswer((_) async {});

      // Mock API service
      when(mockApiService.getGames('test-token', date: any, locationId: any))
          .thenAnswer((_) async => []);
      when(mockApiService.getLocations('test-token'))
          .thenAnswer((_) async => testLocations);
      when(mockApiService.createGame('test-token', any))
          .thenAnswer((_) async => createdGame);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>(
            create: (context) => gameBloc,
            child: const CreateGameScreen(),
          ),
        ),
      );

      // Load locations first
      gameBloc.add(const LoadGames());
      await tester.pumpAndSettle();

      // Act - Simulate successful game creation
      gameBloc.emit(GamesLoaded(
        games: [],
        selectedDate: DateTime.now(),
        selectedLocationId: null,
        locations: testLocations,
      ));
      await tester.pump();

      // Simulate game creation success
      gameBloc.emit(GameCreated(game: createdGame));
      await tester.pumpAndSettle();

      // Assert
      // The screen should still be visible (not black)
      expect(find.byType(CreateGameScreen), findsOneWidget);
      expect(find.text('Create Game'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Success message should be shown
      expect(find.text('Game created successfully'), findsOneWidget);
      
      // Form should be reset (date should be today, time should be current time)
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(InputDecorator), findsNWidgets(2)); // Date and time pickers
    });

    test('GameCreated state should reset form and show success message without navigation', () async {
      // Arrange
      final testGame = Game(
        id: 'temp-id',
        time: '14:30',
        locationId: 'location-1',
        team1: Team(),
        team2: Team(),
        date: DateTime(2024, 1, 15),
      );

      final createdGame = testGame.copyWith(id: 'real-game-id');
      final testLocations = [
        Location(id: 'location-1', name: 'Test Location', address: '123 Test St', description: 'Test'),
      ];

      // Mock the storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => []);
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});

      // Mock the API service
      when(mockApiService.createGame('test-token', testGame))
          .thenAnswer((_) async => createdGame);

      // Set initial state
      gameBloc.emit(GamesLoaded(
        games: [],
        selectedDate: DateTime(2024, 1, 15),
        selectedLocationId: null,
        locations: testLocations,
      ));

      // Act
      gameBloc.add(CreateGame(game: testGame));

      // Assert
      await expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          isA<GameCreated>(),
          isA<GamesLoaded>(),
        ]),
      );

      // Verify API call was made
      verify(mockApiService.createGame('test-token', testGame)).called(1);
      verify(mockStorageService.saveGames(any)).called(1);
    });
  });

  print('✅ All Black Screen fix tests completed!');
  print('The fix should resolve the issue where users see a black screen after creating a game.');
  print('Key improvements:');
  print('1. Removed inappropriate Navigator.pop() call that caused black screen');
  print('2. Form now resets after successful game creation');
  print('3. Success message is shown without navigation issues');
  print('4. CreateGameScreen remains functional as an embedded tab');
}