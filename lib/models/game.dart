
class Team {
  final String? player1;
  final String? player2;

  Team({
    this.player1,
    this.player2,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      player1: json['player1'],
      player2: json['player2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player1': player1,
      'player2': player2,
    };
  }

  Team copyWith({
    String? player1,
    String? player2,
  }) {
    return Team(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
    );
  }

  bool get isEmpty => player1 == null && player2 == null;
  bool get isFull => player1 != null && player2 != null;
}

class Game {
  final String id;
  final String time;
  final String locationId;
  final Team team1;
  final Team team2;
  final int? team1Score1;
  final int? team1Score2;
  final int? team2Score1;
  final int? team2Score2;
  final DateTime date;

  Game({
    required this.id,
    required this.time,
    required this.locationId,
    required this.team1,
    required this.team2,
    this.team1Score1,
    this.team1Score2,
    this.team2Score1,
    this.team2Score2,
    required this.date,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Validate required non-nullable fields
    final id = json['id'];
    if (id == null) {
      throw Exception('Game id cannot be null');
    }

    final time = json['time'];
    if (time == null) {
      throw Exception('Game time cannot be null');
    }

    final locationId = json['location_id'];
    // Provide default value for missing location_id to prevent unnecessary exceptions
    final safeLocationId = locationId ?? 'unknown-location';

    final dateStr = json['date'];
    if (dateStr == null) {
      throw Exception('Game date cannot be null');
    }

    // Validate team data
    final team1Data = json['team1'];
    if (team1Data == null) {
      throw Exception('Game team1 cannot be null');
    }

    final team2Data = json['team2'];
    if (team2Data == null) {
      throw Exception('Game team2 cannot be null');
    }

    return Game(
      id: id as String,
      time: time as String,
      locationId: safeLocationId as String,
      team1: Team.fromJson(team1Data as Map<String, dynamic>),
      team2: Team.fromJson(team2Data as Map<String, dynamic>),
      team1Score1: json['team1_score1'] as int?,
      team1Score2: json['team1_score2'] as int?,
      team2Score1: json['team2_score1'] as int?,
      team2Score2: json['team2_score2'] as int?,
      date: DateTime.parse(dateStr as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'location_id': locationId,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'team1_score1': team1Score1,
      'team1_score2': team1Score2,
      'team2_score1': team2Score1,
      'team2_score2': team2Score2,
      'date': date.toIso8601String().split('T').first,
    };
  }

  Game copyWith({
    String? id,
    String? time,
    String? locationId,
    Team? team1,
    Team? team2,
    int? team1Score1,
    int? team1Score2,
    int? team2Score1,
    int? team2Score2,
    DateTime? date,
  }) {
    return Game(
      id: id ?? this.id,
      time: time ?? this.time,
      locationId: locationId ?? this.locationId,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      team1Score1: team1Score1 ?? this.team1Score1,
      team1Score2: team1Score2 ?? this.team1Score2,
      team2Score1: team2Score1 ?? this.team2Score1,
      team2Score2: team2Score2 ?? this.team2Score2,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game &&
        other.id == id &&
        other.time == time &&
        other.locationId == locationId &&
        other.team1.player1 == team1.player1 &&
        other.team1.player2 == team1.player2 &&
        other.team2.player1 == team2.player1 &&
        other.team2.player2 == team2.player2 &&
        other.team1Score1 == team1Score1 &&
        other.team1Score2 == team1Score2 &&
        other.team2Score1 == team2Score1 &&
        other.team2Score2 == team2Score2 &&
        other.date == date;
  }

  @override
  int get hashCode => id.hashCode;
}
