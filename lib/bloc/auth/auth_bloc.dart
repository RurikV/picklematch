import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;
  StreamSubscription<dynamic>? _authStateSubscription;

  AuthBloc({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<RegisterRequested>(_onRegisterRequested);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<EmailLinkRequested>(_onEmailLinkRequested);
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    print('AuthBloc: AppStarted event received');
    emit(AuthLoading());
    try {
      print('AuthBloc: Checking local storage for cached user');
      // First check local storage for cached user
      final user = await _storageService.getUser();
      final token = await _storageService.getToken();

      if (user != null && token != null) {
        print('AuthBloc: Found cached user: ${user.email}, isActive: ${user.isActive}');
        if (user.isActive) {
          print('AuthBloc: Emitting AuthAuthenticated state from cached user');
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          print('AuthBloc: Emitting AuthVerificationNeeded state from cached user');
          emit(AuthVerificationNeeded(user: user, token: token));
        }
      } else {
        print('AuthBloc: No cached user found, emitting AuthUnauthenticated');
        emit(AuthUnauthenticated());

        // Cancel any existing subscription
        await _authStateSubscription?.cancel();

        // Listen to Firebase auth state changes
        print('AuthBloc: Setting up listener for Firebase auth state changes');
        _authStateSubscription = _apiService.authStateChanges.listen(
          (user) {
            print('AuthBloc: Auth state changed, user: ${user?.email}');
            if (!isClosed) {  // Check if bloc is still active
              if (user != null) {
                if (user.isActive) {
                  print('AuthBloc: Emitting AuthAuthenticated state from Firebase auth');
                  add(LoggedIn(user: user, token: 'firebase-token'));
                } else {
                  print('AuthBloc: Emitting AuthVerificationNeeded state from Firebase auth');
                  emit(AuthVerificationNeeded(user: user, token: 'firebase-token'));
                }
              }
            }
          },
        );
      }
    } catch (e) {
      print('AuthBloc: Error in AppStarted: $e');
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _apiService.login(event.email, event.password);
      // In a real app, the token would come from the API
      final token = 'dummy-token-${DateTime.now().millisecondsSinceEpoch}';

      await _storageService.saveUser(user);
      await _storageService.saveToken(token);

      if (user.isActive) {
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(AuthVerificationNeeded(user: user, token: token));
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    await _storageService.saveUser(event.user);
    await _storageService.saveToken(event.token);

    if (event.user.isActive) {
      emit(AuthAuthenticated(user: event.user, token: event.token));
    } else {
      emit(AuthVerificationNeeded(user: event.user, token: event.token));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        await _apiService.logout(token);
      }
      await _storageService.clearAuthData();
      emit(AuthUnauthenticated());
    } catch (e) {
      await _storageService.clearAuthData();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _apiService.register(event.email, event.password);
      // In a real app, the token would come from the API
      final token = 'dummy-token-${DateTime.now().millisecondsSinceEpoch}';

      await _storageService.saveUser(user);
      await _storageService.saveToken(token);

      emit(RegistrationSuccess(user: user, token: token));
      emit(AuthVerificationNeeded(user: user, token: token));
    } catch (e) {
      emit(RegistrationFailure(error: e.toString()));
    }
  }

  Future<void> _onVerifyEmailRequested(VerifyEmailRequested event, Emitter<AuthState> emit) async {
    print('AuthBloc: VerifyEmailRequested event received');
    emit(AuthLoading());
    try {
      final token = await _storageService.getToken();
      final user = await _storageService.getUser();

      if (token == null || user == null) {
        print('AuthBloc: No token or user found, emitting AuthUnauthenticated');
        emit(AuthUnauthenticated());
        return;
      }

      // If user is already active, just emit authenticated state
      if (user.isActive) {
        print('AuthBloc: User is already active, emitting AuthAuthenticated directly');
        emit(AuthAuthenticated(user: user, token: token));
        return;
      }

      print('AuthBloc: Calling API service to verify email');
      await _apiService.verifyEmail(token);
      print('AuthBloc: Email verification completed successfully');

      // Update user with active status
      print('AuthBloc: Updating user with active status');
      final updatedUser = user.copyWith(isActive: true);
      await _storageService.saveUser(updatedUser);
      print('AuthBloc: User updated and saved to storage');

      // Add a small delay to ensure the UI has time to update
      print('AuthBloc: Adding delay before emitting success states');
      await Future.delayed(const Duration(milliseconds: 500));

      print('AuthBloc: Emitting VerificationSuccess state');
      emit(VerificationSuccess(user: updatedUser, token: token));

      print('AuthBloc: Emitting AuthAuthenticated state');
      emit(AuthAuthenticated(user: updatedUser, token: token));
    } catch (e) {
      print('AuthBloc: Error in verification process: $e');
      emit(VerificationFailure(error: e.toString()));
    }
  }
  Future<void> _onGoogleSignInRequested(GoogleSignInRequested event, Emitter<AuthState> emit) async {
    print('AuthBloc: Google Sign-In Requested');
    print('AuthBloc: Current state: ${state.runtimeType}');
    emit(AuthLoading());
    print('AuthBloc: Emitted AuthLoading state');

    try {
      print('AuthBloc: Calling API service to login with Google');
      final user = await _apiService.loginWithGoogle();
      print('AuthBloc: Google Sign-In successful, user: ${user.email}, isActive: ${user.isActive}, role: ${user.role}');
      print('AuthBloc: User details - UID: ${user.uid}, Name: ${user.name}, Rating: ${user.rating}');

      // In a real app, the token would come from the API
      final token = 'google-token-${DateTime.now().millisecondsSinceEpoch}';
      print('AuthBloc: Generated token: $token');

      print('AuthBloc: Saving user and token to storage');
      try {
        await _storageService.saveUser(user);
        print('AuthBloc: User saved to storage successfully');
      } catch (storageError) {
        print('AuthBloc: Error saving user to storage: $storageError');
        // Continue even if storage fails
      }

      try {
        await _storageService.saveToken(token);
        print('AuthBloc: Token saved to storage successfully');
      } catch (storageError) {
        print('AuthBloc: Error saving token to storage: $storageError');
        // Continue even if storage fails
      }

      // Add a small delay to ensure the UI has time to update
      print('AuthBloc: Adding delay before emitting state');
      await Future.delayed(const Duration(milliseconds: 500));
      print('AuthBloc: Delay completed');

      // Check if user is active
      if (user.isActive) {
        print('AuthBloc: User is active, emitting AuthAuthenticated state');
        emit(AuthAuthenticated(user: user, token: token));
        print('AuthBloc: AuthAuthenticated state emitted');
      } else {
        print('AuthBloc: User is not active, emitting AuthVerificationNeeded state');
        emit(AuthVerificationNeeded(user: user, token: token));
        print('AuthBloc: AuthVerificationNeeded state emitted');
      }

      // Force navigation based on user state
      print('AuthBloc: Forcing navigation based on user state');
      print('AuthBloc: This is handled by the BlocListener in LoginScreen and the BlocBuilder in AppNavigator');
    } catch (e) {
      print('AuthBloc: Google Sign-In failed: $e');
      print('AuthBloc: Error type: ${e.runtimeType}');
      print('AuthBloc: Full error details: ${e.toString()}');

      // Extract error message for user display
      String errorMessage = e.toString();
      if (e.toString().contains('Exception: Google login error:')) {
        // Extract the user-friendly message from the ApiService exception
        final match = RegExp(r'Exception: Google login error: (.+)').firstMatch(e.toString());
        if (match != null) {
          errorMessage = match.group(1) ?? errorMessage;
          print('AuthBloc: Extracted user-friendly error message: $errorMessage');
        }
      }

      print('AuthBloc: Emitting AuthFailure state with error: $errorMessage');
      emit(AuthFailure(error: errorMessage));
      print('AuthBloc: AuthFailure state emitted');
    }
  }

  // Facebook authentication removed as per requirements

  Future<void> _onEmailLinkRequested(EmailLinkRequested event, Emitter<AuthState> emit) async {
    print('AuthBloc: Email Link Requested for email: ${event.email}');
    emit(AuthLoading());
    try {
      print('AuthBloc: Calling API service to send email link');
      await _apiService.sendEmailLink(event.email);
      print('AuthBloc: Email link sent successfully');

      // Store the email locally for later use when completing the sign-in
      await _storageService.saveEmailForSignIn(event.email);

      // Emit a success state to show a confirmation message
      emit(AuthUnauthenticated());

      // Show a success message (this will be handled in the UI)
      print('AuthBloc: Email link sent, user should check their email');
    } catch (e) {
      print('AuthBloc: Email Link Request failed: $e');
      emit(AuthFailure(error: e.toString()));
    }
  }
}
