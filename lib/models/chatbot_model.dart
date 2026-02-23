import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chatbot conversation log
/// Used for intent tracking and analytics
class ChatbotModel {
  final String messageId;
  final String studentId;
  final String message;
  final String response;
  final String detectedIntent; // e.g., 'complaint_status', 'fee_info', etc.
  final List<String> keywords;
  final DateTime timestamp;

  const ChatbotModel({
    required this.messageId,
    required this.studentId,
    required this.message,
    required this.response,
    required this.detectedIntent,
    required this.keywords,
    required this.timestamp,
  });

  /// Create ChatbotModel from Firestore document
  factory ChatbotModel.fromJson(Map<String, dynamic> json) {
    return ChatbotModel(
      messageId: json['messageId'] as String,
      studentId: json['studentId'] as String,
      message: json['message'] as String,
      response: json['response'] as String,
      detectedIntent: json['detectedIntent'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Convert ChatbotModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'studentId': studentId,
      'message': message,
      'response': response,
      'detectedIntent': detectedIntent,
      'keywords': keywords,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Create a copy with modified fields
  ChatbotModel copyWith({
    String? messageId,
    String? studentId,
    String? message,
    String? response,
    String? detectedIntent,
    List<String>? keywords,
    DateTime? timestamp,
  }) {
    return ChatbotModel(
      messageId: messageId ?? this.messageId,
      studentId: studentId ?? this.studentId,
      message: message ?? this.message,
      response: response ?? this.response,
      detectedIntent: detectedIntent ?? this.detectedIntent,
      keywords: keywords ?? this.keywords,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ChatbotModel(id: $messageId, intent: $detectedIntent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatbotModel && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}
