import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the daily mess menu
/// Admin can add/update, students can view
class MessMenuModel {
  final String menuId;
  final DateTime date;
  final List<String> breakfast;
  final List<String> lunch;
  final List<String> dinner;
  final String? remarks; // Special notes or announcements
  final DateTime createdAt;
  final DateTime updatedAt;

  const MessMenuModel({
    required this.menuId,
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create MessMenuModel from Firestore document
  factory MessMenuModel.fromJson(Map<String, dynamic> json) {
    return MessMenuModel(
      menuId: json['menuId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      breakfast: List<String>.from(json['breakfast'] as List),
      lunch: List<String>.from(json['lunch'] as List),
      dinner: List<String>.from(json['dinner'] as List),
      remarks: json['remarks'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert MessMenuModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'menuId': menuId,
      'date': Timestamp.fromDate(date),
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with modified fields
  MessMenuModel copyWith({
    String? menuId,
    DateTime? date,
    List<String>? breakfast,
    List<String>? lunch,
    List<String>? dinner,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessMenuModel(
      menuId: menuId ?? this.menuId,
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if menu is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  String toString() {
    return 'MessMenuModel(menuId: $menuId, date: ${date.toLocal()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessMenuModel && other.menuId == menuId;
  }

  @override
  int get hashCode => menuId.hashCode;
}
