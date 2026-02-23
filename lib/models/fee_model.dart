import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a fee record for students
/// Tracks payment status and due dates
class FeeModel {
  final String feeId;
  final String studentId;
  final String studentName;
  final double amount;
  final String feeType; // 'room_rent', 'mess_fee', 'maintenance', 'other'
  final DateTime dueDate;
  final String status; // 'pending', 'overdue', 'paid'
  final DateTime? paidDate;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeeModel({
    required this.feeId,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.feeType,
    required this.dueDate,
    required this.status,
    this.paidDate,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create FeeModel from Firestore document
  factory FeeModel.fromJson(Map<String, dynamic> json) {
    return FeeModel(
      feeId: json['feeId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      amount: (json['amount'] as num).toDouble(),
      feeType: json['feeType'] as String,
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      status: json['status'] as String,
      paidDate: json['paidDate'] != null
          ? (json['paidDate'] as Timestamp).toDate()
          : null,
      transactionId: json['transactionId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert FeeModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'feeId': feeId,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'feeType': feeType,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with modified fields
  FeeModel copyWith({
    String? feeId,
    String? studentId,
    String? studentName,
    double? amount,
    String? feeType,
    DateTime? dueDate,
    String? status,
    DateTime? paidDate,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeeModel(
      feeId: feeId ?? this.feeId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      amount: amount ?? this.amount,
      feeType: feeType ?? this.feeType,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if fee is overdue
  bool get isOverdue {
    if (status == 'paid') return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Check if fee is paid
  bool get isPaid => status == 'paid';

  /// Get days until due (negative if overdue)
  int get daysUntilDue {
    return dueDate.difference(DateTime.now()).inDays;
  }

  @override
  String toString() {
    return 'FeeModel(id: $feeId, type: $feeType, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeeModel && other.feeId == feeId;
  }

  @override
  int get hashCode => feeId.hashCode;
}
