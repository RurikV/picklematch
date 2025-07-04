import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;

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
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Listen to Firebase auth state changes
      _apiService.authStateChanges.listen((user) {
        if (user != null) {
          if (user.isActive) {
            emit(AuthAuthenticated(user: user, token: 'firebase-token'));
          } else {
            emit(AuthVerificationNeeded(user: user, token: 'firebase-token'));
          }
        } else {
          emit(AuthUnauthenticated());
        }
      });

      // Also check local storage for cached user
      final user = await _storageService.getUser();
      final token = await _storageService.getToken();

      if (user != null && token != null) {
        if (user.isActive) {
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          emit(AuthVerificationNeeded(user: user, token: token));
        }
      } else {
        // If no cached user, wait for Firebase auth state
      }
    } catch (e) {
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
}
