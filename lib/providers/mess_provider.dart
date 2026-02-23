import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Mess service provider
final messServiceProvider = Provider<MessService>((ref) {
  return MessService();
});

/// Menu by date provider
final menuByDateProvider = FutureProvider.family<MessMenuModel?, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(messServiceProvider);
  return await service.getMenuByDate(date);
});

/// Today's menu provider
final todayMenuProvider = FutureProvider<MessMenuModel?>((ref) async {
  final service = ref.watch(messServiceProvider);
  return await service.getTodayMenu();
});

/// Menus in range provider
final menusInRangeProvider =
    FutureProvider.family<
      List<MessMenuModel>,
      ({DateTime startDate, DateTime endDate})
    >((ref, params) async {
      final service = ref.watch(messServiceProvider);
      return await service.getMenusInRange(
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

/// All feedback provider
final allFeedbackProvider = FutureProvider.family<List<FeedbackModel>, int?>((
  ref,
  limit,
) async {
  final service = ref.watch(messServiceProvider);
  return await service.getAllFeedback(limit: limit);
});

/// Feedback by menu provider
final feedbackByMenuProvider =
    FutureProvider.family<List<FeedbackModel>, String>((ref, menuId) async {
      final service = ref.watch(messServiceProvider);
      return await service.getFeedbackByMenu(menuId);
    });

/// Feedback statistics provider
final feedbackStatisticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(messServiceProvider);
  return await service.getFeedbackStatistics();
});

/// Menu management notifier provider
final menuManagementProvider =
    StateNotifierProvider<MenuManagementNotifier, AsyncValue<MessMenuModel?>>((
      ref,
    ) {
      return MenuManagementNotifier(ref.watch(messServiceProvider));
    });

/// Menu management state notifier
class MenuManagementNotifier extends StateNotifier<AsyncValue<MessMenuModel?>> {
  final MessService _service;

  MenuManagementNotifier(this._service) : super(const AsyncValue.data(null));

  /// Add or update menu
  Future<void> addOrUpdateMenu({
    required DateTime date,
    required List<String> breakfast,
    required List<String> lunch,
    required List<String> dinner,
    String? remarks,
    String? menuId,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _service.addOrUpdateMenu(
        date: date,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        remarks: remarks,
        menuId: menuId,
      );
    });
  }

  /// Delete menu
  Future<void> deleteMenu(String menuId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _service.deleteMenu(menuId);
      return null;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Feedback submission notifier provider
final feedbackSubmissionProvider =
    StateNotifierProvider<
      FeedbackSubmissionNotifier,
      AsyncValue<FeedbackModel?>
    >((ref) {
      return FeedbackSubmissionNotifier(ref.watch(messServiceProvider));
    });

/// Feedback submission state notifier
class FeedbackSubmissionNotifier
    extends StateNotifier<AsyncValue<FeedbackModel?>> {
  final MessService _service;

  FeedbackSubmissionNotifier(this._service)
    : super(const AsyncValue.data(null));

  /// Submit feedback
  Future<void> submitFeedback({
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
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _service.submitFeedback(
        studentId: studentId,
        studentName: studentName,
        menuId: menuId,
        date: date,
        mealType: mealType,
        rating: rating,
        comment: comment,
        likedItems: likedItems,
        dislikedItems: dislikedItems,
      );
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}
