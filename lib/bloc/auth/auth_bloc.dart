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
    on<FacebookSignInRequested>(_onFacebookSignInRequested);
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
                  add(LoggedIn(user: user, token: 'firebase-token'));
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
    emit(AuthLoading());
    try {
      final token = await _storageService.getToken();
      final user = await _storageService.getUser();

      if (token == null || user == null) {
        emit(AuthUnauthenticated());
        return;
      }

      await _apiService.verifyEmail(token);

      // Update user with active status
      final updatedUser = user.copyWith(isActive: true);
      await _storageService.saveUser(updatedUser);

      emit(VerificationSuccess(user: updatedUser, token: token));
      emit(AuthAuthenticated(user: updatedUser, token: token));
    } catch (e) {
      emit(VerificationFailure(error: e.toString()));
    }
  }
  Future<void> _onGoogleSignInRequested(GoogleSignInRequested event, Emitter<AuthState> emit) async {
    print('AuthBloc: Google Sign-In Requested');
    emit(AuthLoading());
    try {
      print('AuthBloc: Calling API service to login with Google');
      final user = await _apiService.loginWithGoogle();
      print('AuthBloc: Google Sign-In successful, user: ${user.email}');

      // In a real app, the token would come from the API
      final token = 'google-token-${DateTime.now().millisecondsSinceEpoch}';

      print('AuthBloc: Saving user and token to storage');
      await _storageService.saveUser(user);
      await _storageService.saveToken(token);

      // Add a small delay to ensure the UI has time to update
      print('AuthBloc: Adding delay before emitting AuthAuthenticated state');
      await Future.delayed(const Duration(milliseconds: 500));

      print('AuthBloc: Emitting AuthAuthenticated state');
      emit(AuthAuthenticated(user: user, token: token));
      print('AuthBloc: AuthAuthenticated state emitted');

      // Force navigation to HomeScreen
      print('AuthBloc: Forcing navigation to HomeScreen');
      // This is handled by the BlocListener in LoginScreen and the BlocBuilder in AppNavigator
    } catch (e) {
      print('AuthBloc: Google Sign-In failed: $e');
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onFacebookSignInRequested(FacebookSignInRequested event, Emitter<AuthState> emit) async {
    print('AuthBloc: Facebook Sign-In Requested');
    emit(AuthLoading());
    try {
      print('AuthBloc: Calling API service to login with Facebook');
      final user = await _apiService.loginWithFacebook();
      print('AuthBloc: Facebook Sign-In successful, user: ${user.email}');

      // In a real app, the token would come from the API
      final token = 'facebook-token-${DateTime.now().millisecondsSinceEpoch}';

      print('AuthBloc: Saving user and token to storage');
      await _storageService.saveUser(user);
      await _storageService.saveToken(token);

      // Add a small delay to ensure the UI has time to update
      print('AuthBloc: Adding delay before emitting AuthAuthenticated state');
      await Future.delayed(const Duration(milliseconds: 500));

      print('AuthBloc: Emitting AuthAuthenticated state');
      emit(AuthAuthenticated(user: user, token: token));
      print('AuthBloc: AuthAuthenticated state emitted');

      // Force navigation to HomeScreen
      print('AuthBloc: Forcing navigation to HomeScreen');
      // This is handled by the BlocListener in LoginScreen and the BlocBuilder in AppNavigator
    } catch (e) {
      print('AuthBloc: Facebook Sign-In failed: $e');
      emit(AuthFailure(error: e.toString()));
    }
  }
}
