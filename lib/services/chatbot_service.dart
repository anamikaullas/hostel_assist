import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../constants/index.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Chatbot service with NLP-based intent detection
/// Provides context-aware responses using keyword matching
class ChatbotService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  ChatbotService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  // Intent keyword mappings for NLP classification
  static const Map<String, List<String>> _intentKeywords = {
    AppConstants.intentComplaintStatus: [
      'complaint',
      'issue',
      'problem',
      'status',
      'progress',
      'resolved',
      'pending',
      'track',
    ],
    AppConstants.intentFeeInfo: [
      'fee',
      'payment',
      'cost',
      'paid',
      'due',
      'amount',
      'bill',
      'rent',
      'money',
    ],
    AppConstants.intentMessMenu: [
      'menu',
      'food',
      'meal',
      'breakfast',
      'lunch',
      'dinner',
      'eat',
      'mess',
      'today',
    ],
    AppConstants.intentRoomInfo: [
      'room',
      'accommodation',
      'block',
      'floor',
      'roommate',
      'bed',
    ],
    AppConstants.intentRulesRegulations: [
      'rule',
      'regulation',
      'policy',
      'allowed',
      'curfew',
      'visitor',
      'guest',
    ],
    AppConstants.intentMaintenance: [
      'maintain',
      'repair',
      'fix',
      'broken',
      'damaged',
    ],
    AppConstants.intentGreeting: [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good evening',
      'greetings',
    ],
    AppConstants.intentHelp: ['help', 'support', 'assist', 'guide', 'how to'],
  };

  /// Process user message and generate response
  Future<String> processMessage({
    required String studentId,
    required String message,
  }) async {
    try {
      _logger.i('Processing chatbot message from student: $studentId');

      // Detect intent using NLP
      final intent = _detectIntent(message);
      final keywords = _extractKeywords(message);

      // Generate response based on intent
      final response = await _generateResponse(
        studentId: studentId,
        message: message,
        intent: intent,
      );

      // Log conversation
      await _logConversation(
        studentId: studentId,
        message: message,
        response: response,
        intent: intent,
        keywords: keywords,
      );

      return response;
    } catch (e) {
      _logger.e('Error processing chatbot message', error: e);
      return 'Sorry, I encountered an error. Please try again or contact admin for support.';
    }
  }

  /// Detect user intent using keyword matching
  ///
  /// Algorithm:
  /// 1. Convert message to lowercase
  /// 2. Extract keywords
  /// 3. Count matches for each intent
  /// 4. Return intent with highest match count
  /// 5. Default to 'other' if no clear intent
  String _detectIntent(String message) {
    final words = _extractWords(message.toLowerCase());
    final intentScores = <String, int>{};

    // Count keyword matches for each intent
    _intentKeywords.forEach((intent, keywords) {
      int matchCount = 0;
      for (final word in words) {
        for (final keyword in keywords) {
          if (word.contains(keyword) || keyword.contains(word)) {
            matchCount++;
          }
        }
      }
      if (matchCount > 0) {
        intentScores[intent] = matchCount;
      }
    });

    // Return intent with highest score
    if (intentScores.isEmpty) {
      return AppConstants.intentOther;
    }

    final sortedIntents = intentScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _logger.d('Intent scores: $intentScores');
    _logger.i('Detected intent: ${sortedIntents.first.key}');

    return sortedIntents.first.key;
  }

  /// Extract meaningful keywords from message
  List<String> _extractKeywords(String message) {
    final words = _extractWords(message.toLowerCase());

    // Filter out common words
    final stopWords = {
      'a',
      'an',
      'the',
      'is',
      'are',
      'was',
      'were',
      'in',
      'on',
      'at',
      'to',
      'for',
    };

    return words
        .where((word) => !stopWords.contains(word) && word.length > 2)
        .toList();
  }

  /// Extract words from text
  List<String> _extractWords(String text) {
    return text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Generate context-aware response based on intent
  Future<String> _generateResponse({
    required String studentId,
    required String message,
    required String intent,
  }) async {
    switch (intent) {
      case AppConstants.intentComplaintStatus:
        return await _getComplaintStatusResponse(studentId);

      case AppConstants.intentFeeInfo:
        return await _getFeeInfoResponse(studentId);

      case AppConstants.intentMessMenu:
        return await _getMessMenuResponse();

      case AppConstants.intentRoomInfo:
        return await _getRoomInfoResponse(studentId);

      case AppConstants.intentRulesRegulations:
        return _getRulesResponse();

      case AppConstants.intentMaintenance:
        return _getMaintenanceResponse();

      case AppConstants.intentGreeting:
        return _getGreetingResponse();

      case AppConstants.intentHelp:
        return _getHelpResponse();

      case AppConstants.intentOther:
      default:
        return _getDefaultResponse();
    }
  }

  /// Generate complaint status response
  Future<String> _getComplaintStatusResponse(String studentId) async {
    try {
      final complaints = await _firestore
          .collection(AppConstants.collectionComplaints)
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (complaints.docs.isEmpty) {
        return 'You have no complaints registered. If you have any issues, you can submit a complaint through the Complaints section.';
      }

      final recentComplaint = ComplaintModel.fromJson(
        complaints.docs.first.data(),
      );
      final pending = complaints.docs
          .where((doc) => doc.data()['status'] == AppConstants.complaintPending)
          .length;
      final resolved = complaints.docs
          .where(
            (doc) => doc.data()['status'] == AppConstants.complaintResolved,
          )
          .length;

      return 'You have ${complaints.docs.length} complaint(s): $pending pending, $resolved resolved. '
          'Your most recent complaint (${recentComplaint.category}) is ${recentComplaint.status}.';
    } catch (e) {
      _logger.e('Error fetching complaint status', error: e);
      return 'I couldn\'t fetch your complaint status. Please check the Complaints section.';
    }
  }

  /// Generate fee information response
  Future<String> _getFeeInfoResponse(String studentId) async {
    try {
      final fees = await _firestore
          .collection(AppConstants.collectionFees)
          .where('studentId', isEqualTo: studentId)
          .where(
            'status',
            whereIn: [AppConstants.feePending, AppConstants.feeOverdue],
          )
          .get();

      if (fees.docs.isEmpty) {
        return 'You have no pending fees. All payments are up to date! 🎉';
      }

      final totalDue = fees.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
      );

      return 'You have ${fees.docs.length} pending fee(s) totaling ${totalDue.toCurrency}. '
          'Please check the Fees section for details.';
    } catch (e) {
      _logger.e('Error fetching fee info', error: e);
      return 'I couldn\'t fetch your fee information. Please check the Fees section.';
    }
  }

  /// Generate mess menu response
  Future<String> _getMessMenuResponse() async {
    try {
      final today = DateTime.now().startOfDay;
      final menuDocs = await _firestore
          .collection(AppConstants.collectionMessMenu)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where(
            'date',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .limit(1)
          .get();

      if (menuDocs.docs.isEmpty) {
        return 'Today\'s menu is not yet available. Please check back later or contact the mess admin.';
      }

      final menu = MessMenuModel.fromJson(menuDocs.docs.first.data());
      return 'Today\'s Menu:\n'
          '🌅 Breakfast: ${menu.breakfast.join(', ')}\n'
          '🌞 Lunch: ${menu.lunch.join(', ')}\n'
          '🌙 Dinner: ${menu.dinner.join(', ')}';
    } catch (e) {
      _logger.e('Error fetching mess menu', error: e);
      return 'I couldn\'t fetch today\'s menu. Please check the Mess section.';
    }
  }

  /// Generate room information response
  Future<String> _getRoomInfoResponse(String studentId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(studentId)
          .get();

      if (!userDoc.exists) {
        return 'I couldn\'t find your profile information.';
      }

      final user = UserModel.fromJson(userDoc.data()!);

      if (user.roomId == null) {
        return 'You don\'t have a room assigned yet. Please contact admin for room allocation.';
      }

      final roomDoc = await _firestore
          .collection(AppConstants.collectionRooms)
          .doc(user.roomId)
          .get();

      if (!roomDoc.exists) {
        return 'Room information not found. Please contact admin.';
      }

      final room = RoomModel.fromJson(roomDoc.data()!);

      return 'Your Room: ${room.roomNumber}\n'
          'Block: ${room.blockName}, Floor: ${room.floorNumber}\n'
          'Type: ${room.roomType}, Occupancy: ${room.currentOccupancy}/${room.capacity}\n'
          'Amenities: ${room.amenities.join(', ')}';
    } catch (e) {
      _logger.e('Error fetching room info', error: e);
      return 'I couldn\'t fetch your room information. Please contact admin.';
    }
  }

  /// Generate rules and regulations response
  String _getRulesResponse() {
    return 'Hostel Rules:\n'
        '• Curfew: 10:00 PM on weekdays, 11:00 PM on weekends\n'
        '• Visitors allowed only in common areas during visiting hours\n'
        '• Keep rooms clean and tidy\n'
        '• No loud music or disturbances after 9:00 PM\n'
        '• Report any maintenance issues immediately\n\n'
        'For complete rules, please refer to your hostel handbook.';
  }

  /// Generate maintenance help response
  String _getMaintenanceResponse() {
    return 'For maintenance issues:\n'
        '1. Go to the Complaints section\n'
        '2. Submit a complaint with details\n'
        '3. Attach a photo if possible\n'
        '4. Track status in real-time\n\n'
        'For urgent issues, contact the hostel office directly.';
  }

  /// Generate greeting response
  String _getGreetingResponse() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return '$greeting! I\'m your HostelAssist chatbot. How can I help you today? '
        'You can ask about complaints, fees, mess menu, room details, or hostel rules.';
  }

  /// Generate help response
  String _getHelpResponse() {
    return 'I can help you with:\n'
        '• Check complaint status\n'
        '• View fee information\n'
        '• See today\'s mess menu\n'
        '• Get room details\n'
        '• Learn hostel rules\n'
        '• Maintenance guidance\n\n'
        'Just ask your question in natural language!';
  }

  /// Generate default response for unknown intents
  String _getDefaultResponse() {
    return 'I\'m not sure I understand. I can help you with complaints, fees, mess menu, '
        'room information, or hostel rules. Could you please rephrase your question?';
  }

  /// Log conversation to Firestore for analytics
  Future<void> _logConversation({
    required String studentId,
    required String message,
    required String response,
    required String intent,
    required List<String> keywords,
  }) async {
    try {
      final messageId = _uuid.v4();

      final chatLog = ChatbotModel(
        messageId: messageId,
        studentId: studentId,
        message: message,
        response: response,
        detectedIntent: intent,
        keywords: keywords,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionChatbotLogs)
          .doc(messageId)
          .set(chatLog.toJson());

      _logger.d('Conversation logged: $messageId');
    } catch (e) {
      _logger.w('Failed to log conversation', error: e);
      // Don't throw - logging failure shouldn't break the chatbot
    }
  }

  /// Get chat history for a student
  Future<List<ChatbotModel>> getChatHistory(
    String studentId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionChatbotLogs)
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatbotModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching chat history', error: e);
      throw FirestoreException(
        'Failed to fetch chat history: ${e.toString()}',
        details: e,
      );
    }
  }
}
