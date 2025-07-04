import 'package:equatable/equatable.dart';
import '../../models/game.dart';
import '../../models/location.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GamesLoaded extends GameState {
  final List<Game> games;
  final DateTime? selectedDate;
  final String? selectedLocationId;
  final List<Location> locations;

  const GamesLoaded({
    required this.games,
    this.selectedDate,
    this.selectedLocationId,
    required this.locations,
  });

  @override
  List<Object?> get props => [games, selectedDate, selectedLocationId, locations];

  GamesLoaded copyWith({
    List<Game>? games,
    DateTime? selectedDate,
    String? selectedLocationId,
    List<Location>? locations,
  }) {
    return GamesLoaded(
      games: games ?? this.games,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      locations: locations ?? this.locations,
    );
  }
}

class GameError extends GameState {
  final String error;

  const GameError({required this.error});

  @override
  List<Object?> get props => [error];
}

class GameResultUpdated extends GameState {
  final Game game;

  const GameResultUpdated({required this.game});

  @override
  List<Object?> get props => [game];
}

class GameJoined extends GameState {
  final Game game;

  const GameJoined({required this.game});

  @override
  List<Object?> get props => [game];
}

class GameCreated extends GameState {
  final Game game;

  const GameCreated({required this.game});

  @override
  List<Object?> get props => [game];
}

class GameDeleted extends GameState {
  final String gameId;

  const GameDeleted({required this.gameId});

  @override
  List<Object?> get props => [gameId];
}