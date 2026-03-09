import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../constants/index.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Fee management service handling payments and tracking
class FeeService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  FeeService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Create a new fee record (Admin only)
  Future<FeeModel> createFee({
    required String studentId,
    required String studentName,
    required double amount,
    required String feeType,
    required DateTime dueDate,
  }) async {
    try {
      _logger.i('Creating fee for student: $studentId');

      if (amount <= 0) {
        throw ValidationException('Fee amount must be greater than zero');
      }

      final feeId = _uuid.v4();
      final now = DateTime.now();

      final fee = FeeModel(
        feeId: feeId,
        studentId: studentId,
        studentName: studentName,
        amount: amount,
        feeType: feeType,
        dueDate: dueDate,
        status: AppConstants.feePending,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(AppConstants.collectionFees)
          .doc(feeId)
          .set(fee.toJson());

      _logger.i('Fee created: $feeId');
      return fee;
    } catch (e) {
      _logger.e('Error creating fee', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to create fee: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Mark fee as paid
  Future<void> markFeeAsPaid({
    required String feeId,
    required String transactionId,
    DateTime? paidDate,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.collectionFees)
          .doc(feeId)
          .update({
            'status': AppConstants.feePaid,
            'paidDate': Timestamp.fromDate(paidDate ?? DateTime.now()),
            'transactionId': transactionId,
            'updatedAt': Timestamp.now(),
          });

      _logger.i('Fee marked as paid: $feeId');
    } catch (e) {
      _logger.e('Error marking fee as paid', error: e);
      throw FirestoreException(
        'Failed to update fee: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Update fee status
  Future<void> updateFeeStatus(String feeId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.collectionFees)
          .doc(feeId)
          .update({'status': status, 'updatedAt': Timestamp.now()});

      _logger.i('Fee status updated: $feeId -> $status');
    } catch (e) {
      _logger.e('Error updating fee status', error: e);
      throw FirestoreException(
        'Failed to update fee: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get fees for a specific student
  Future<List<FeeModel>> getFeesByStudent(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionFees)
          .where('studentId', isEqualTo: studentId)
          .orderBy('dueDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['feeId'] ??= doc.id;
        return FeeModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching student fees', error: e);
      throw FirestoreException(
        'Failed to fetch fees: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get all fees (Admin view)
  Future<List<FeeModel>> getAllFees({String? status}) async {
    try {
      Query query = _firestore.collection(AppConstants.collectionFees);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query
          .orderBy('dueDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['feeId'] ??= doc.id;
        return FeeModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching all fees', error: e);
      throw FirestoreException(
        'Failed to fetch fees: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get overdue fees
  Future<List<FeeModel>> getOverdueFees() async {
    try {
      final now = DateTime.now();

      final querySnapshot = await _firestore
          .collection(AppConstants.collectionFees)
          .where('status', isEqualTo: AppConstants.feePending)
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['feeId'] ??= doc.id;
        return FeeModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching overdue fees', error: e);
      throw FirestoreException(
        'Failed to fetch overdue fees: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Update overdue fees status (run periodically)
  Future<void> updateOverdueFeesStatus() async {
    try {
      final overdueFees = await getOverdueFees();

      for (final fee in overdueFees) {
        if (fee.status == AppConstants.feePending) {
          await updateFeeStatus(fee.feeId, AppConstants.feeOverdue);
        }
      }

      _logger.i('Updated ${overdueFees.length} overdue fees');
    } catch (e) {
      _logger.e('Error updating overdue fees', error: e);
      throw FirestoreException(
        'Failed to update overdue fees: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get fee by ID
  Future<FeeModel> getFeeById(String feeId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionFees)
          .doc(feeId)
          .get();

      if (!doc.exists) {
        throw NotFoundException('Fee not found: $feeId');
      }

      final feeData = Map<String, dynamic>.from(doc.data()!);
      feeData['feeId'] ??= doc.id;
      return FeeModel.fromJson(feeData);
    } catch (e) {
      _logger.e('Error fetching fee', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to fetch fee: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Delete fee
  Future<void> deleteFee(String feeId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionFees)
          .doc(feeId)
          .delete();

      _logger.i('Fee deleted: $feeId');
    } catch (e) {
      _logger.e('Error deleting fee', error: e);
      throw FirestoreException(
        'Failed to delete fee: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get fee statistics
  Future<Map<String, dynamic>> getFeeStatistics() async {
    try {
      final allFees = await getAllFees();

      final total = allFees.length;
      final paid = allFees
          .where((f) => f.status == AppConstants.feePaid)
          .length;
      final pending = allFees
          .where((f) => f.status == AppConstants.feePending)
          .length;
      final overdue = allFees
          .where((f) => f.status == AppConstants.feeOverdue)
          .length;

      final totalAmount = allFees.fold<double>(
        0.0,
        (sum, fee) => sum + fee.amount,
      );
      final paidAmount = allFees
          .where((f) => f.status == AppConstants.feePaid)
          .fold<double>(0.0, (sum, fee) => sum + fee.amount);
      final pendingAmount = allFees
          .where((f) => f.status != AppConstants.feePaid)
          .fold<double>(0.0, (sum, fee) => sum + fee.amount);

      return {
        'total': total,
        'paid': paid,
        'pending': pending,
        'overdue': overdue,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'collectionRate': total > 0 ? (paid / total) * 100 : 0.0,
      };
    } catch (e) {
      _logger.e('Error calculating fee statistics', error: e);
      throw FirestoreException(
        'Failed to calculate statistics: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get pending fees for a student
  Future<List<FeeModel>> getPendingFeesByStudent(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionFees)
          .where('studentId', isEqualTo: studentId)
          .where(
            'status',
            whereIn: [AppConstants.feePending, AppConstants.feeOverdue],
          )
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['feeId'] ??= doc.id;
        return FeeModel.fromJson(data);
      }).toList();
    } catch (e) {
      _logger.e('Error fetching pending fees', error: e);
      throw FirestoreException(
        'Failed to fetch pending fees: ${e.toString()}',
        details: e,
      );
    }
  }
}
