import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Firebase Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user data provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

/// Login state notifier provider
final loginProvider =
    StateNotifierProvider<LoginNotifier, AsyncValue<UserModel?>>((ref) {
      return LoginNotifier(ref.watch(authServiceProvider));
    });

/// Login state notifier
class LoginNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  LoginNotifier(this._authService) : super(const AsyncValue.data(null));

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _authService.login(email: email, password: password);
    });
  }

  /// Logout
  Future<void> logout() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _authService.logout();
      return null;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Registration state notifier provider
final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, AsyncValue<UserModel?>>((ref) {
      return RegistrationNotifier(ref.watch(authServiceProvider));
    });

/// Registration state notifier
class RegistrationNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  RegistrationNotifier(this._authService) : super(const AsyncValue.data(null));

  /// Register a new student
  Future<void> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String enrollmentId,
    required int year,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _authService.registerStudent(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        enrollmentId: enrollmentId,
        year: year,
      );
    });
  }

  /// Register a new admin
  Future<void> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _authService.registerAdmin(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Password reset provider
final passwordResetProvider =
    StateNotifierProvider<PasswordResetNotifier, AsyncValue<bool>>((ref) {
      return PasswordResetNotifier(ref.watch(authServiceProvider));
    });

/// Password reset state notifier
class PasswordResetNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthService _authService;

  PasswordResetNotifier(this._authService)
    : super(const AsyncValue.data(false));

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _authService.sendPasswordResetEmail(email);
      return true;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(false);
  }
}
