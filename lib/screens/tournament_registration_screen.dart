import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/tournament/tournament_bloc.dart';
import '../bloc/tournament/tournament_event.dart';
import '../bloc/tournament/tournament_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../models/tournament.dart';

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
        if (state is TournamentLoading) {
          return const Center(child: CircularProgressIndicator());
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

        return const Center(child: Text('Unknown state'));
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
        if (state is TournamentLoading) {
          return const Center(child: CircularProgressIndicator());
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

        return const Center(child: Text('Unknown state'));
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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