import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an admin broadcast notification shown to students
class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final String targetType; // 'all', 'year', 'block', 'individual'
  final String? targetValue;
  final String sentBy;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.targetType,
    this.targetValue,
    required this.sentBy,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'all',
      targetValue: json['targetValue'] as String?,
      sentBy: json['sentBy'] as String? ?? 'Admin',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'targetType': targetType,
      'targetValue': targetValue,
      'sentBy': sentBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() =>
      'NotificationModel(id: $notificationId, title: $title)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.notificationId == notificationId;
  }

  @override
  int get hashCode => notificationId.hashCode;
}
