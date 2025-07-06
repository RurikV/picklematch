import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/location.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class GameList extends StatefulWidget {
  final List<Game> games;
  final List<Location> locations;
  final Function(Game) onGameTap;

  const GameList({
    super.key,
    required this.games,
    required this.locations,
    required this.onGameTap,
  });

  @override
  _GameListState createState() => _GameListState();
}

class _GameListState extends State<GameList> {
  Map<String, Player> _players = {};

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      final storageService = StorageService();
      final apiService = ApiService();

      // Try to get players from cache first
      _players = await storageService.getPlayers();

      // If cache is empty or we want fresh data, fetch from API
      if (_players.isEmpty) {
        final token = await storageService.getToken();
        if (token != null) {
          _players = await apiService.getPlayers(token);
          await storageService.savePlayers(_players);
        }
      }

      // Update UI if mounted
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading players: $e');
      // Continue with empty players map - fallback to email-based names
    }
  }

  String _getLocationName(String locationId) {
    final location = widget.locations.firstWhere(
      (loc) => loc.id == locationId,
      orElse: () => Location(id: 'unknown', name: 'Unknown Location'),
    );
    return location.name;
  }

  String _getPlayerName(String? playerId) {
    if (playerId == null) return 'Empty';

    // Look up the player name from the player repository
    final player = _players[playerId];
    if (player != null) {
      return player.getDisplayName();
    }

    // Enhanced fallback logic to ensure names are always displayed
    // Check if playerId looks like an email (contains @)
    if (playerId.contains('@')) {
      // Extract name from email
      return playerId.split('@').first;
    }

    // If playerId doesn't look like an email, it might be a UID
    // Try to find a more user-friendly display
    // For UIDs, we'll show a shortened version with "User" prefix
    if (playerId.length > 10) {
      return 'User ${playerId.substring(0, 8)}';
    }

    // Last resort: return the playerId as-is but with "User" prefix
    return 'User $playerId';
  }

  String _getTeamNames(Team team) {
    final player1 = _getPlayerName(team.player1);
    final player2 = _getPlayerName(team.player2);
    return '$player1 / $player2';
  }

  String _getScoreText(Game game) {
    if (game.team1Score1 == null || game.team1Score2 == null || 
        game.team2Score1 == null || game.team2Score2 == null) {
      return 'No scores';
    }

    return '${game.team1Score1}-${game.team2Score1}, ${game.team1Score2}-${game.team2Score2}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_tennis, size: 64.0, color: Colors.grey),
            const SizedBox(height: 16.0),
            Text(
              'No games found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Try selecting a different date or location',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.games.length,
      itemBuilder: (context, index) {
        final game = widget.games[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () => widget.onGameTap(game),
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time and location
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16.0, color: Colors.blue),
                        const SizedBox(width: 4.0),
                        Text(
                          game.time,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16.0),
                        const Icon(Icons.location_on, size: 16.0, color: Colors.blue),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            _getLocationName(game.locationId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12.0),

                    // Teams and scores
                    Row(
                      children: [
                        // Team 1
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Team 1',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _getTeamNames(game.team1),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // VS
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                        // Team 2
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Team 2',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _getTeamNames(game.team2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Scores if available
                    if (game.team1Score1 != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_score, size: 16.0, color: Colors.green),
                            const SizedBox(width: 4.0),
                            Text(
                              _getScoreText(game),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                    // Available slots indicator
                    if (!game.team1.isFull || !game.team2.isFull)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 16.0,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              'Slots available',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
