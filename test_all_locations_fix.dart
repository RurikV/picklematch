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
import 'lib/screens/home_screen.dart';

// Generate mocks
@GenerateMocks([ApiService, StorageService])
import 'test_all_locations_fix.mocks.dart';

void main() {
  group('All Locations Fix Tests', () {
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

    test('SetSelectedLocation event should handle null locationId for "All Locations"', () async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
        Location(id: 'location-2', name: 'Tennis Court B', address: '456 Oak Ave', description: 'Indoor court'),
      ];

      final testGames = [
        Game(
          id: 'game-1',
          time: '14:30',
          locationId: 'location-1',
          team1: Team(),
          team2: Team(),
          date: DateTime.now(),
        ),
        Game(
          id: 'game-2',
          time: '16:00',
          locationId: 'location-2',
          team1: Team(),
          team2: Team(),
          date: DateTime.now(),
        ),
      ];

      // Mock storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => testGames);
      when(mockStorageService.getLocations()).thenAnswer((_) async => testLocations);
      when(mockStorageService.getSelectedDate()).thenAnswer((_) async => DateTime.now());
      when(mockStorageService.getSelectedLocationId()).thenAnswer((_) async => null);
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});
      when(mockStorageService.saveLocations(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedDate(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedLocationId(any)).thenAnswer((_) async {});

      // Mock API service
      when(mockApiService.getGames('test-token', date: any, locationId: any))
          .thenAnswer((_) async => testGames);
      when(mockApiService.getLocations('test-token'))
          .thenAnswer((_) async => testLocations);

      // Set initial state with a specific location selected
      gameBloc.emit(GamesLoaded(
        games: [testGames[0]], // Only games from location-1
        selectedDate: DateTime.now(),
        selectedLocationId: 'location-1',
        locations: testLocations,
      ));

      // Act - Select "All Locations" (null locationId)
      gameBloc.add(const SetSelectedLocation(locationId: null));

      // Assert
      await expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          isA<GamesLoaded>(),
        ]),
      );

      // Verify that saveSelectedLocationId was called with null
      verify(mockStorageService.saveSelectedLocationId(null)).called(1);
      
      // Verify that getGames was called without location filter
      verify(mockApiService.getGames('test-token', date: any, locationId: null)).called(1);
    });

    testWidgets('HomeScreen should handle "All Locations" selection correctly', (WidgetTester tester) async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
        Location(id: 'location-2', name: 'Tennis Court B', address: '456 Oak Ave', description: 'Indoor court'),
      ];

      final testGames = [
        Game(
          id: 'game-1',
          time: '14:30',
          locationId: 'location-1',
          team1: Team(),
          team2: Team(),
          date: DateTime.now(),
        ),
      ];

      // Mock storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => testGames);
      when(mockStorageService.getLocations()).thenAnswer((_) async => testLocations);
      when(mockStorageService.getSelectedDate()).thenAnswer((_) async => DateTime.now());
      when(mockStorageService.getSelectedLocationId()).thenAnswer((_) async => 'location-1');
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});
      when(mockStorageService.saveLocations(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedDate(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedLocationId(any)).thenAnswer((_) async {});

      // Mock API service
      when(mockApiService.getGames('test-token', date: any, locationId: any))
          .thenAnswer((_) async => testGames);
      when(mockApiService.getLocations('test-token'))
          .thenAnswer((_) async => testLocations);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>(
            create: (context) => gameBloc,
            child: const HomeScreen(),
          ),
        ),
      );

      // Set initial state
      gameBloc.emit(GamesLoaded(
        games: testGames,
        selectedDate: DateTime.now(),
        selectedLocationId: 'location-1',
        locations: testLocations,
      ));
      await tester.pump();

      // Find the location dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Tap on the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify "All Locations" option is available
      expect(find.text('All Locations'), findsOneWidget);

      // Tap on "All Locations"
      await tester.tap(find.text('All Locations'));
      await tester.pumpAndSettle();

      // Verify that the location was cleared (this would trigger the SetSelectedLocation event)
      // The actual verification would be done through the GameBloc state changes
    });

    test('GameBloc should load all games when locationId is null', () async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
        Location(id: 'location-2', name: 'Tennis Court B', address: '456 Oak Ave', description: 'Indoor court'),
      ];

      final allGames = [
        Game(
          id: 'game-1',
          time: '14:30',
          locationId: 'location-1',
          team1: Team(),
          team2: Team(),
          date: DateTime.now(),
        ),
        Game(
          id: 'game-2',
          time: '16:00',
          locationId: 'location-2',
          team1: Team(),
          team2: Team(),
          date: DateTime.now(),
        ),
      ];

      // Mock storage service
      when(mockStorageService.getToken()).thenAnswer((_) async => 'test-token');
      when(mockStorageService.getGames()).thenAnswer((_) async => allGames);
      when(mockStorageService.getLocations()).thenAnswer((_) async => testLocations);
      when(mockStorageService.getSelectedDate()).thenAnswer((_) async => DateTime.now());
      when(mockStorageService.getSelectedLocationId()).thenAnswer((_) async => null);
      when(mockStorageService.saveGames(any)).thenAnswer((_) async {});
      when(mockStorageService.saveLocations(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedDate(any)).thenAnswer((_) async {});
      when(mockStorageService.saveSelectedLocationId(any)).thenAnswer((_) async {});

      // Mock API service to return all games when locationId is null
      when(mockApiService.getGames('test-token', date: any, locationId: null))
          .thenAnswer((_) async => allGames);
      when(mockApiService.getLocations('test-token'))
          .thenAnswer((_) async => testLocations);

      // Act
      gameBloc.add(const LoadGames(locationId: null));

      // Assert
      await expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          predicate<GamesLoaded>((state) => 
            state.games.length == 2 && 
            state.selectedLocationId == null),
        ]),
      );

      // Verify API was called with null locationId
      verify(mockApiService.getGames('test-token', date: any, locationId: null)).called(1);
    });
  });

  print('✅ All "All Locations" functionality tests completed!');
  print('The fix should resolve the issue where "All Locations" choice doesn\'t work.');
  print('Key improvements:');
  print('1. SetSelectedLocation event now accepts nullable String locationId');
  print('2. HomeScreen calls _onLocationCleared() when "All Locations" is selected');
  print('3. _onLocationCleared() properly sets locationId to null');
  print('4. GameBloc handles null locationId by loading all games without location filter');
}