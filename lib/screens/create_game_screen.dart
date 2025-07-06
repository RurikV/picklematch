import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import '../models/game.dart';
import '../models/location.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedLocationId;

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocations();
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
      // If GameBloc is not in GamesLoaded state, trigger LoadGames to get locations
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _createGame() {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocationId == null) {
        setState(() {
          _errorMessage = 'Please select a location';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Format time as a string (e.g., "14:30")
      final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Create a new game object
      final newGame = Game(
        id: 'temp-id', // This will be replaced by the server
        time: formattedTime,
        locationId: _selectedLocationId!,
        team1: Team(),
        team2: Team(),
        date: _selectedDate,
      );

      // Dispatch the CreateGame event
      context.read<GameBloc>().add(CreateGame(game: newGame));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Game'),
      ),
      body: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameCreated) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game created successfully')),
            );
            // Reset the form after successful creation
            setState(() {
              _selectedDate = DateTime.now();
              _selectedTime = TimeOfDay.now();
              _errorMessage = null;
            });
          } else if (state is GameError) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.error;
            });
          } else if (state is GamesLoaded) {
            // Update locations when GameBloc loads them
            setState(() {
              _locations = state.locations;
              if (_locations.isNotEmpty && _selectedLocationId == null) {
                _selectedLocationId = _locations.first.id;
              }
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                const SizedBox(height: 16.0),

                // Time picker
                InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                    ),
                  ),
                ),

                const SizedBox(height: 16.0),

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

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                const Spacer(),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createGame,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Create Game'),
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
