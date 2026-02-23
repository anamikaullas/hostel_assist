import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user (Student or Admin) in the hostel management system
/// Immutable model with JSON serialization support
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'student' or 'admin'
  final String phoneNumber;
  final String? enrollmentId; // Only for students
  final String? roomId; // Assigned room for students
  final int? year; // Academic year for students
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.phoneNumber,
    this.enrollmentId,
    this.roomId,
    this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      phoneNumber: json['phoneNumber'] as String,
      enrollmentId: json['enrollmentId'] as String?,
      roomId: json['roomId'] as String?,
      year: json['year'] as int?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phoneNumber': phoneNumber,
      'enrollmentId': enrollmentId,
      'roomId': roomId,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    String? phoneNumber,
    String? enrollmentId,
    String? roomId,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      roomId: roomId ?? this.roomId,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is a student
  bool get isStudent => role == 'student';

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
