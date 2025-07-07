import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picklematch/screens/tournament_management_screen.dart';
import 'package:picklematch/bloc/auth/auth_bloc.dart';
import 'package:picklematch/bloc/auth/auth_event.dart';
import 'package:picklematch/bloc/auth/auth_state.dart';
import 'package:picklematch/bloc/tournament/tournament_bloc.dart';
import 'package:picklematch/bloc/tournament/tournament_event.dart';
import 'package:picklematch/bloc/tournament/tournament_state.dart';
import 'package:picklematch/models/user.dart';

// Mock BLoCs for testing
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockTournamentBloc extends MockBloc<TournamentEvent, TournamentState> implements TournamentBloc {}

void main() {
  group('Tournament Management UI Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockTournamentBloc mockTournamentBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockTournamentBloc = MockTournamentBloc();

      // Create a test user
      final testUser = User(
        uid: 'test-uid',
        email: 'test@example.com',
        role: 'admin',
        isActive: true,
        rating: 1500.0,
        name: 'Test Admin',
      );

      // Set up mock auth state
      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(user: testUser, token: 'test-token'),
      );

      // Set up mock tournament state
      when(() => mockTournamentBloc.state).thenReturn(
        TournamentLoaded([]),
      );
    });

    testWidgets('should display tournament management screen', (WidgetTester tester) async {
      print('[DEBUG_LOG] Testing tournament management screen UI');

      // Build the widget with proper BLoC providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<TournamentBloc>.value(value: mockTournamentBloc),
            ],
            child: const TournamentManagementScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      print('[DEBUG_LOG] Widget built successfully');

      // Verify that the tournament management screen is displayed
      expect(find.byType(TournamentManagementScreen), findsOneWidget);
      print('[DEBUG_LOG] Found tournament management screen');

      print('[DEBUG_LOG] Tournament management UI test completed successfully');
    });

    testWidgets('should show basic tournament screen structure', (WidgetTester tester) async {
      print('[DEBUG_LOG] Testing tournament screen structure');

      // Build the widget with proper BLoC providers
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<TournamentBloc>.value(value: mockTournamentBloc),
            ],
            child: const TournamentManagementScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify the screen loads without errors
      expect(find.byType(TournamentManagementScreen), findsOneWidget);
      print('[DEBUG_LOG] Tournament management screen loaded successfully');

      print('[DEBUG_LOG] Tournament screen structure test completed successfully');
    });
  });
}
