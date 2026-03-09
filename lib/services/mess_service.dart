import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../constants/index.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Mess management service handling menu and feedback
class MessService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  MessService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Add or update mess menu for a specific date (Admin only)
  Future<MessMenuModel> addOrUpdateMenu({
    required DateTime date,
    required List<String> breakfast,
    required List<String> lunch,
    required List<String> dinner,
    String? remarks,
    String? menuId,
  }) async {
    try {
      _logger.i('Adding/updating mess menu for date: ${date.formatted}');

      final id = menuId ?? _uuid.v4();
      final now = DateTime.now();

      final menu = MessMenuModel(
        menuId: id,
        date: date.startOfDay,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        remarks: remarks,
        createdAt: menuId == null ? now : now,
        updatedAt: now,
      );

      await _firestore
          .collection(AppConstants.collectionMessMenu)
          .doc(id)
          .set(menu.toJson());

      _logger.i('Menu saved successfully: $id');
      return menu;
    } catch (e) {
      _logger.e('Error saving mess menu', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to save menu: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get menu for a specific date
  Future<MessMenuModel?> getMenuByDate(DateTime date) async {
    try {
      final startOfDay = date.startOfDay;
      final endOfDay = date.endOfDay;

      final querySnapshot = await _firestore
          .collection(AppConstants.collectionMessMenu)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final firstDoc = querySnapshot.docs.first;
      final menuData = Map<String, dynamic>.from(firstDoc.data());
      menuData['menuId'] ??= firstDoc.id;
      return MessMenuModel.fromJson(menuData);
    } catch (e) {
      _logger.e('Error fetching menu by date', error: e);
      throw FirestoreException(
        'Failed to fetch menu: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get menus for a date range
  Future<List<MessMenuModel>> getMenusInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionMessMenu)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.startOfDay),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate.endOfDay),
          )
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['menuId'] ??= doc.id;
        return MessMenuModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching menus in range', error: e);
      throw FirestoreException(
        'Failed to fetch menus: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get today's menu
  Future<MessMenuModel?> getTodayMenu() async {
    return await getMenuByDate(DateTime.now());
  }

  /// Delete menu
  Future<void> deleteMenu(String menuId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionMessMenu)
          .doc(menuId)
          .delete();

      _logger.i('Menu deleted: $menuId');
    } catch (e) {
      _logger.e('Error deleting menu', error: e);
      throw FirestoreException(
        'Failed to delete menu: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Submit feedback for a meal
  Future<FeedbackModel> submitFeedback({
    required String studentId,
    required String studentName,
    required String menuId,
    required DateTime date,
    required String mealType,
    required int rating,
    String? comment,
    List<String>? likedItems,
    List<String>? dislikedItems,
  }) async {
    try {
      _logger.i('Submitting feedback from student: $studentId');

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw ValidationException('Rating must be between 1 and 5');
      }

      // Validate comment length
      if (comment != null &&
          comment.length > AppConstants.maxFeedbackCommentLength) {
        throw ValidationException(
          'Comment must be less than ${AppConstants.maxFeedbackCommentLength} characters',
        );
      }

      final feedbackId = _uuid.v4();

      final feedback = FeedbackModel(
        feedbackId: feedbackId,
        studentId: studentId,
        studentName: studentName,
        menuId: menuId,
        date: date,
        mealType: mealType,
        rating: rating,
        comment: comment,
        likedItems: likedItems,
        dislikedItems: dislikedItems,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionFeedback)
          .doc(feedbackId)
          .set(feedback.toJson());

      _logger.i('Feedback submitted: $feedbackId');
      return feedback;
    } catch (e) {
      _logger.e('Error submitting feedback', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to submit feedback: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get feedback for a specific menu
  Future<List<FeedbackModel>> getFeedbackByMenu(String menuId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionFeedback)
          .where('menuId', isEqualTo: menuId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['feedbackId'] ??= doc.id;
        return FeedbackModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching feedback', error: e);
      throw FirestoreException(
        'Failed to fetch feedback: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get all feedback
  Future<List<FeedbackModel>> getAllFeedback({int? limit}) async {
    try {
      Query query = _firestore
          .collection(AppConstants.collectionFeedback)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['feedbackId'] ??= doc.id;
        return FeedbackModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching all feedback', error: e);
      throw FirestoreException(
        'Failed to fetch feedback: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStatistics() async {
    try {
      final allFeedback = await getAllFeedback();

      if (allFeedback.isEmpty) {
        return {
          'total': 0,
          'averageRating': 0.0,
          'positive': 0,
          'negative': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final totalRating = allFeedback.fold<int>(
        0,
        (sum, feedback) => sum + feedback.rating,
      );
      final averageRating = totalRating / allFeedback.length;

      final positive = allFeedback.where((f) => f.isPositive).length;
      final negative = allFeedback.where((f) => f.isNegative).length;

      final ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final feedback in allFeedback) {
        ratingDistribution[feedback.rating] =
            ratingDistribution[feedback.rating]! + 1;
      }

      return {
        'total': allFeedback.length,
        'averageRating': averageRating,
        'positive': positive,
        'negative': negative,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      _logger.e('Error calculating feedback statistics', error: e);
      throw FirestoreException(
        'Failed to calculate statistics: ${e.toString()}',
        details: e,
      );
    }
  }
}
