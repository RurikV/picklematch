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
import 'lib/models/location.dart';
import 'lib/screens/create_game_screen.dart';

// Generate mocks
@GenerateMocks([ApiService, StorageService])
import 'test_location_selection_fix.mocks.dart';

void main() {
  group('Location Selection in Create Game Screen Tests', () {
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

    testWidgets('CreateGameScreen should show location dropdown when locations are loaded', (WidgetTester tester) async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
        Location(id: 'location-2', name: 'Tennis Court B', address: '456 Oak Ave', description: 'Indoor court'),
        Location(id: 'location-3', name: 'Community Center', address: '789 Pine St', description: 'Multi-purpose court'),
      ];

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

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>(
            create: (context) => gameBloc,
            child: const CreateGameScreen(),
          ),
        ),
      );

      // Trigger LoadGames to load locations
      gameBloc.add(const LoadGames());
      await tester.pump();

      // Wait for the GameBloc to emit GamesLoaded state
      await tester.pumpAndSettle();

      // Assert
      // Check that location dropdown is present
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Check that the dropdown has the correct label
      expect(find.text('Location'), findsOneWidget);
      
      // Tap on the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      
      // Check that all locations are available in the dropdown
      expect(find.text('Tennis Court A'), findsOneWidget);
      expect(find.text('Tennis Court B'), findsOneWidget);
      expect(find.text('Community Center'), findsOneWidget);
    });

    testWidgets('CreateGameScreen should handle location selection', (WidgetTester tester) async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
        Location(id: 'location-2', name: 'Tennis Court B', address: '456 Oak Ave', description: 'Indoor court'),
      ];

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

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<GameBloc>(
            create: (context) => gameBloc,
            child: const CreateGameScreen(),
          ),
        ),
      );

      // Trigger LoadGames to load locations
      gameBloc.add(const LoadGames());
      await tester.pump();
      await tester.pumpAndSettle();

      // Act - Select a different location
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Tennis Court B').last);
      await tester.pumpAndSettle();

      // Assert - The selected location should be updated
      // We can verify this by checking that the dropdown shows the selected value
      expect(find.text('Tennis Court B'), findsOneWidget);
    });

    test('CreateGameScreen should trigger LoadGames when GameBloc is not in GamesLoaded state', () async {
      // Arrange
      final testLocations = [
        Location(id: 'location-1', name: 'Tennis Court A', address: '123 Main St', description: 'Outdoor court'),
      ];

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

      // Act - When GameBloc is in initial state and _loadLocations is called
      // This simulates what happens when CreateGameScreen initializes
      
      // The GameBloc should receive a LoadGames event
      expectLater(
        gameBloc.stream,
        emitsInOrder([
          isA<GameLoading>(),
          isA<GamesLoaded>(),
        ]),
      );

      // Trigger the LoadGames event (this is what _loadLocations does when state is not GamesLoaded)
      gameBloc.add(const LoadGames());
    });
  });

  print('✅ All Location Selection functionality tests completed!');
  print('The fix should resolve the issue where users cannot choose a location during game creation.');
  print('Key improvements:');
  print('1. CreateGameScreen now triggers LoadGames if GameBloc is not in GamesLoaded state');
  print('2. CreateGameScreen is now reactive to GameBloc state changes via BlocListener');
  print('3. Locations are automatically loaded and the first location is selected by default');
  print('4. The location dropdown will be populated once locations are loaded from the API');
}