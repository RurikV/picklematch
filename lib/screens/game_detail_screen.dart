import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import '../models/game.dart';
import '../models/location.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _team1Score1Controller = TextEditingController();
  final TextEditingController _team1Score2Controller = TextEditingController();
  final TextEditingController _team2Score1Controller = TextEditingController();
  final TextEditingController _team2Score2Controller = TextEditingController();

  late Game _game;
  Location? _location;
  Map<String, Player> _players = {};

  @override
  void initState() {
    super.initState();
    _game = widget.game;

    // Initialize score controllers
    _team1Score1Controller.text = _game.team1Score1?.toString() ?? '';
    _team1Score2Controller.text = _game.team1Score2?.toString() ?? '';
    _team2Score1Controller.text = _game.team2Score1?.toString() ?? '';
    _team2Score2Controller.text = _game.team2Score2?.toString() ?? '';

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Find location
    final gameState = context.read<GameBloc>().state;
    if (gameState is GamesLoaded) {
      _location = gameState.locations.firstWhere(
        (loc) => loc.id == _game.locationId,
        orElse: () => Location(id: 'unknown', name: 'Unknown Location'),
      );
    }

    // Load players
    _loadPlayers();
  }

  @override
  void dispose() {
    _team1Score1Controller.dispose();
    _team1Score2Controller.dispose();
    _team2Score1Controller.dispose();
    _team2Score2Controller.dispose();
    _animationController.dispose();
    super.dispose();
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

  void _joinTeam(String team) {
    context.read<GameBloc>().add(JoinGame(gameId: _game.id, team: team));
  }

  void _saveScores() {
    if (_team1Score1Controller.text.isEmpty ||
        _team1Score2Controller.text.isEmpty ||
        _team2Score1Controller.text.isEmpty ||
        _team2Score2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all scores')),
      );
      return;
    }

    context.read<GameBloc>().add(
      UpdateGameResult(
        gameId: _game.id,
        team1Score1: int.parse(_team1Score1Controller.text),
        team1Score2: int.parse(_team1Score2Controller.text),
        team2Score1: int.parse(_team2Score1Controller.text),
        team2Score2: int.parse(_team2Score2Controller.text),
      ),
    );
  }

  void _deleteGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Game'),
        content: const Text('Are you sure you want to delete this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.read<GameBloc>().add(DeleteGame(gameId: _game.id));
              // Navigation will happen when GameDeleted state is received
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getPlayerName(String? playerId) {
    if (playerId == null) return 'Empty';

    // Look up the player name from the player repository
    final player = _players[playerId];
    if (player != null) {
      return player.getDisplayName();
    }

    // Fallback to email-based name if player not found in repository
    return playerId.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Details'),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated && state.user.role == 'admin') {
                return IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteGame,
                  tooltip: 'Delete Game',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameResultUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game result updated successfully')),
            );
            setState(() {
              _game = state.game;
            });
          } else if (state is GameJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Joined game successfully')),
            );
            setState(() {
              _game = state.game;
            });
          } else if (state is GameDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game deleted successfully')),
            );
            Navigator.of(context).pop();
          } else if (state is GameError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game info card
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 8.0),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(_game.date),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 8.0),
                              Text(
                                _game.time,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8.0),
                              Text(
                                _location?.name ?? 'Unknown Location',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Teams and scores
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teams',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16.0),

                          // Team 1
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Team 1',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text('Player 1: ${_getPlayerName(_game.team1.player1)}'),
                                    Text('Player 2: ${_getPlayerName(_game.team1.player2)}'),
                                  ],
                                ),
                              ),
                              if (!_game.team1.isFull)
                                ElevatedButton(
                                  onPressed: () => _joinTeam('team1'),
                                  child: const Text('Join'),
                                ),
                            ],
                          ),

                          const Divider(height: 32.0),

                          // Team 2
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Team 2',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text('Player 1: ${_getPlayerName(_game.team2.player1)}'),
                                    Text('Player 2: ${_getPlayerName(_game.team2.player2)}'),
                                  ],
                                ),
                              ),
                              if (!_game.team2.isFull)
                                ElevatedButton(
                                  onPressed: () => _joinTeam('team2'),
                                  child: const Text('Join'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24.0),

                  // Scores
                  Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scores',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16.0),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Team 1',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60.0,
                                          child: TextField(
                                            controller: _team1Score1Controller,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                                vertical: 8.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        SizedBox(
                                          width: 60.0,
                                          child: TextField(
                                            controller: _team1Score2Controller,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                                vertical: 8.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16.0),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Team 2',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60.0,
                                          child: TextField(
                                            controller: _team2Score1Controller,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                                vertical: 8.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        SizedBox(
                                          width: 60.0,
                                          child: TextField(
                                            controller: _team2Score2Controller,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                                vertical: 8.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16.0),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveScores,
                              child: const Text('Save Scores'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
