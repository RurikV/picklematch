import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final ApiService _apiService;
  final StorageService _storageService;
  String? _token;

  GameBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(GameInitial()) {
    on<LoadGames>(_onLoadGames);
    on<UpdateGameResult>(_onUpdateGameResult);
    on<JoinGame>(_onJoinGame);
    on<CreateGame>(_onCreateGame);
    on<DeleteGame>(_onDeleteGame);
    on<SetSelectedDate>(_onSetSelectedDate);
    on<SetSelectedLocation>(_onSetSelectedLocation);
  }

  Future<void> _onLoadGames(LoadGames event, Emitter<GameState> emit) async {
    print('GameBloc: _onLoadGames called');
    emit(GameLoading());
    try {
      _token = await _storageService.getToken();
      if (_token == null) {
        print('GameBloc: Authentication token not found');
        emit(const GameError(error: 'Authentication token not found'));
        return;
      }

      // Get selected date and location from storage if not provided in event
      DateTime? selectedDate = event.date != null 
          ? DateTime.parse(event.date!) 
          : await _storageService.getSelectedDate();

      String? selectedLocationId = event.locationId ?? await _storageService.getSelectedLocationId();

      print('GameBloc: Selected date: $selectedDate, Selected location ID: $selectedLocationId');

      // Format date for API
      String? formattedDate;
      if (selectedDate != null) {
        formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      }

      // Load games and locations
      print('GameBloc: Loading games and locations');
      final games = await _apiService.getGames(_token!, date: formattedDate, locationId: selectedLocationId);
      print('GameBloc: Loaded ${games.length} games');

      final locations = await _apiService.getLocations(_token!);
      print('GameBloc: Loaded ${locations.length} locations: ${locations.map((loc) => loc.name).join(', ')}');

      // Cache data
      print('GameBloc: Caching data');
      await _storageService.saveGames(games);
      await _storageService.saveLocations(locations);
      if (selectedDate != null) await _storageService.saveSelectedDate(selectedDate);
      if (selectedLocationId != null) await _storageService.saveSelectedLocationId(selectedLocationId);

      print('GameBloc: Emitting GamesLoaded state with ${locations.length} locations');
      emit(GamesLoaded(
        games: games,
        selectedDate: selectedDate,
        selectedLocationId: selectedLocationId,
        locations: locations,
      ));
    } catch (e) {
      print('GameBloc: Error loading games and locations: $e');
      // Try to load from cache if network fails
      try {
        print('GameBloc: Loading from cache');
        final games = await _storageService.getGames();
        final locations = await _storageService.getLocations();
        final selectedDate = await _storageService.getSelectedDate();
        final selectedLocationId = await _storageService.getSelectedLocationId();

        print('GameBloc: Loaded ${games.length} games and ${locations.length} locations from cache');
        print('GameBloc: Cache locations: ${locations.map((loc) => loc.name).join(', ')}');

        print('GameBloc: Emitting GamesLoaded state with cached data');
        emit(GamesLoaded(
          games: games,
          selectedDate: selectedDate,
          selectedLocationId: selectedLocationId,
          locations: locations,
        ));
      } catch (cacheError) {
        print('GameBloc: Cache error: $cacheError');
        emit(GameError(error: 'Failed to load games: $e (Cache error: $cacheError)'));
      }
    }
  }

  Future<void> _onUpdateGameResult(UpdateGameResult event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is GamesLoaded) {
      emit(GameLoading());
      try {
        _token = await _storageService.getToken();
        if (_token == null) {
          emit(const GameError(error: 'Authentication token not found'));
          return;
        }

        final updatedGame = await _apiService.updateGameResult(
          _token!,
          event.gameId,
          event.team1Score1,
          event.team1Score2,
          event.team2Score1,
          event.team2Score2,
        );

        // Update the game in the list
        final updatedGames = currentState.games.map((game) {
          return game.id == updatedGame.id ? updatedGame : game;
        }).toList();

        // Update cache
        await _storageService.saveGames(updatedGames);

        emit(GameResultUpdated(game: updatedGame));
        emit(currentState.copyWith(games: updatedGames));
      } catch (e) {
        emit(GameError(error: 'Failed to update game result: $e'));
        emit(currentState); // Restore previous state
      }
    }
  }

  Future<void> _onJoinGame(JoinGame event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is GamesLoaded) {
      emit(GameLoading());
      try {
        _token = await _storageService.getToken();
        if (_token == null) {
          emit(const GameError(error: 'Authentication token not found'));
          return;
        }

        final updatedGame = await _apiService.joinGame(_token!, event.gameId, event.team);

        // Update the game in the list
        final updatedGames = currentState.games.map((game) {
          return game.id == updatedGame.id ? updatedGame : game;
        }).toList();

        // Update cache
        await _storageService.saveGames(updatedGames);

        emit(GameJoined(game: updatedGame));
        emit(currentState.copyWith(games: updatedGames));
      } catch (e) {
        emit(GameError(error: 'Failed to join game: $e'));
        emit(currentState); // Restore previous state
      }
    }
  }

  Future<void> _onCreateGame(CreateGame event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is GamesLoaded) {
      emit(GameLoading());
      try {
        _token = await _storageService.getToken();
        if (_token == null) {
          emit(const GameError(error: 'Authentication token not found'));
          return;
        }

        final createdGame = await _apiService.createGame(_token!, event.game);

        // Add the new game to the list
        final updatedGames = [...currentState.games, createdGame];

        // Update cache
        await _storageService.saveGames(updatedGames);

        emit(GameCreated(game: createdGame));
        emit(currentState.copyWith(games: updatedGames));
      } catch (e) {
        emit(GameError(error: 'Failed to create game: $e'));
        emit(currentState); // Restore previous state
      }
    }
  }

  Future<void> _onDeleteGame(DeleteGame event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is GamesLoaded) {
      emit(GameLoading());
      try {
        _token = await _storageService.getToken();
        if (_token == null) {
          emit(const GameError(error: 'Authentication token not found'));
          return;
        }

        await _apiService.deleteGame(_token!, event.gameId);

        // Remove the game from the list
        final updatedGames = currentState.games.where((game) => game.id != event.gameId).toList();

        // Update cache
        await _storageService.saveGames(updatedGames);

        emit(GameDeleted(gameId: event.gameId));
        emit(currentState.copyWith(games: updatedGames));
      } catch (e) {
        emit(GameError(error: 'Failed to delete game: $e'));
        emit(currentState); // Restore previous state
      }
    }
  }

  Future<void> _onSetSelectedDate(SetSelectedDate event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is GamesLoaded) {
      // Save selected date
      await _storageService.saveSelectedDate(event.date);

      // Reload games with new date
      add(LoadGames(
        date: '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}',
        locationId: currentState.selectedLocationId,
      ));
    } else {
      // Save selected date
      await _storageService.saveSelectedDate(event.date);

      // Load games with new date
      add(LoadGames(
        date: '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}',
      ));
    }
  }

  Future<void> _onSetSelectedLocation(SetSelectedLocation event, Emitter<GameState> emit) async {
    final currentState = state;
    if (currentState is GamesLoaded) {
      // Save selected location
      await _storageService.saveSelectedLocationId(event.locationId);

      // Reload games with new location
      add(LoadGames(
        date: currentState.selectedDate != null 
            ? '${currentState.selectedDate!.year}-${currentState.selectedDate!.month.toString().padLeft(2, '0')}-${currentState.selectedDate!.day.toString().padLeft(2, '0')}'
            : null,
        locationId: event.locationId,
      ));
    } else {
      // Save selected location
      await _storageService.saveSelectedLocationId(event.locationId);

      // Load games with new location
      add(LoadGames(locationId: event.locationId));
    }
  }
}
