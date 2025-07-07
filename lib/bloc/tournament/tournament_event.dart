import '../../models/tournament.dart';

abstract class TournamentEvent {}

class LoadTournaments extends TournamentEvent {}

class LoadTournamentsByAdmin extends TournamentEvent {
  final String adminUserId;
  LoadTournamentsByAdmin(this.adminUserId);
}

class LoadOpenTournaments extends TournamentEvent {
  final String playerId;
  LoadOpenTournaments(this.playerId);
}

class LoadPlayerTournaments extends TournamentEvent {
  final String playerId;
  LoadPlayerTournaments(this.playerId);
}

class CreateTournament extends TournamentEvent {
  final String name;
  final String description;
  final String locationId;
  final DateTime date;
  final List<String> timeSlots;
  final int numberOfCourts;
  final String adminUserId;
  final double? minRating;
  final double? maxRating;

  CreateTournament({
    required this.name,
    required this.description,
    required this.locationId,
    required this.date,
    required this.timeSlots,
    required this.numberOfCourts,
    required this.adminUserId,
    this.minRating,
    this.maxRating,
  });
}

class RegisterForTournament extends TournamentEvent {
  final String tournamentId;
  final String playerId;

  RegisterForTournament({
    required this.tournamentId,
    required this.playerId,
  });
}

class UnregisterFromTournament extends TournamentEvent {
  final String tournamentId;
  final String playerId;

  UnregisterFromTournament({
    required this.tournamentId,
    required this.playerId,
  });
}

class GenerateTournamentMatches extends TournamentEvent {
  final String tournamentId;
  final String adminUserId;

  GenerateTournamentMatches({
    required this.tournamentId,
    required this.adminUserId,
  });
}

class StartTournament extends TournamentEvent {
  final String tournamentId;
  final String adminUserId;

  StartTournament({
    required this.tournamentId,
    required this.adminUserId,
  });
}

class CompleteTournament extends TournamentEvent {
  final String tournamentId;
  final String adminUserId;

  CompleteTournament({
    required this.tournamentId,
    required this.adminUserId,
  });
}

class CancelTournament extends TournamentEvent {
  final String tournamentId;
  final String adminUserId;

  CancelTournament({
    required this.tournamentId,
    required this.adminUserId,
  });
}

class UpdateTournament extends TournamentEvent {
  final Tournament tournament;
  final String adminUserId;

  UpdateTournament({
    required this.tournament,
    required this.adminUserId,
  });
}

class LoadTournamentDetails extends TournamentEvent {
  final String tournamentId;

  LoadTournamentDetails(this.tournamentId);
}
