import 'package:equatable/equatable.dart';
import '../../models/game.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class LoadGames extends GameEvent {
  final String? date;
  final String? locationId;

  const LoadGames({this.date, this.locationId});

  @override
  List<Object?> get props => [date, locationId];
}

class UpdateGameResult extends GameEvent {
  final String gameId;
  final int team1Score1;
  final int team1Score2;
  final int team2Score1;
  final int team2Score2;

  const UpdateGameResult({
    required this.gameId,
    required this.team1Score1,
    required this.team1Score2,
    required this.team2Score1,
    required this.team2Score2,
  });

  @override
  List<Object?> get props => [gameId, team1Score1, team1Score2, team2Score1, team2Score2];
}

class JoinGame extends GameEvent {
  final String gameId;
  final String team; // 'team1' or 'team2'

  const JoinGame({required this.gameId, required this.team});

  @override
  List<Object?> get props => [gameId, team];
}

class CreateGame extends GameEvent {
  final Game game;

  const CreateGame({required this.game});

  @override
  List<Object?> get props => [game];
}

class DeleteGame extends GameEvent {
  final String gameId;

  const DeleteGame({required this.gameId});

  @override
  List<Object?> get props => [gameId];
}

class SetSelectedDate extends GameEvent {
  final DateTime date;

  const SetSelectedDate({required this.date});

  @override
  List<Object?> get props => [date];
}

class SetSelectedLocation extends GameEvent {
  final String? locationId;

  const SetSelectedLocation({required this.locationId});

  @override
  List<Object?> get props => [locationId];
}
