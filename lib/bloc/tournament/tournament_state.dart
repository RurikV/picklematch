import '../../models/tournament.dart';

abstract class TournamentState {}

class TournamentInitial extends TournamentState {}

class TournamentLoading extends TournamentState {}

class TournamentLoaded extends TournamentState {
  final List<Tournament> tournaments;
  
  TournamentLoaded(this.tournaments);
}

class TournamentDetailsLoaded extends TournamentState {
  final Tournament tournament;
  
  TournamentDetailsLoaded(this.tournament);
}

class TournamentCreated extends TournamentState {
  final Tournament tournament;
  
  TournamentCreated(this.tournament);
}

class TournamentUpdated extends TournamentState {
  final Tournament tournament;
  
  TournamentUpdated(this.tournament);
}

class TournamentRegistrationSuccess extends TournamentState {
  final String message;
  
  TournamentRegistrationSuccess(this.message);
}

class TournamentUnregistrationSuccess extends TournamentState {
  final String message;
  
  TournamentUnregistrationSuccess(this.message);
}

class TournamentMatchesGenerated extends TournamentState {
  final Tournament tournament;
  
  TournamentMatchesGenerated(this.tournament);
}

class TournamentStarted extends TournamentState {
  final Tournament tournament;
  
  TournamentStarted(this.tournament);
}

class TournamentCompleted extends TournamentState {
  final Tournament tournament;
  
  TournamentCompleted(this.tournament);
}

class TournamentCancelled extends TournamentState {
  final Tournament tournament;
  
  TournamentCancelled(this.tournament);
}

class TournamentError extends TournamentState {
  final String message;
  
  TournamentError(this.message);
}

class TournamentOperationInProgress extends TournamentState {
  final String operation;
  
  TournamentOperationInProgress(this.operation);
}