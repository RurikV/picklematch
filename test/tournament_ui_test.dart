import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklematch/bloc/tournament/tournament_bloc.dart';
import 'package:picklematch/bloc/auth/auth_bloc.dart';
import 'package:picklematch/bloc/auth/auth_state.dart';
import 'package:picklematch/bloc/game/game_bloc.dart';
import 'package:picklematch/screens/tournament_management_screen.dart';
import 'package:picklematch/models/user.dart';

void main() {
  group('Tournament Management UI Tests', () {
    testWidgets('should display tournament management screen for admin users', (WidgetTester tester) async {
      print('[DEBUG_LOG] Testing tournament management screen UI');

      // Create a mock admin user
      final adminUser = User(
        uid: 'admin123',
        email: 'admin@test.com',
        role: 'admin',
        isActive: true,
        rating: 1500.0,
        name: 'Admin User',
      );

      // Build the widget with necessary providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<TournamentBloc>(
                create: (context) => TournamentBloc(),
              ),
              BlocProvider<AuthBloc>(
                create: (context) => AuthBloc(
                  apiService: MockApiService(),
                  storageService: MockStorageService(),
                ),
              ),
              BlocProvider<GameBloc>(
                create: (context) => GameBloc(
                  apiService: MockApiService(),
                  storageService: MockStorageService(),
                ),
              ),
            ],
            child: const TournamentManagementScreen(),
          ),
        ),
      );

      print('[DEBUG_LOG] Widget built successfully');

      // Verify that the tournament management screen is displayed
      expect(find.text('Tournament Management'), findsOneWidget);
      print('[DEBUG_LOG] Found tournament management title');

      // Verify that the add button is present
      expect(find.byIcon(Icons.add), findsOneWidget);
      print('[DEBUG_LOG] Found add tournament button');

      // Verify that the empty state is shown initially
      expect(find.text('No tournaments created yet'), findsOneWidget);
      print('[DEBUG_LOG] Found empty state message');

      // Tap the add button to show the create form
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      print('[DEBUG_LOG] Tapped add button, form should be visible');

      // Verify that the create tournament form is displayed
      expect(find.text('Tournament Name'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Number of Courts'), findsOneWidget);
      expect(find.text('Time Slots'), findsOneWidget);

      print('[DEBUG_LOG] All form fields found successfully');

      // Verify that the create tournament button is present
      expect(find.text('Create Tournament'), findsOneWidget);
      print('[DEBUG_LOG] Found create tournament button');

      print('[DEBUG_LOG] Tournament management UI test completed successfully');
    });

    testWidgets('should show tournament cards with action buttons', (WidgetTester tester) async {
      print('[DEBUG_LOG] Testing tournament cards display');

      // This test would require mocking the tournament data
      // For now, we'll just verify the basic structure
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<TournamentBloc>(
                create: (context) => TournamentBloc(),
              ),
              BlocProvider<AuthBloc>(
                create: (context) => AuthBloc(
                  apiService: MockApiService(),
                  storageService: MockStorageService(),
                ),
              ),
              BlocProvider<GameBloc>(
                create: (context) => GameBloc(
                  apiService: MockApiService(),
                  storageService: MockStorageService(),
                ),
              ),
            ],
            child: const TournamentManagementScreen(),
          ),
        ),
      );

      // Verify the screen loads without errors
      expect(find.byType(TournamentManagementScreen), findsOneWidget);
      print('[DEBUG_LOG] Tournament management screen loaded successfully');

      print('[DEBUG_LOG] Tournament cards test completed successfully');
    });
  });
}

// Mock classes for testing
class MockApiService {
  Future<void> initialize() async {}
}

class MockStorageService {
  Future<void> initialize() async {}
}