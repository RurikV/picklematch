import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picklematch/bloc/auth/auth_bloc.dart';
import 'package:picklematch/bloc/auth/auth_event.dart';
import 'package:picklematch/bloc/auth/auth_state.dart';
import 'package:picklematch/screens/login_screen.dart';
import 'package:picklematch/services/api_service.dart';
import 'package:picklematch/services/storage_service.dart';

@GenerateMocks([AuthBloc, ApiService, StorageService])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> stateController;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    stateController = StreamController<AuthState>.broadcast();

    // Stub the stream property to return our controlled stream
    when(mockAuthBloc.stream).thenAnswer((_) => stateController.stream);
    when(mockAuthBloc.state).thenReturn(AuthInitial());

    // Emit initial state
    stateController.add(AuthInitial());
  });

  tearDown(() {
    stateController.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 1200, // Increased height to accommodate the full LoginScreen
          child: BlocProvider<AuthBloc>(
            create: (context) => mockAuthBloc,
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }

  // Helper method to emit state through stream
  void emitState(AuthState state) {
    when(mockAuthBloc.state).thenReturn(state);
    stateController.add(state);
  }

  testWidgets('LoginScreen shows login form initially', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert - Check for main welcome text
    expect(find.text('Welcome to Pickle Match'), findsOneWidget);

    // Assert - Check for tab structure
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Email/Pwd'), findsOneWidget);
    expect(find.text('Email Link'), findsOneWidget);

    // Switch to Email/Password tab to check its content
    await tester.tap(find.text('Email/Pwd'));
    await tester.pumpAndSettle();

    // Assert - Check Email/Password tab content
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Don\'t have an account? Register'), findsOneWidget);
  });



  testWidgets('LoginScreen submits login form with valid data', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());

    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());

    // Switch to Email/Password tab
    await tester.tap(find.text('Email/Pwd'));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    // Submit form
    await tester.tap(find.byType(ElevatedButton));

    // Verify
    verify(mockAuthBloc.add(const LoginRequested(
      email: 'test@example.com',
      password: 'password123',
    ))).called(1);
  });


  testWidgets('LoginScreen shows validation errors for empty fields', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());

    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());

    // Switch to Email/Password tab
    await tester.tap(find.text('Email/Pwd'));
    await tester.pumpAndSettle();

    // Submit form without filling
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Rebuild after validation

    // Assert
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation error for invalid email', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());

    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());

    // Switch to Email/Password tab
    await tester.tap(find.text('Email/Pwd'));
    await tester.pumpAndSettle();

    // Fill form with invalid email
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    // Submit form
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Rebuild after validation

    // Assert
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

}
