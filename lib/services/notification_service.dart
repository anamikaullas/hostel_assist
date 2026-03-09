import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Service for reading admin broadcast notifications
class NotificationService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();

  NotificationService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  static const String _collection = 'notifications';

  /// Get recent notifications (for all students or matching year/block)
  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    String? year,
    String? block,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final all = querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['notificationId'] ??= doc.id;
        return NotificationModel.fromJson(data);
      }).toList();

      // Filter notifications relevant to this student
      return all.where((n) {
        if (n.targetType == 'all') return true;
        if (n.targetType == 'year' && year != null) {
          return n.targetValue == year;
        }
        if (n.targetType == 'block' && block != null) {
          return n.targetValue == block;
        }
        return n.targetType == 'all';
      }).toList();
    } catch (e) {
      _logger.e('Error fetching notifications', error: e);
      throw FirestoreException(
        'Failed to fetch notifications: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Stream of recent notifications (real-time updates)
  Stream<List<NotificationModel>> watchNotifications({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['notificationId'] ??= doc.id;
              return NotificationModel.fromJson(data);
            }).toList());
  }
}
