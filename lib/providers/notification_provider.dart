import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Notifications stream provider (real-time)
final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
      final service = ref.watch(notificationServiceProvider);
      return service.watchNotifications(limit: 30);
    });

/// Notifications future provider (one-shot fetch)
final notificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getNotifications(limit: 30);
});
