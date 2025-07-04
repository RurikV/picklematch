import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:picklematch/bloc/game/game_bloc.dart';
import 'package:picklematch/bloc/game/game_event.dart';
import 'package:picklematch/bloc/game/game_state.dart';
import 'package:picklematch/models/game.dart';
import 'package:picklematch/models/location.dart';
import 'package:picklematch/services/api_service.dart';
import 'package:picklematch/services/storage_service.dart';

@GenerateMocks([ApiService, StorageService])
import 'game_bloc_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;
  late GameBloc gameBloc;

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

  group('GameBloc', () {
    final testDate = DateTime(2023, 1, 1);
    final formattedDate = '2023-01-01';
    const testLocationId = 'location-1';
    const testToken = 'test-token';

    final testLocations = [
      Location(id: 'location-1', name: 'Location 1'),
      Location(id: 'location-2', name: 'Location 2'),
    ];

    final testGames = [
      Game(
        id: 'game-1',
        time: '10:00 AM',
        locationId: 'location-1',
        team1: Team(),
        team2: Team(),
        date: testDate,
      ),
      Game(
        id: 'game-2',
        time: '11:00 AM',
        locationId: 'location-2',
        team1: Team(),
        team2: Team(),
        date: testDate,
      ),
    ];

    test('initial state is GameInitial', () {
      expect(gameBloc.state, isA<GameInitial>());
    });

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GamesLoaded] when LoadGames is added',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.getGames(testToken)).thenAnswer((_) async => testGames);
        when(mockApiService.getLocations(testToken)).thenAnswer((_) async => testLocations);
        when(mockStorageService.saveGames(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveLocations(any)).thenAnswer((_) async => {});
        return gameBloc;
      },
      act: (bloc) => bloc.add(const LoadGames()),
      expect: () => [
        isA<GameLoading>(),
        isA<GamesLoaded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.getGames(testToken)).called(1);
        verify(mockApiService.getLocations(testToken)).called(1);
        verify(mockStorageService.saveGames(testGames)).called(1);
        verify(mockStorageService.saveLocations(testLocations)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GamesLoaded] when LoadGames with date and locationId is added',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.getGames(testToken, date: formattedDate, locationId: testLocationId))
            .thenAnswer((_) async => testGames);
        when(mockApiService.getLocations(testToken)).thenAnswer((_) async => testLocations);
        when(mockStorageService.saveGames(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveLocations(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveSelectedDate(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveSelectedLocationId(any)).thenAnswer((_) async => {});
        return gameBloc;
      },
      act: (bloc) => bloc.add(LoadGames(date: formattedDate, locationId: testLocationId)),
      expect: () => [
        isA<GameLoading>(),
        isA<GamesLoaded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.getGames(testToken, date: formattedDate, locationId: testLocationId)).called(1);
        verify(mockApiService.getLocations(testToken)).called(1);
        verify(mockStorageService.saveGames(testGames)).called(1);
        verify(mockStorageService.saveLocations(testLocations)).called(1);
        verify(mockStorageService.saveSelectedLocationId(testLocationId)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GameError] when LoadGames fails and cache is empty',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.getGames(testToken)).thenThrow(Exception('Failed to load games'));
        when(mockStorageService.getGames()).thenThrow(Exception('Cache empty'));
        return gameBloc;
      },
      act: (bloc) => bloc.add(const LoadGames()),
      expect: () => [
        isA<GameLoading>(),
        isA<GameError>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.getGames(testToken)).called(1);
        verify(mockStorageService.getGames()).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GamesLoaded] when LoadGames fails but cache is available',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.getGames(testToken)).thenThrow(Exception('Failed to load games'));
        when(mockStorageService.getGames()).thenAnswer((_) async => testGames);
        when(mockStorageService.getLocations()).thenAnswer((_) async => testLocations);
        when(mockStorageService.getSelectedDate()).thenAnswer((_) async => testDate);
        when(mockStorageService.getSelectedLocationId()).thenAnswer((_) async => testLocationId);
        return gameBloc;
      },
      act: (bloc) => bloc.add(const LoadGames()),
      expect: () => [
        isA<GameLoading>(),
        isA<GamesLoaded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.getGames(testToken)).called(1);
        verify(mockStorageService.getGames()).called(1);
        verify(mockStorageService.getLocations()).called(1);
        verify(mockStorageService.getSelectedDate()).called(1);
        verify(mockStorageService.getSelectedLocationId()).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GameResultUpdated, GamesLoaded] when UpdateGameResult is added',
      build: () {
        // Set initial state to GamesLoaded
        gameBloc.emit(GamesLoaded(
          games: testGames,
          locations: testLocations,
        ));

        final updatedGame = testGames[0].copyWith(
          team1Score1: 10,
          team1Score2: 11,
          team2Score1: 5,
          team2Score2: 7,
        );

        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.updateGameResult(
          testToken,
          'game-1',
          10,
          11,
          5,
          7,
        )).thenAnswer((_) async => updatedGame);
        when(mockStorageService.saveGames(any)).thenAnswer((_) async => {});

        return gameBloc;
      },
      act: (bloc) => bloc.add(const UpdateGameResult(
        gameId: 'game-1',
        team1Score1: 10,
        team1Score2: 11,
        team2Score1: 5,
        team2Score2: 7,
      )),
      expect: () => [
        isA<GameLoading>(),
        isA<GameResultUpdated>(),
        isA<GamesLoaded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.updateGameResult(
          testToken,
          'game-1',
          10,
          11,
          5,
          7,
        )).called(1);
        verify(mockStorageService.saveGames(any)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GameJoined, GamesLoaded] when JoinGame is added',
      build: () {
        // Set initial state to GamesLoaded
        gameBloc.emit(GamesLoaded(
          games: testGames,
          locations: testLocations,
        ));

        final updatedGame = testGames[0].copyWith(
          team1: Team(player1: 'user-1'),
        );

        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.joinGame(
          testToken,
          'game-1',
          'team1',
        )).thenAnswer((_) async => updatedGame);
        when(mockStorageService.saveGames(any)).thenAnswer((_) async => {});

        return gameBloc;
      },
      act: (bloc) => bloc.add(const JoinGame(
        gameId: 'game-1',
        team: 'team1',
      )),
      expect: () => [
        isA<GameLoading>(),
        isA<GameJoined>(),
        isA<GamesLoaded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.joinGame(
          testToken,
          'game-1',
          'team1',
        )).called(1);
        verify(mockStorageService.saveGames(any)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameLoading, GameDeleted, GamesLoaded] when DeleteGame is added',
      build: () {
        // Set initial state to GamesLoaded
        gameBloc.emit(GamesLoaded(
          games: testGames,
          locations: testLocations,
        ));

        when(mockStorageService.getToken()).thenAnswer((_) async => testToken);
        when(mockApiService.deleteGame(
          testToken,
          'game-1',
        )).thenAnswer((_) async => {});
        when(mockStorageService.saveGames(any)).thenAnswer((_) async => {});

        return gameBloc;
      },
      act: (bloc) => bloc.add(const DeleteGame(
        gameId: 'game-1',
      )),
      expect: () => [
        isA<GameLoading>(),
        isA<GameDeleted>(),
        isA<GamesLoaded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.deleteGame(
          testToken,
          'game-1',
        )).called(1);
        verify(mockStorageService.saveGames(any)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'calls LoadGames when SetSelectedDate is added',
      build: () {
        // Set initial state to GamesLoaded
        gameBloc.emit(GamesLoaded(
          games: testGames,
          locations: testLocations,
        ));

        when(mockStorageService.saveSelectedDate(any)).thenAnswer((_) async => {});

        return gameBloc;
      },
      act: (bloc) => bloc.add(SetSelectedDate(date: testDate)),
      verify: (_) {
        verify(mockStorageService.saveSelectedDate(testDate)).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'calls LoadGames when SetSelectedLocation is added',
      build: () {
        // Set initial state to GamesLoaded
        gameBloc.emit(GamesLoaded(
          games: testGames,
          locations: testLocations,
          selectedDate: testDate,
        ));

        when(mockStorageService.saveSelectedLocationId(any)).thenAnswer((_) async => {});

        return gameBloc;
      },
      act: (bloc) => bloc.add(const SetSelectedLocation(locationId: testLocationId)),
      verify: (_) {
        verify(mockStorageService.saveSelectedLocationId(testLocationId)).called(1);
      },
    );
  });
}