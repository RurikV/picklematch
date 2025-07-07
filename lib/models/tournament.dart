import 'game.dart';

class Tournament {
  final String id;
  final String name;
  final String description;
  final String locationId;
  final DateTime date;
  final List<String> timeSlots; // List of time slots for games
  final int numberOfCourts;
  final String createdBy; // Admin user ID
  final DateTime createdAt;
  final List<String> registeredPlayers; // List of player UIDs
  final List<TournamentGame> games; // Generated games
  final TournamentStatus status;
  final double? minRating;
  final double? maxRating;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.locationId,
    required this.date,
    required this.timeSlots,
    required this.numberOfCourts,
    required this.createdBy,
    required this.createdAt,
    this.registeredPlayers = const [],
    this.games = const [],
    this.status = TournamentStatus.open,
    this.minRating,
    this.maxRating,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      locationId: json['location_id'],
      date: DateTime.parse(json['date']),
      timeSlots: List<String>.from(json['time_slots'] ?? []),
      numberOfCourts: json['number_of_courts'] ?? 1,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      registeredPlayers: List<String>.from(json['registered_players'] ?? []),
      games: (json['games'] as List<dynamic>?)
          ?.map((game) => TournamentGame.fromJson(game))
          .toList() ?? [],
      status: TournamentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TournamentStatus.open,
      ),
      minRating: json['min_rating']?.toDouble(),
      maxRating: json['max_rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location_id': locationId,
      'date': date.toIso8601String().split('T').first,
      'time_slots': timeSlots,
      'number_of_courts': numberOfCourts,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'registered_players': registeredPlayers,
      'games': games.map((game) => game.toJson()).toList(),
      'status': status.name,
      'min_rating': minRating,
      'max_rating': maxRating,
    };
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    String? locationId,
    DateTime? date,
    List<String>? timeSlots,
    int? numberOfCourts,
    String? createdBy,
    DateTime? createdAt,
    List<String>? registeredPlayers,
    List<TournamentGame>? games,
    TournamentStatus? status,
    double? minRating,
    double? maxRating,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      locationId: locationId ?? this.locationId,
      date: date ?? this.date,
      timeSlots: timeSlots ?? this.timeSlots,
      numberOfCourts: numberOfCourts ?? this.numberOfCourts,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      registeredPlayers: registeredPlayers ?? this.registeredPlayers,
      games: games ?? this.games,
      status: status ?? this.status,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
    );
  }

  bool canRegister(double? playerRating) {
    if (status != TournamentStatus.open) return false;

    if (minRating != null && (playerRating == null || playerRating < minRating!)) {
      return false;
    }

    if (maxRating != null && (playerRating == null || playerRating > maxRating!)) {
      return false;
    }

    return true;
  }
}

class TournamentGame {
  final String id;
  final String tournamentId;
  final String timeSlot;
  final int courtNumber;
  final Team team1;
  final Team team2;
  final int? team1Score1;
  final int? team1Score2;
  final int? team2Score1;
  final int? team2Score2;
  final GameStatus status;

  TournamentGame({
    required this.id,
    required this.tournamentId,
    required this.timeSlot,
    required this.courtNumber,
    required this.team1,
    required this.team2,
    this.team1Score1,
    this.team1Score2,
    this.team2Score1,
    this.team2Score2,
    this.status = GameStatus.scheduled,
  });

  factory TournamentGame.fromJson(Map<String, dynamic> json) {
    return TournamentGame(
      id: json['id'],
      tournamentId: json['tournament_id'],
      timeSlot: json['time_slot'],
      courtNumber: json['court_number'],
      team1: Team.fromJson(json['team1']),
      team2: Team.fromJson(json['team2']),
      team1Score1: json['team1_score1'],
      team1Score2: json['team1_score2'],
      team2Score1: json['team2_score1'],
      team2Score2: json['team2_score2'],
      status: GameStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => GameStatus.scheduled,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'time_slot': timeSlot,
      'court_number': courtNumber,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'team1_score1': team1Score1,
      'team1_score2': team1Score2,
      'team2_score1': team2Score1,
      'team2_score2': team2Score2,
      'status': status.name,
    };
  }

  TournamentGame copyWith({
    String? id,
    String? tournamentId,
    String? timeSlot,
    int? courtNumber,
    Team? team1,
    Team? team2,
    int? team1Score1,
    int? team1Score2,
    int? team2Score1,
    int? team2Score2,
    GameStatus? status,
  }) {
    return TournamentGame(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      timeSlot: timeSlot ?? this.timeSlot,
      courtNumber: courtNumber ?? this.courtNumber,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      team1Score1: team1Score1 ?? this.team1Score1,
      team1Score2: team1Score2 ?? this.team1Score2,
      team2Score1: team2Score1 ?? this.team2Score1,
      team2Score2: team2Score2 ?? this.team2Score2,
      status: status ?? this.status,
    );
  }
}

enum TournamentStatus {
  open,
  closed,
  inProgress,
  completed,
  cancelled,
}

enum GameStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

// Import the Team class from game.dart
// This will be handled by the import statement at the top of the file
