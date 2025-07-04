import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:picklematch/bloc/auth/auth_bloc.dart';
import 'package:picklematch/bloc/auth/auth_event.dart';
import 'package:picklematch/bloc/auth/auth_state.dart';
import 'package:picklematch/models/user.dart';
import 'package:picklematch/services/api_service.dart';
import 'package:picklematch/services/storage_service.dart';

@GenerateMocks([ApiService, StorageService])
import 'auth_bloc_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;
  late AuthBloc authBloc;

  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();
    authBloc = AuthBloc(
      apiService: mockApiService,
      storageService: mockStorageService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    final user = User(
      uid: 'test-uid',
      email: 'test@example.com',
      role: 'user',
      isActive: true,
    );

    final inactiveUser = User(
      uid: 'test-uid',
      email: 'test@example.com',
      role: 'user',
      isActive: false,
    );

    const token = 'test-token';

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AppStarted and user is authenticated and active',
      build: () {
        when(mockStorageService.getUser()).thenAnswer((_) async => user);
        when(mockStorageService.getToken()).thenAnswer((_) async => token);
        return authBloc;
      },
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(mockStorageService.getUser()).called(1);
        verify(mockStorageService.getToken()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthVerificationNeeded] when AppStarted and user is authenticated but not active',
      build: () {
        when(mockStorageService.getUser()).thenAnswer((_) async => inactiveUser);
        when(mockStorageService.getToken()).thenAnswer((_) async => token);
        return authBloc;
      },
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthVerificationNeeded>(),
      ],
      verify: (_) {
        verify(mockStorageService.getUser()).called(1);
        verify(mockStorageService.getToken()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when AppStarted and user is not authenticated',
      build: () {
        when(mockStorageService.getUser()).thenAnswer((_) async => null);
        when(mockStorageService.getToken()).thenAnswer((_) async => null);
        return authBloc;
      },
      act: (bloc) => bloc.add(AppStarted()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (_) {
        verify(mockStorageService.getUser()).called(1);
        verify(mockStorageService.getToken()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when LoginRequested and login is successful and user is active',
      build: () {
        when(mockApiService.login(any, any)).thenAnswer((_) async => user);
        when(mockStorageService.saveUser(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveToken(any)).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@example.com', password: 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(mockApiService.login('test@example.com', 'password')).called(1);
        verify(mockStorageService.saveUser(any)).called(1);
        verify(mockStorageService.saveToken(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthVerificationNeeded] when LoginRequested and login is successful but user is not active',
      build: () {
        when(mockApiService.login(any, any)).thenAnswer((_) async => inactiveUser);
        when(mockStorageService.saveUser(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveToken(any)).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@example.com', password: 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthVerificationNeeded>(),
      ],
      verify: (_) {
        verify(mockApiService.login('test@example.com', 'password')).called(1);
        verify(mockStorageService.saveUser(any)).called(1);
        verify(mockStorageService.saveToken(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when LoginRequested and login fails',
      build: () {
        when(mockApiService.login(any, any)).thenThrow(Exception('Login failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: 'test@example.com', password: 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>(),
      ],
      verify: (_) {
        verify(mockApiService.login('test@example.com', 'password')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when LoggedOut',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => token);
        when(mockApiService.logout(any)).thenAnswer((_) async => {});
        when(mockStorageService.clearAuthData()).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(LoggedOut()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockApiService.logout(token)).called(1);
        verify(mockStorageService.clearAuthData()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, RegistrationSuccess, AuthVerificationNeeded] when RegisterRequested and registration is successful',
      build: () {
        when(mockApiService.register(any, any)).thenAnswer((_) async => inactiveUser);
        when(mockStorageService.saveUser(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveToken(any)).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const RegisterRequested(email: 'test@example.com', password: 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<RegistrationSuccess>(),
        isA<AuthVerificationNeeded>(),
      ],
      verify: (_) {
        verify(mockApiService.register('test@example.com', 'password')).called(1);
        verify(mockStorageService.saveUser(any)).called(1);
        verify(mockStorageService.saveToken(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, RegistrationFailure] when RegisterRequested and registration fails',
      build: () {
        when(mockApiService.register(any, any)).thenThrow(Exception('Registration failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const RegisterRequested(email: 'test@example.com', password: 'password')),
      expect: () => [
        isA<AuthLoading>(),
        isA<RegistrationFailure>(),
      ],
      verify: (_) {
        verify(mockApiService.register('test@example.com', 'password')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, VerificationSuccess, AuthAuthenticated] when VerifyEmailRequested and verification is successful',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => token);
        when(mockStorageService.getUser()).thenAnswer((_) async => inactiveUser);
        when(mockApiService.verifyEmail(any)).thenAnswer((_) async => {});
        when(mockStorageService.saveUser(any)).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(VerifyEmailRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<VerificationSuccess>(),
        isA<AuthAuthenticated>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockStorageService.getUser()).called(1);
        verify(mockApiService.verifyEmail(token)).called(1);
        verify(mockStorageService.saveUser(any)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, VerificationFailure] when VerifyEmailRequested and verification fails',
      build: () {
        when(mockStorageService.getToken()).thenAnswer((_) async => token);
        when(mockStorageService.getUser()).thenAnswer((_) async => inactiveUser);
        when(mockApiService.verifyEmail(any)).thenThrow(Exception('Verification failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(VerifyEmailRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<VerificationFailure>(),
      ],
      verify: (_) {
        verify(mockStorageService.getToken()).called(1);
        verify(mockStorageService.getUser()).called(1);
        verify(mockApiService.verifyEmail(token)).called(1);
      },
    );
  });
}