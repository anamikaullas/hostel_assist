import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a student complaint with AI classification
/// Classification is done using rule-based NLP
class ComplaintModel {
  final String complaintId;
  final String studentId;
  final String studentName;
  final String category; // User-provided category
  final String? determinedCategory; // AI-classified category
  final String description;
  final String status; // 'pending', 'in_progress', 'resolved'
  final String priority; // 'high', 'medium', 'low'
  final String? imageUrl; // Optional image evidence
  final String? adminRemarks;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const ComplaintModel({
    required this.complaintId,
    required this.studentId,
    required this.studentName,
    required this.category,
    this.determinedCategory,
    required this.description,
    required this.status,
    required this.priority,
    this.imageUrl,
    this.adminRemarks,
    required this.createdAt,
    this.resolvedAt,
  });

  /// Create ComplaintModel from Firestore document
  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      complaintId: json['complaintId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      category: json['category'] as String,
      determinedCategory: json['determinedCategory'] as String?,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      imageUrl: json['imageUrl'] as String?,
      adminRemarks: json['adminRemarks'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      resolvedAt: json['resolvedAt'] != null
          ? (json['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert ComplaintModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'complaintId': complaintId,
      'studentId': studentId,
      'studentName': studentName,
      'category': category,
      'determinedCategory': determinedCategory,
      'description': description,
      'status': status,
      'priority': priority,
      'imageUrl': imageUrl,
      'adminRemarks': adminRemarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  /// Create a copy with modified fields
  ComplaintModel copyWith({
    String? complaintId,
    String? studentId,
    String? studentName,
    String? category,
    String? determinedCategory,
    String? description,
    String? status,
    String? priority,
    String? imageUrl,
    String? adminRemarks,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return ComplaintModel(
      complaintId: complaintId ?? this.complaintId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      category: category ?? this.category,
      determinedCategory: determinedCategory ?? this.determinedCategory,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      adminRemarks: adminRemarks ?? this.adminRemarks,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Check if complaint is open/pending
  bool get isOpen => status == 'pending' || status == 'in_progress';

  /// Check if complaint is resolved
  bool get isResolved => status == 'resolved';

  /// Check if complaint is high priority
  bool get isHighPriority => priority == 'high';

  @override
  String toString() {
    return 'ComplaintModel(id: $complaintId, status: $status, priority: $priority, category: $determinedCategory)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplaintModel && other.complaintId == complaintId;
  }

  @override
  int get hashCode => complaintId.hashCode;
}
