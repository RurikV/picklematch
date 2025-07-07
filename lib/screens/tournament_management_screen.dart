import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/tournament/tournament_bloc.dart';
import '../bloc/tournament/tournament_event.dart';
import '../bloc/tournament/tournament_state.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../models/tournament.dart';
import '../models/location.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_state.dart';
import '../bloc/game/game_event.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  _TournamentManagementScreenState createState() => _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen> {
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TournamentBloc>().add(LoadTournamentsByAdmin(authState.user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Management'),
        actions: [
          IconButton(
            icon: Icon(_showCreateForm ? Icons.list : Icons.add),
            onPressed: () {
              setState(() {
                _showCreateForm = !_showCreateForm;
              });
            },
          ),
        ],
      ),
      body: _showCreateForm ? const _CreateTournamentForm() : const _TournamentList(),
    );
  }
}

class _TournamentList extends StatelessWidget {
  const _TournamentList();

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
                    'No tournaments created yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first tournament',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.tournaments.length,
            itemBuilder: (context, index) {
              final tournament = state.tournaments[index];
              return _TournamentCard(tournament: tournament);
            },
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
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context.read<TournamentBloc>().add(LoadTournamentsByAdmin(authState.user.uid));
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

  const _TournamentCard({required this.tournament});

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
            const SizedBox(height: 12),
            Row(
              children: [
                if (tournament.status == TournamentStatus.open)
                  ElevatedButton.icon(
                    onPressed: () => _generateMatches(context, tournament),
                    icon: const Icon(Icons.sports_tennis, size: 16),
                    label: const Text('Generate Games'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (tournament.status == TournamentStatus.closed)
                  ElevatedButton.icon(
                    onPressed: () => _startTournament(context, tournament),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Tournament'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (tournament.status == TournamentStatus.inProgress)
                  ElevatedButton.icon(
                    onPressed: () => _completeTournament(context, tournament),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showTournamentDetails(context, tournament),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generateMatches(BuildContext context, Tournament tournament) {
    if (tournament.registeredPlayers.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 4 players to generate matches'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TournamentBloc>().add(
        GenerateTournamentMatches(
          tournamentId: tournament.id,
          adminUserId: authState.user.uid,
        ),
      );
    }
  }

  void _startTournament(BuildContext context, Tournament tournament) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TournamentBloc>().add(
        StartTournament(
          tournamentId: tournament.id,
          adminUserId: authState.user.uid,
        ),
      );
    }
  }

  void _completeTournament(BuildContext context, Tournament tournament) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TournamentBloc>().add(
        CompleteTournament(
          tournamentId: tournament.id,
          adminUserId: authState.user.uid,
        ),
      );
    }
  }

  void _showTournamentDetails(BuildContext context, Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tournament.name),
        content: Column(
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
            Text('Games: ${tournament.games.length}'),
            if (tournament.minRating != null)
              Text('Min Rating: ${tournament.minRating}'),
            if (tournament.maxRating != null)
              Text('Max Rating: ${tournament.maxRating}'),
          ],
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

class _CreateTournamentForm extends StatefulWidget {
  const _CreateTournamentForm();

  @override
  _CreateTournamentFormState createState() => _CreateTournamentFormState();
}

class _CreateTournamentFormState extends State<_CreateTournamentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minRatingController = TextEditingController();
  final _maxRatingController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedLocationId;
  int _numberOfCourts = 1;
  List<String> _timeSlots = ['09:00', '10:00', '11:00'];

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _minRatingController.dispose();
    _maxRatingController.dispose();
    super.dispose();
  }

  void _loadLocations() {
    final gameState = context.read<GameBloc>().state;
    if (gameState is GamesLoaded) {
      setState(() {
        _locations = gameState.locations;
        if (_locations.isNotEmpty) {
          _selectedLocationId = _locations.first.id;
        }
      });
    } else {
      context.read<GameBloc>().add(const LoadGames());
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addTimeSlot() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((time) {
      if (time != null) {
        final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        if (!_timeSlots.contains(timeString)) {
          setState(() {
            _timeSlots.add(timeString);
            _timeSlots.sort();
          });
        }
      }
    });
  }

  void _removeTimeSlot(String timeSlot) {
    setState(() {
      _timeSlots.remove(timeSlot);
    });
  }

  void _createTournament() {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocationId == null) {
        setState(() {
          _errorMessage = 'Please select a location';
        });
        return;
      }

      if (_timeSlots.isEmpty) {
        setState(() {
          _errorMessage = 'Please add at least one time slot';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<TournamentBloc>().add(
          CreateTournament(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            locationId: _selectedLocationId!,
            date: _selectedDate,
            timeSlots: _timeSlots,
            numberOfCourts: _numberOfCourts,
            adminUserId: authState.user.uid,
            minRating: _minRatingController.text.isNotEmpty 
                ? double.tryParse(_minRatingController.text) 
                : null,
            maxRating: _maxRatingController.text.isNotEmpty 
                ? double.tryParse(_maxRatingController.text) 
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TournamentBloc, TournamentState>(
          listener: (context, state) {
            if (state is TournamentCreated) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tournament created successfully')),
              );
              // Reset form
              _nameController.clear();
              _descriptionController.clear();
              _minRatingController.clear();
              _maxRatingController.clear();
              setState(() {
                _selectedDate = DateTime.now().add(const Duration(days: 1));
                _timeSlots = ['09:00', '10:00', '11:00'];
                _numberOfCourts = 1;
                _errorMessage = null;
              });
              // Reload tournaments
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<TournamentBloc>().add(LoadTournamentsByAdmin(authState.user.uid));
              }
            } else if (state is TournamentError) {
              setState(() {
                _isLoading = false;
                _errorMessage = state.message;
              });
            }
          },
        ),
        BlocListener<GameBloc, GameState>(
          listener: (context, state) {
            if (state is GamesLoaded) {
              setState(() {
                _locations = state.locations;
                if (_locations.isNotEmpty && _selectedLocationId == null) {
                  _selectedLocationId = _locations.first.id;
                }
              });
            }
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a tournament name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Date picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Location dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedLocationId,
                  items: _locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location.id,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocationId = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Number of courts
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Number of Courts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _numberOfCourts.toString(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of courts';
                    }
                    final courts = int.tryParse(value);
                    if (courts == null || courts < 1) {
                      return 'Please enter a valid number of courts';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final courts = int.tryParse(value);
                    if (courts != null && courts > 0) {
                      _numberOfCourts = courts;
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Time slots
                const Text(
                  'Time Slots',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._timeSlots.map((timeSlot) => Chip(
                      label: Text(timeSlot),
                      onDeleted: _timeSlots.length > 1 ? () => _removeTimeSlot(timeSlot) : null,
                    )),
                    ActionChip(
                      label: const Text('+ Add Time'),
                      onPressed: _addTimeSlot,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rating constraints
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minRatingController,
                        decoration: const InputDecoration(
                          labelText: 'Min Rating (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final rating = double.tryParse(value);
                            if (rating == null || rating < 0) {
                              return 'Invalid rating';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxRatingController,
                        decoration: const InputDecoration(
                          labelText: 'Max Rating (optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final rating = double.tryParse(value);
                            if (rating == null || rating < 0) {
                              return 'Invalid rating';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                const SizedBox(height: 24),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTournament,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Create Tournament'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
