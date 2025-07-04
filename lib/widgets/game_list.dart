import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/location.dart';

class GameList extends StatelessWidget {
  final List<Game> games;
  final List<Location> locations;
  final Function(Game) onGameTap;

  const GameList({
    super.key,
    required this.games,
    required this.locations,
    required this.onGameTap,
  });

  String _getLocationName(String locationId) {
    final location = locations.firstWhere(
      (loc) => loc.id == locationId,
      orElse: () => Location(id: 'unknown', name: 'Unknown Location'),
    );
    return location.name;
  }

  String _getTeamNames(Team team) {
    final player1 = team.player1 != null ? team.player1!.split('@').first : 'Empty';
    final player2 = team.player2 != null ? team.player2!.split('@').first : 'Empty';
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
    if (games.isEmpty) {
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
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () => onGameTap(game),
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