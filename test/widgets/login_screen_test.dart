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

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (context) => mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen shows login form initially', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    
    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Assert
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Don\'t have an account? Register'), findsOneWidget);
  });

  testWidgets('LoginScreen toggles between login and register modes', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    
    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Assert - Initially in login mode
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    
    // Act - Tap register link
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle(); // Wait for animation
    
    // Assert - Now in register mode
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    
    // Act - Tap login link
    await tester.tap(find.text('Already have an account? Login'));
    await tester.pumpAndSettle(); // Wait for animation
    
    // Assert - Back to login mode
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('LoginScreen shows loading indicator when AuthLoading state', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthLoading());
    
    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LoginScreen submits login form with valid data', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    
    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    
    // Submit form
    await tester.tap(find.text('Login'));
    
    // Verify
    verify(mockAuthBloc.add(const LoginRequested(
      email: 'test@example.com',
      password: 'password123',
    ))).called(1);
  });

  testWidgets('LoginScreen submits register form with valid data', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    
    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Switch to register mode
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle(); // Wait for animation
    
    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    
    // Submit form
    await tester.tap(find.text('Register'));
    
    // Verify
    verify(mockAuthBloc.add(const RegisterRequested(
      email: 'test@example.com',
      password: 'password123',
    ))).called(1);
  });

  testWidgets('LoginScreen shows validation errors for empty fields', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    
    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Submit form without filling
    await tester.tap(find.text('Login'));
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
    
    // Fill form with invalid email
    await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    
    // Submit form
    await tester.tap(find.text('Login'));
    await tester.pump(); // Rebuild after validation
    
    // Assert
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation error for short password in register mode', (WidgetTester tester) async {
    // Arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    
    // Act - Render login screen
    await tester.pumpWidget(createWidgetUnderTest());
    
    // Switch to register mode
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle(); // Wait for animation
    
    // Fill form with short password
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    
    // Submit form
    await tester.tap(find.text('Register'));
    await tester.pump(); // Rebuild after validation
    
    // Assert
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });
}