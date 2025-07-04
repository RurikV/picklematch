import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import '../platform/platform_service.dart';
import '../widgets/day_picker.dart';
import '../widgets/game_list.dart';
import 'game_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPowerSavingMode = false;
  final PlatformService _platformService = PlatformService();

  @override
  void initState() {
    super.initState();
    _checkPowerSavingMode();
    _loadGames();
  }

  Future<void> _checkPowerSavingMode() async {
    final isPowerSavingMode = await _platformService.isPowerSavingModeEnabled();
    setState(() {
      _isPowerSavingMode = isPowerSavingMode;
    });
  }

  void _loadGames() {
    context.read<GameBloc>().add(const LoadGames());
  }

  void _onDateSelected(DateTime date) {
    context.read<GameBloc>().add(SetSelectedDate(date: date));
  }

  void _onLocationSelected(String locationId) {
    context.read<GameBloc>().add(SetSelectedLocation(locationId: locationId));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PickleMatch'),
        actions: [
          if (_isPowerSavingMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.battery_saver),
            ),
        ],
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state is GameLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GamesLoaded) {
            return SafeArea(
              child: Column(
                children: [
                  // Power saving mode banner
                  if (_isPowerSavingMode)
                    Container(
                      color: Colors.amber.shade100,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: const [
                          Icon(Icons.battery_saver, color: Colors.amber),
                          SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Power saving mode is enabled. Some features may be limited.',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Date picker
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DayPicker(
                      selectedDate: state.selectedDate ?? DateTime.now(),
                      onDateSelected: _onDateSelected,
                    ),
                  ),

                  // Location selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Builder(
                      builder: (context) {
                        print('HomeScreen: Building location dropdown with ${state.locations.length} locations');
                        print('HomeScreen: Locations: ${state.locations.map((loc) => loc.name).join(', ')}');
                        print('HomeScreen: Selected location ID: ${state.selectedLocationId}');

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          ),
                          isExpanded: true,
                          value: state.selectedLocationId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Locations'),
                            ),
                            ...state.locations.map((location) {
                              print('HomeScreen: Adding dropdown item for location: ${location.name} (${location.id})');
                              return DropdownMenuItem<String>(
                                value: location.id,
                                child: Text(location.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            print('HomeScreen: Location dropdown value changed to: $value');
                            if (value != null) {
                              _onLocationSelected(value);
                            } else {
                              // Handle "All Locations" selection
                              print('HomeScreen: "All Locations" selected, reloading games');
                              context.read<GameBloc>().add(const LoadGames());
                            }
                          },
                        );
                      }
                    ),
                  ),

                  // Game list
                  Expanded(
                    child: GameList(
                      games: state.games,
                      locations: state.locations,
                      onGameTap: (game) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameDetailScreen(game: game),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else if (state is GameError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
                  const SizedBox(height: 16.0),
                  Text('Error: ${state.error}'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadGames,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
