import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Room allocation service provider
final roomAllocationServiceProvider = Provider<RoomAllocationService>((ref) {
  return RoomAllocationService();
});

/// All rooms provider
final allRoomsProvider = FutureProvider<List<RoomModel>>((ref) async {
  final service = ref.watch(roomAllocationServiceProvider);
  return await service.getAllRooms();
});

/// Room by ID provider
final roomByIdProvider = FutureProvider.family<RoomModel, String>((
  ref,
  roomId,
) async {
  final service = ref.watch(roomAllocationServiceProvider);
  return await service.getRoomById(roomId);
});

/// Room by student ID provider
final roomByStudentIdProvider = FutureProvider.family<RoomModel?, String>((
  ref,
  studentId,
) async {
  final service = ref.watch(roomAllocationServiceProvider);
  return await service.getRoomByStudentId(studentId);
});

/// Room allocation notifier provider
final roomAllocationProvider =
    StateNotifierProvider<RoomAllocationNotifier, AsyncValue<String?>>((ref) {
      return RoomAllocationNotifier(ref.watch(roomAllocationServiceProvider));
    });

/// Room allocation state notifier
class RoomAllocationNotifier extends StateNotifier<AsyncValue<String?>> {
  final RoomAllocationService _service;

  RoomAllocationNotifier(this._service) : super(const AsyncValue.data(null));

  /// Allocate room to a student
  Future<void> allocateRoom({
    required String studentId,
    required String fullName,
    List<String> preferredAmenities = const [],
    int? preferredFloor,
    String? preferredBlock,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _service.allocateRoom(
        studentId: studentId,
        fullName: fullName,
        preferredAmenities: preferredAmenities,
        preferredFloor: preferredFloor,
        preferredBlock: preferredBlock,
      );
    });
  }

  /// Deallocate room from student
  Future<void> deallocateRoom(String studentId, String roomId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _service.deallocateRoom(studentId, roomId);
      return null;
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}
