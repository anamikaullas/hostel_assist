import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../constants/index.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Complaint service with AI-based classification
/// Uses rule-based NLP for automatic categorization and priority assignment
class ComplaintService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  ComplaintService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  // Keyword-based classification dictionaries
  static const Map<String, List<String>> _categoryKeywords = {
    AppConstants.categoryPlumbing: [
      'water',
      'leak',
      'tap',
      'faucet',
      'toilet',
      'flush',
      'pipe',
      'drain',
      'sink',
      'shower',
      'bath',
      'plumbing',
      'dripping',
      'clogged',
      'overflow',
    ],
    AppConstants.categoryElectrical: [
      'light',
      'bulb',
      'switch',
      'power',
      'electricity',
      'socket',
      'outlet',
      'fan',
      'wiring',
      'electrical',
      'shock',
      'sparking',
      'fuse',
      'circuit',
      'voltage',
    ],
    AppConstants.categoryMaintenance: [
      'paint',
      'wall',
      'door',
      'window',
      'furniture',
      'bed',
      'table',
      'chair',
      'cupboard',
      'ceiling',
      'floor',
      'broken',
      'damaged',
      'repair',
      'maintenance',
      'crack',
    ],
    AppConstants.categoryCleanliness: [
      'clean',
      'dirty',
      'dust',
      'garbage',
      'trash',
      'waste',
      'smell',
      'odor',
      'insect',
      'pest',
      'rat',
      'cockroach',
      'hygiene',
      'sanitation',
      'messy',
    ],
    AppConstants.categoryNoise: [
      'noise',
      'loud',
      'disturb',
      'sound',
      'music',
      'party',
      'shouting',
      'disturbance',
      'quiet',
      'peace',
    ],
    AppConstants.categoryHeating: [
      'cold',
      'hot',
      'temperature',
      'heater',
      'ac',
      'air conditioning',
      'cooling',
      'heating',
      'ventilation',
      'thermostat',
    ],
  };

  static const List<String> _highPriorityKeywords = [
    'urgent',
    'emergency',
    'critical',
    'danger',
    'hazard',
    'immediately',
    'asap',
    'serious',
    'severe',
    'flooding',
    'sparking',
    'broken',
    'unsafe',
  ];

  static const List<String> _mediumPriorityKeywords = [
    'important',
    'problem',
    'issue',
    'soon',
    'needed',
    'quickly',
    'attention',
  ];

  static const List<String> _lowPriorityKeywords = [
    'minor',
    'slight',
    'small',
    'when possible',
    'eventually',
    'later',
  ];

  /// Submit a new complaint with automatic classification
  Future<ComplaintModel> submitComplaint({
    required String studentId,
    required String studentName,
    required String category,
    required String description,
    String? imageUrl,
  }) async {
    try {
      _logger.i('Submitting complaint for student: $studentId');

      // Validate description length
      if (description.length > AppConstants.maxComplaintDescriptionLength) {
        throw ValidationException(
          'Description must be less than ${AppConstants.maxComplaintDescriptionLength} characters',
        );
      }

      // AI Classification: Determine category and priority using NLP
      final determinedCategory = _classifyCategory(description);
      final priority = _determinePriority(description);

      final complaintId = _uuid.v4();

      final complaint = ComplaintModel(
        complaintId: complaintId,
        studentId: studentId,
        studentName: studentName,
        category: category,
        determinedCategory: determinedCategory,
        description: description,
        status: AppConstants.complaintPending,
        priority: priority,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId)
          .set(complaint.toJson());

      _logger.i(
        'Complaint submitted: $complaintId (category: $determinedCategory, priority: $priority)',
      );

      return complaint;
    } catch (e) {
      _logger.e('Error submitting complaint', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to submit complaint: ${e.toString()}',
        details: e,
      );
    }
  }

  /// AI Classification: Determine complaint category using keyword matching
  ///
  /// Algorithm:
  /// 1. Convert description to lowercase
  /// 2. Extract words (split by non-alphanumeric characters)
  /// 3. Count keyword matches for each category
  /// 4. Return category with highest match count
  /// 5. Default to 'other' if no clear category
  String _classifyCategory(String description) {
    final words = _extractWords(description.toLowerCase());
    final categoryScores = <String, int>{};

    // Count keyword matches for each category
    _categoryKeywords.forEach((category, keywords) {
      int matchCount = 0;
      for (final word in words) {
        for (final keyword in keywords) {
          if (word.contains(keyword) || keyword.contains(word)) {
            matchCount++;
          }
        }
      }
      if (matchCount > 0) {
        categoryScores[category] = matchCount;
      }
    });

    // Return category with highest score
    if (categoryScores.isEmpty) {
      return AppConstants.categoryOther;
    }

    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _logger.d('Category classification scores: $categoryScores');
    _logger.i(
      'Classified as: ${sortedCategories.first.key} (score: ${sortedCategories.first.value})',
    );

    return sortedCategories.first.key;
  }

  /// AI Classification: Determine priority using keyword matching
  ///
  /// Priority levels:
  /// - High: Contains urgent/emergency keywords
  /// - Medium: Contains important/problem keywords
  /// - Low: Contains minor/when possible keywords or default
  String _determinePriority(String description) {
    final words = _extractWords(description.toLowerCase());

    // Check for high priority keywords
    for (final word in words) {
      for (final keyword in _highPriorityKeywords) {
        if (word.contains(keyword) || keyword.contains(word)) {
          return AppConstants.priorityHigh;
        }
      }
    }

    // Check for medium priority keywords
    for (final word in words) {
      for (final keyword in _mediumPriorityKeywords) {
        if (word.contains(keyword) || keyword.contains(word)) {
          return AppConstants.priorityMedium;
        }
      }
    }

    // Check for low priority keywords
    for (final word in words) {
      for (final keyword in _lowPriorityKeywords) {
        if (word.contains(keyword) || keyword.contains(word)) {
          return AppConstants.priorityLow;
        }
      }
    }

    // Default to medium priority
    return AppConstants.priorityMedium;
  }

  /// Extract words from text (split by non-alphanumeric characters)
  List<String> _extractWords(String text) {
    return text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Get all complaints for a student
  Future<List<ComplaintModel>> getComplaintsByStudent(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionComplaints)
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ComplaintModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching student complaints', error: e);
      throw FirestoreException(
        'Failed to fetch complaints: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get all complaints (admin view)
  Future<List<ComplaintModel>> getAllComplaints({String? status}) async {
    try {
      Query query = _firestore.collection(AppConstants.collectionComplaints);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                ComplaintModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      _logger.e('Error fetching all complaints', error: e);
      throw FirestoreException(
        'Failed to fetch complaints: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Update complaint status (admin action)
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminRemarks,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        if (adminRemarks != null) 'adminRemarks': adminRemarks,
      };

      if (status == AppConstants.complaintResolved) {
        updates['resolvedAt'] = Timestamp.now();
      }

      await _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId)
          .update(updates);

      _logger.i('Updated complaint $complaintId to status: $status');
    } catch (e) {
      _logger.e('Error updating complaint status', error: e);
      throw FirestoreException(
        'Failed to update complaint: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get complaint by ID
  Future<ComplaintModel> getComplaintById(String complaintId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId)
          .get();

      if (!doc.exists) {
        throw NotFoundException('Complaint not found: $complaintId');
      }

      return ComplaintModel.fromJson(doc.data()!);
    } catch (e) {
      _logger.e('Error fetching complaint', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to fetch complaint: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get complaint statistics (admin analytics)
  Future<Map<String, dynamic>> getComplaintStatistics() async {
    try {
      final allComplaints = await getAllComplaints();

      final stats = {
        'total': allComplaints.length,
        'pending': allComplaints
            .where((c) => c.status == AppConstants.complaintPending)
            .length,
        'inProgress': allComplaints
            .where((c) => c.status == AppConstants.complaintInProgress)
            .length,
        'resolved': allComplaints
            .where((c) => c.status == AppConstants.complaintResolved)
            .length,
        'highPriority': allComplaints
            .where((c) => c.priority == AppConstants.priorityHigh)
            .length,
        'categoryCounts': <String, int>{},
      };

      // Count complaints by category
      for (final complaint in allComplaints) {
        final category =
            complaint.determinedCategory ?? AppConstants.categoryOther;
        final categoryCounts = stats['categoryCounts'] as Map<String, int>;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      _logger.e('Error calculating complaint statistics', error: e);
      throw FirestoreException(
        'Failed to calculate statistics: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Delete a complaint (admin only)
  Future<void> deleteComplaint(String complaintId) async {
    try {
      _logger.i('Deleting complaint: $complaintId');

      await _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId)
          .delete();

      _logger.i('Complaint deleted successfully');
    } catch (e) {
      _logger.e('Error deleting complaint', error: e);
      throw FirestoreException(
        'Failed to delete complaint: ${e.toString()}',
        details: e,
      );
    }
  }
}
