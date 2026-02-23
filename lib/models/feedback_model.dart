import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents student feedback for mess meals
/// Used for analytics and improving food quality
class FeedbackModel {
  final String feedbackId;
  final String studentId;
  final String studentName;
  final String menuId; // Reference to MessMenuModel
  final DateTime date;
  final String mealType; // 'breakfast', 'lunch', 'dinner'
  final int rating; // 1-5 stars
  final String? comment;
  final List<String>? likedItems;
  final List<String>? dislikedItems;
  final DateTime createdAt;

  const FeedbackModel({
    required this.feedbackId,
    required this.studentId,
    required this.studentName,
    required this.menuId,
    required this.date,
    required this.mealType,
    required this.rating,
    this.comment,
    this.likedItems,
    this.dislikedItems,
    required this.createdAt,
  });

  /// Create FeedbackModel from Firestore document
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      feedbackId: json['feedbackId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      menuId: json['menuId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      mealType: json['mealType'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      likedItems: json['likedItems'] != null
          ? List<String>.from(json['likedItems'] as List)
          : null,
      dislikedItems: json['dislikedItems'] != null
          ? List<String>.from(json['dislikedItems'] as List)
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert FeedbackModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'studentId': studentId,
      'studentName': studentName,
      'menuId': menuId,
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'rating': rating,
      'comment': comment,
      'likedItems': likedItems,
      'dislikedItems': dislikedItems,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with modified fields
  FeedbackModel copyWith({
    String? feedbackId,
    String? studentId,
    String? studentName,
    String? menuId,
    DateTime? date,
    String? mealType,
    int? rating,
    String? comment,
    List<String>? likedItems,
    List<String>? dislikedItems,
    DateTime? createdAt,
  }) {
    return FeedbackModel(
      feedbackId: feedbackId ?? this.feedbackId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      menuId: menuId ?? this.menuId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      likedItems: likedItems ?? this.likedItems,
      dislikedItems: dislikedItems ?? this.dislikedItems,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if feedback is positive (4-5 stars)
  bool get isPositive => rating >= 4;

  /// Check if feedback is negative (1-2 stars)
  bool get isNegative => rating <= 2;

  @override
  String toString() {
    return 'FeedbackModel(id: $feedbackId, mealType: $mealType, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackModel && other.feedbackId == feedbackId;
  }

  @override
  int get hashCode => feedbackId.hashCode;
}
