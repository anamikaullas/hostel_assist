import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Fee service provider
final feeServiceProvider = Provider<FeeService>((ref) {
  return FeeService();
});

/// Fees by student provider
final feesByStudentProvider = FutureProvider.family<List<FeeModel>, String>((
  ref,
  studentId,
) async {
  final service = ref.watch(feeServiceProvider);
  return await service.getFeesByStudent(studentId);
});

/// Pending fees by student provider
final pendingFeesByStudentProvider =
    FutureProvider.family<List<FeeModel>, String>((ref, studentId) async {
      final service = ref.watch(feeServiceProvider);
      return await service.getPendingFeesByStudent(studentId);
    });

/// All fees provider (admin)
final allFeesProvider = FutureProvider.family<List<FeeModel>, String?>((
  ref,
  status,
) async {
  final service = ref.watch(feeServiceProvider);
  return await service.getAllFees(status: status);
});

/// Fee by ID provider
final feeByIdProvider = FutureProvider.family<FeeModel, String>((
  ref,
  feeId,
) async {
  final service = ref.watch(feeServiceProvider);
  return await service.getFeeById(feeId);
});

/// Fee statistics provider
final feeStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(feeServiceProvider);
  return await service.getFeeStatistics();
});

/// Fee creation notifier provider
final feeCreationProvider =
    StateNotifierProvider<FeeCreationNotifier, AsyncValue<FeeModel?>>((ref) {
      return FeeCreationNotifier(ref.watch(feeServiceProvider));
    });

/// Fee creation state notifier
class FeeCreationNotifier extends StateNotifier<AsyncValue<FeeModel?>> {
  final FeeService _service;

  FeeCreationNotifier(this._service) : super(const AsyncValue.data(null));

  /// Create a new fee
  Future<void> createFee({
    required String studentId,
    required String studentName,
    required double amount,
    required String feeType,
    required DateTime dueDate,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _service.createFee(
        studentId: studentId,
        studentName: studentName,
        amount: amount,
        feeType: feeType,
        dueDate: dueDate,
      );
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Fee payment notifier provider
final feePaymentProvider =
    StateNotifierProvider<FeePaymentNotifier, AsyncValue<bool>>((ref) {
      return FeePaymentNotifier(ref.watch(feeServiceProvider));
    });

/// Fee payment state notifier
class FeePaymentNotifier extends StateNotifier<AsyncValue<bool>> {
  final FeeService _service;

  FeePaymentNotifier(this._service) : super(const AsyncValue.data(false));

  /// Mark fee as paid
  Future<void> markFeeAsPaid({
    required String feeId,
    required String transactionId,
    DateTime? paidDate,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _service.markFeeAsPaid(
        feeId: feeId,
        transactionId: transactionId,
        paidDate: paidDate,
      );
      return true;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(false);
  }
}
