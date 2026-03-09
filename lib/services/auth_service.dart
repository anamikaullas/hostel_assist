import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import '../constants/index.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Authentication service handling user login, registration, and user management
/// Business logic layer between UI and Firebase Auth
class AuthService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();

  AuthService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseAuth get _auth => _firebaseService.auth;
  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Register a new student
  Future<UserModel> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String enrollmentId,
    required int year,
  }) async {
    try {
      _logger.i('Registering student: $email');

      // Validate input
      if (!email.isValidEmail) {
        throw ValidationException('Invalid email format');
      }
      if (password.length < AppConstants.minPasswordLength) {
        throw ValidationException(
          'Password must be at least ${AppConstants.minPasswordLength} characters',
        );
      }

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create user document in Firestore
      final userModel = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        role: AppConstants.roleStudent,
        phoneNumber: phoneNumber,
        enrollmentId: enrollmentId,
        year: year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .set(userModel.toJson());

      _logger.i('Student registered successfully: $uid');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during registration', error: e);
      throw AuthException(_getAuthErrorMessage(e), code: e.code, details: e);
    } catch (e) {
      _logger.e('Error during student registration', error: e);
      if (e is HostelAssistException) rethrow;
      throw AuthException('Registration failed: ${e.toString()}', details: e);
    }
  }

  /// Register a new admin
  Future<UserModel> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      _logger.i('Registering admin: $email');

      // Validate input
      if (!email.isValidEmail) {
        throw ValidationException('Invalid email format');
      }
      if (password.length < AppConstants.minPasswordLength) {
        throw ValidationException(
          'Password must be at least ${AppConstants.minPasswordLength} characters',
        );
      }

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Create user document in Firestore
      final userModel = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        role: AppConstants.roleAdmin,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .set(userModel.toJson());

      _logger.i('Admin registered successfully: $uid');
      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during admin registration', error: e);
      throw AuthException(_getAuthErrorMessage(e), code: e.code, details: e);
    } catch (e) {
      _logger.e('Error during admin registration', error: e);
      if (e is HostelAssistException) rethrow;
      throw AuthException('Registration failed: ${e.toString()}', details: e);
    }
  }

  /// Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Logging in user: $email');

      // Validate input
      if (!email.isValidEmail) {
        throw ValidationException('Invalid email format');
      }

      // Sign in with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw NotFoundException('User data not found in database');
      }

      final loginData = Map<String, dynamic>.from(userDoc.data()!);
      loginData['uid'] ??= uid;
      final userModel = UserModel.fromJson(loginData);
      _logger.i('User logged in successfully: $uid (${userModel.role})');

      return userModel;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during login', error: e);
      throw AuthException(_getAuthErrorMessage(e), code: e.code, details: e);
    } catch (e) {
      _logger.e('Error during login', error: e);
      if (e is HostelAssistException) rethrow;
      throw AuthException('Login failed: ${e.toString()}', details: e);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _firebaseService.signOut();
      _logger.i('User logged out');
    } catch (e) {
      _logger.e('Error during logout', error: e);
      throw AuthException('Logout failed: ${e.toString()}', details: e);
    }
  }

  /// Get user data by ID
  Future<UserModel> getUserById(String uid) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw NotFoundException('User not found: $uid');
      }

      final userData = Map<String, dynamic>.from(userDoc.data()!);
      userData['uid'] ??= uid;
      return UserModel.fromJson(userData);
    } catch (e) {
      _logger.e('Error fetching user data', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to fetch user: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get current logged-in user data
  /// If the user is authenticated but has no Firestore document,
  /// a default document is created automatically to prevent errors.
  Future<UserModel?> getCurrentUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      return await getUserById(user.uid);
    } on NotFoundException {
      // User exists in Firebase Auth but not in Firestore.
      // Auto-create the missing Firestore document.
      _logger.w(
        'Firestore document missing for authenticated user ${user.uid}. '
        'Auto-creating document.',
      );
      return await _createMissingUserDocument(user);
    } catch (e) {
      _logger.e('Error fetching current user data', error: e);
      return null;
    }
  }

  /// Creates a Firestore user document for an authenticated user
  /// whose document is missing (e.g., created via Firebase console).
  Future<UserModel> _createMissingUserDocument(User user) async {
    final now = DateTime.now();
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? 'unknown@email.com',
      fullName: user.displayName ?? 'User',
      role: AppConstants.roleStudent, // Default to student
      phoneNumber: user.phoneNumber ?? '',
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(userModel.toJson());

    _logger.i('Auto-created Firestore document for user: ${user.uid}');
    return userModel;
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update(updates);

      _logger.i('User profile updated: $uid');
    } catch (e) {
      _logger.e('Error updating user profile', error: e);
      throw FirestoreException(
        'Failed to update profile: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during password reset', error: e);
      throw AuthException(_getAuthErrorMessage(e), code: e.code, details: e);
    } catch (e) {
      _logger.e('Error sending password reset email', error: e);
      throw AuthException(
        'Failed to send password reset email: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}
