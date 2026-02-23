import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import '../utils/index.dart';

/// Core Firebase service handling initialization and common operations
/// All Firebase-related services should use this as a dependency
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final Logger _logger = Logger();

  // Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Firebase
  /// Should be called once at app startup
  Future<void> initialize() async {
    if (_initialized) {
      _logger.i('Firebase already initialized');
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
      _logger.i('Firebase initialized successfully');

      // Configure Firestore settings
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _logger.i('Firestore settings configured');
    } catch (e) {
      _logger.e('Failed to initialize Firebase', error: e);
      throw FirestoreException(
        'Failed to initialize Firebase: ${e.toString()}',
        code: 'firebase_init_failed',
        details: e,
      );
    }
  }

  /// Get current user ID
  String? get currentUserId => auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => auth.currentUser != null;

  /// Get current user email
  String? get currentUserEmail => auth.currentUser?.email;

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Sign out failed', error: e);
      throw AuthException(
        'Failed to sign out: ${e.toString()}',
        code: 'signout_failed',
        details: e,
      );
    }
  }

  /// Check Firestore connectivity
  Future<bool> checkConnection() async {
    try {
      await firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      _logger.w('Firestore connection check failed', error: e);
      return false;
    }
  }

  /// Get server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Dispose resources (if needed)
  void dispose() {
    _logger.i('FirebaseService disposed');
  }
}
