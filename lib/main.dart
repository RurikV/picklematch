import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:picklematch/bloc/auth/auth_bloc.dart';
import 'package:picklematch/bloc/auth/auth_event.dart';
import 'package:picklematch/bloc/auth/auth_state.dart';
import 'package:picklematch/bloc/game/game_bloc.dart';
import 'package:picklematch/bloc/tournament/tournament_bloc.dart';
import 'package:picklematch/screens/login_screen.dart';
import 'package:picklematch/screens/verification_screen.dart';
import 'package:picklematch/widgets/animated_loading_widget.dart';
import 'package:picklematch/widgets/rive_animation_widget.dart';
import 'screens/main_navigation_screen.dart';
import 'package:picklematch/services/api_service.dart';
import 'package:picklematch/services/storage_service.dart';
import 'package:picklematch/platform/platform_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize API service (which initializes Firebase)
  final apiService = ApiService();
  await apiService.initialize();

  // Initialize platform service
  final platformService = PlatformService();
  await platformService.initialize();

  runApp(MyApp(apiService: apiService, platformService: platformService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final PlatformService platformService;

  const MyApp({super.key, required this.apiService, required this.platformService});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(
          create: (context) => apiService,
        ),
        RepositoryProvider<StorageService>(
          create: (context) => StorageService(),
        ),
        RepositoryProvider<PlatformService>(
          create: (context) => platformService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            )..add(AppStarted()),
          ),
          BlocProvider<GameBloc>(
            create: (context) => GameBloc(
              apiService: context.read<ApiService>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider<TournamentBloc>(
            create: (context) => TournamentBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'PickleMatch',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 2,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          home: const AppNavigator(),
        ),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('AppNavigator: BlocBuilder received state: ${state.runtimeType}');
        if (state is AuthInitial || state is AuthLoading) {
          print('AppNavigator: Showing loading screen for ${state.runtimeType}');
          return Scaffold(
            body: AnimatedBackgroundWidget(
              child: const Center(
                child: AnimatedLoadingWidget(
                  message: 'Loading PickleMatch...',
                  primaryColor: Colors.blue,
                  secondaryColor: Colors.blueAccent,
                  size: 120.0,
                ),
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          print('AppNavigator: Navigating to MainNavigationScreen for AuthAuthenticated state');
          return const MainNavigationScreen();
        } else if (state is AuthVerificationNeeded) {
          print('AppNavigator: Navigating to VerificationScreen for AuthVerificationNeeded state');
          return const VerificationScreen();
        } else {
          print('AppNavigator: Navigating to LoginScreen for ${state.runtimeType} state');
          return const LoginScreen();
        }
      },
    );
  }
}
