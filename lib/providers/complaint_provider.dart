import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Complaint service provider
final complaintServiceProvider = Provider<ComplaintService>((ref) {
  return ComplaintService();
});

/// Complaints by student provider
final complaintsByStudentProvider =
    FutureProvider.family<List<ComplaintModel>, String>((ref, studentId) async {
      final service = ref.watch(complaintServiceProvider);
      return await service.getComplaintsByStudent(studentId);
    });

/// All complaints provider (admin)
final allComplaintsProvider =
    FutureProvider.family<List<ComplaintModel>, String?>((ref, status) async {
      final service = ref.watch(complaintServiceProvider);
      return await service.getAllComplaints(status: status);
    });

/// Complaint by ID provider
final complaintByIdProvider = FutureProvider.family<ComplaintModel, String>((
  ref,
  complaintId,
) async {
  final service = ref.watch(complaintServiceProvider);
  return await service.getComplaintById(complaintId);
});

/// Complaint statistics provider
final complaintStatisticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(complaintServiceProvider);
  return await service.getComplaintStatistics();
});

/// Complaint submission notifier provider
final complaintSubmissionProvider =
    StateNotifierProvider<
      ComplaintSubmissionNotifier,
      AsyncValue<ComplaintModel?>
    >((ref) {
      return ComplaintSubmissionNotifier(ref.watch(complaintServiceProvider));
    });

/// Complaint submission state notifier
class ComplaintSubmissionNotifier
    extends StateNotifier<AsyncValue<ComplaintModel?>> {
  final ComplaintService _service;

  ComplaintSubmissionNotifier(this._service)
    : super(const AsyncValue.data(null));

  /// Submit a new complaint
  Future<void> submitComplaint({
    required String studentId,
    required String studentName,
    required String category,
    required String description,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _service.submitComplaint(
        studentId: studentId,
        studentName: studentName,
        category: category,
        description: description,
        imageUrl: imageUrl,
      );
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Complaint update notifier provider
final complaintUpdateProvider =
    StateNotifierProvider<ComplaintUpdateNotifier, AsyncValue<bool>>((ref) {
      return ComplaintUpdateNotifier(ref.watch(complaintServiceProvider));
    });

/// Complaint update state notifier
class ComplaintUpdateNotifier extends StateNotifier<AsyncValue<bool>> {
  final ComplaintService _service;

  ComplaintUpdateNotifier(this._service) : super(const AsyncValue.data(false));

  /// Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminRemarks,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _service.updateComplaintStatus(
        complaintId: complaintId,
        status: status,
        adminRemarks: adminRemarks,
      );
      return true;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(false);
  }
}
