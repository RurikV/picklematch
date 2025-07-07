import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/tournament/tournament_bloc.dart';
import '../bloc/tournament/tournament_event.dart';
import '../bloc/tournament/tournament_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../models/tournament.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../services/firebase_service.dart';

class TournamentRegistrationScreen extends StatefulWidget {
  const TournamentRegistrationScreen({super.key});

  @override
  _TournamentRegistrationScreenState createState() => _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState extends State<TournamentRegistrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.uid;
    }
  }

  void _loadTournaments() {
    if (_currentUserId != null) {
      if (_tabController.index == 0) {
        // Load open tournaments
        context.read<TournamentBloc>().add(LoadOpenTournaments(_currentUserId!));
      } else {
        // Load player's registered tournaments
        context.read<TournamentBloc>().add(LoadPlayerTournaments(_currentUserId!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _loadTournaments();
          },
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.search)),
            Tab(text: 'My Tournaments', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: BlocListener<TournamentBloc, TournamentState>(
        listener: (context, state) {
          if (state is TournamentRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Reload tournaments after successful registration
            _loadTournaments();
          } else if (state is TournamentUnregistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.blue,
              ),
            );
            // Reload tournaments after successful unregistration
            _loadTournaments();
          } else if (state is TournamentGameScoresUpdated) {
            // Handle game scores updated state to prevent infinite loading
            // when returning from games screen after saving scores
            _loadTournaments();
          } else if (state is TournamentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _AvailableTournamentsTab(currentUserId: _currentUserId),
            _MyTournamentsTab(currentUserId: _currentUserId),
          ],
        ),
      ),
    );
  }
}

class _AvailableTournamentsTab extends StatelessWidget {
  final String? currentUserId;

  const _AvailableTournamentsTab({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentBloc, TournamentState>(
      builder: (context, state) {
        if (state is TournamentLoading || state is TournamentOperationInProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (state is TournamentOperationInProgress) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.operation,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        } else if (state is TournamentLoaded) {
          if (state.tournaments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tournaments available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new tournaments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (currentUserId != null) {
                context.read<TournamentBloc>().add(LoadOpenTournaments(currentUserId!));
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tournaments.length,
              itemBuilder: (context, index) {
                final tournament = state.tournaments[index];
                return _TournamentCard(
                  tournament: tournament,
                  currentUserId: currentUserId,
                  isRegistered: false,
                );
              },
            ),
          );
        } else if (state is TournamentRegistrationSuccess || 
                   state is TournamentUnregistrationSuccess) {
          // For registration/unregistration success, reload the tournaments
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (currentUserId != null) {
              context.read<TournamentBloc>().add(LoadOpenTournaments(currentUserId!));
            }
          });
          return const Center(child: CircularProgressIndicator());
        } else if (state is TournamentError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (currentUserId != null) {
                      context.read<TournamentBloc>().add(LoadOpenTournaments(currentUserId!));
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Handle any remaining states by showing loading
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _MyTournamentsTab extends StatelessWidget {
  final String? currentUserId;

  const _MyTournamentsTab({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentBloc, TournamentState>(
      builder: (context, state) {
        if (state is TournamentLoading || state is TournamentOperationInProgress) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (state is TournamentOperationInProgress) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.operation,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        } else if (state is TournamentLoaded) {
          if (state.tournaments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tournaments registered',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Register for tournaments in the Available tab',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (currentUserId != null) {
                context.read<TournamentBloc>().add(LoadPlayerTournaments(currentUserId!));
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tournaments.length,
              itemBuilder: (context, index) {
                final tournament = state.tournaments[index];
                return _TournamentCard(
                  tournament: tournament,
                  currentUserId: currentUserId,
                  isRegistered: true,
                );
              },
            ),
          );
        } else if (state is TournamentRegistrationSuccess || 
                   state is TournamentUnregistrationSuccess) {
          // For registration/unregistration success, reload the tournaments
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (currentUserId != null) {
              context.read<TournamentBloc>().add(LoadPlayerTournaments(currentUserId!));
            }
          });
          return const Center(child: CircularProgressIndicator());
        } else if (state is TournamentError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (currentUserId != null) {
                      context.read<TournamentBloc>().add(LoadPlayerTournaments(currentUserId!));
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Handle any remaining states by showing loading
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final String? currentUserId;
  final bool isRegistered;

  const _TournamentCard({
    required this.tournament,
    required this.currentUserId,
    required this.isRegistered,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: tournament.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tournament.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(tournament.date),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${tournament.registeredPlayers.length} players',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (tournament.timeSlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Times: ${tournament.timeSlots.join(', ')}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
            if (tournament.minRating != null || tournament.maxRating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Rating: ${tournament.minRating ?? 'Any'} - ${tournament.maxRating ?? 'Any'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isRegistered && tournament.status == TournamentStatus.open)
                  ElevatedButton.icon(
                    onPressed: () => _registerForTournament(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                if (isRegistered && tournament.status == TournamentStatus.open)
                  ElevatedButton.icon(
                    onPressed: () => _unregisterFromTournament(context),
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('Unregister'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                if (tournament.status != TournamentStatus.open)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tournament.status == TournamentStatus.closed
                          ? 'Registration Closed'
                          : tournament.status == TournamentStatus.inProgress
                              ? 'In Progress'
                              : tournament.status == TournamentStatus.completed
                                  ? 'Completed'
                                  : 'Cancelled',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                if (tournament.games.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showTournamentGames(context),
                    icon: const Icon(Icons.sports_tennis, size: 16),
                    label: const Text('View Games'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => _showTournamentDetails(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _registerForTournament(BuildContext context) {
    if (currentUserId != null) {
      context.read<TournamentBloc>().add(
        RegisterForTournament(
          tournamentId: tournament.id,
          playerId: currentUserId!,
        ),
      );
    }
  }

  void _unregisterFromTournament(BuildContext context) {
    if (currentUserId != null) {
      context.read<TournamentBloc>().add(
        UnregisterFromTournament(
          tournamentId: tournament.id,
          playerId: currentUserId!,
        ),
      );
    }
  }

  void _showTournamentDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tournament.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${tournament.description}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('EEEE, MMMM d, yyyy').format(tournament.date)}'),
              const SizedBox(height: 8),
              Text('Time Slots: ${tournament.timeSlots.join(', ')}'),
              const SizedBox(height: 8),
              Text('Courts: ${tournament.numberOfCourts}'),
              const SizedBox(height: 8),
              Text('Registered Players: ${tournament.registeredPlayers.length}'),
              const SizedBox(height: 8),
              Text('Status: ${tournament.status.name.toUpperCase()}'),
              if (tournament.minRating != null) ...[
                const SizedBox(height: 8),
                Text('Min Rating: ${tournament.minRating}'),
              ],
              if (tournament.maxRating != null) ...[
                const SizedBox(height: 8),
                Text('Max Rating: ${tournament.maxRating}'),
              ],
              if (tournament.games.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Games: ${tournament.games.length}'),
              ],
            ],
          ),
        ),
        actions: [
          if (tournament.games.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTournamentGames(context);
              },
              child: const Text('View Games'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTournamentGames(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentGamesScreen(tournament: tournament),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TournamentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case TournamentStatus.open:
        color = Colors.green;
        label = 'Open';
        break;
      case TournamentStatus.closed:
        color = Colors.orange;
        label = 'Closed';
        break;
      case TournamentStatus.inProgress:
        color = Colors.blue;
        label = 'In Progress';
        break;
      case TournamentStatus.completed:
        color = Colors.grey;
        label = 'Completed';
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}

class TournamentGamesScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentGamesScreen({super.key, required this.tournament});

  @override
  _TournamentGamesScreenState createState() => _TournamentGamesScreenState();
}

class _TournamentGamesScreenState extends State<TournamentGamesScreen> {
  final Map<String, Player> _players = {};
  bool _isLoading = true;
  late Tournament _tournament;

  @override
  void initState() {
    super.initState();
    _tournament = widget.tournament;
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      final firebaseService = FirebaseService();

      // Get all unique player UIDs from tournament games
      final Set<String> playerUids = {};
      for (final game in _tournament.games) {
        if (game.team1.player1 != null) playerUids.add(game.team1.player1!);
        if (game.team1.player2 != null) playerUids.add(game.team1.player2!);
        if (game.team2.player1 != null) playerUids.add(game.team2.player1!);
        if (game.team2.player2 != null) playerUids.add(game.team2.player2!);
      }

      // Load player data for each UID
      for (final uid in playerUids) {
        try {
          final player = await firebaseService.getPlayer(uid);
          if (player != null) {
            _players[uid] = player;
          }
        } catch (e) {
          print('Error loading player $uid: $e');
        }
      }
    } catch (e) {
      print('Error loading player data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPlayerName(String? playerId) {
    if (playerId == null) return 'Empty';

    final player = _players[playerId];
    if (player != null) {
      return player.getDisplayName();
    }

    // Fallback logic similar to game_list.dart
    if (playerId.contains('@')) {
      return playerId.split('@').first;
    }

    if (playerId.length > 10) {
      return 'User ${playerId.substring(0, 8)}';
    }

    return 'User $playerId';
  }

  String _getTeamNames(Team team) {
    final player1 = _getPlayerName(team.player1);
    final player2 = _getPlayerName(team.player2);
    return '$player1 / $player2';
  }

  String _getScoreText(TournamentGame game) {
    if (game.team1Score1 == null || game.team1Score2 == null || 
        game.team2Score1 == null || game.team2Score2 == null) {
      return 'No scores';
    }

    return '${game.team1Score1}-${game.team2Score1}, ${game.team1Score2}-${game.team2Score2}';
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.scheduled:
        return Colors.blue;
      case GameStatus.inProgress:
        return Colors.orange;
      case GameStatus.completed:
        return Colors.green;
      case GameStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TournamentBloc, TournamentState>(
      listener: (context, state) {
        if (state is TournamentGameScoresUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game scores updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Update the tournament data
          setState(() {
            _tournament = state.tournament;
          });
        } else if (state is TournamentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is TournamentOperationInProgress) {
          // Handle the loading state - no action needed as the UI will show the updated tournament data
          // This prevents infinite loading by acknowledging the state
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_tournament.name} - Games'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tournament.games.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_tennis, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No games scheduled yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tournament.games.length,
                    itemBuilder: (context, index) {
                      final game = _tournament.games[index];
                      return _buildGameCard(game);
                    },
                  ),
      ),
    );
  }

  void _showScoreInputDialog(TournamentGame game) {
    final team1Score1Controller = TextEditingController(
      text: game.team1Score1?.toString() ?? '',
    );
    final team1Score2Controller = TextEditingController(
      text: game.team1Score2?.toString() ?? '',
    );
    final team2Score1Controller = TextEditingController(
      text: game.team2Score1?.toString() ?? '',
    );
    final team2Score2Controller = TextEditingController(
      text: game.team2Score2?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Scores - ${game.timeSlot}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Court ${game.courtNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Team 1 scores
              Text(
                'Team 1: ${_getTeamNames(game.team1)}',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: team1Score1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Set 1',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: team1Score2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Set 2',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Team 2 scores
              Text(
                'Team 2: ${_getTeamNames(game.team2)}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: team2Score1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Set 1',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: team2Score2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Set 2',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateGameScores(
              game,
              team1Score1Controller.text,
              team1Score2Controller.text,
              team2Score1Controller.text,
              team2Score2Controller.text,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Save Scores'),
          ),
        ],
      ),
    );
  }

  void _updateGameScores(
    TournamentGame game,
    String team1Score1Text,
    String team1Score2Text,
    String team2Score1Text,
    String team2Score2Text,
  ) {
    // Validate input
    final team1Score1 = int.tryParse(team1Score1Text);
    final team1Score2 = int.tryParse(team1Score2Text);
    final team2Score1 = int.tryParse(team2Score1Text);
    final team2Score2 = int.tryParse(team2Score2Text);

    if (team1Score1 == null || team1Score2 == null || 
        team2Score1 == null || team2Score2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid scores for all sets'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (team1Score1 < 0 || team1Score2 < 0 || team2Score1 < 0 || team2Score2 < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scores cannot be negative'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to update scores'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Close dialog
    Navigator.of(context).pop();

    // Update scores via bloc
    context.read<TournamentBloc>().add(
      UpdateTournamentGameScores(
        tournamentId: _tournament.id,
        gameId: game.id,
        team1Score1: team1Score1,
        team1Score2: team1Score2,
        team2Score1: team2Score1,
        team2Score2: team2Score2,
        userId: authState.user.uid,
      ),
    );
  }

  Widget _buildGameCard(TournamentGame game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game header with time, court, and status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        game.timeSlot,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.sports_tennis, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Court ${game.courtNumber}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
                      const SizedBox(height: 4),
                      Text(
                        _getTeamNames(game.team1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // VS and scores
                GestureDetector(
                  onTap: () => _showScoreInputDialog(game),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getScoreText(game),
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ],
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
                      const SizedBox(height: 4),
                      Text(
                        _getTeamNames(game.team2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
