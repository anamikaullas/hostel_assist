import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatbot_service.dart';

/// Google Gemini API service for AI chatbot responses
/// Uses Gemini 2.0 Flash — free tier, no billing required
class GrokService {
  static const String _apiKeyPrefsKey = 'gemini_api_key';
  static const String _model = 'gemini-3.0-flash';
  static const String _defaultApiKey =
      'AIzaSyB1IkWLPfcbOH3-m_mWhX9BtcevFGGw_PQ';

  static const String _systemPrompt =
      'You are HostelBot, a dedicated AI assistant for college hostel students. '
      'You help students with hostel-related queries including:\n'
      '- Complaint submissions and status tracking\n'
      '- Fee payments, dues, and receipts\n'
      '- Daily mess menu and food feedback\n'
      '- Room details, block info, and roommate queries\n'
      '- Hostel rules, curfew timings, and visitor policies\n'
      '- Maintenance requests and repair follow-ups\n'
      '- Study room and common area bookings\n'
      '- Laundry, internet, and facility queries\n\n'
      'Always be friendly, concise, and empathetic. '
      'Use simple language and keep responses under 150 words. '
      'If a query is unrelated to hostel life, politely redirect to hostel topics.';

  final Logger _logger = Logger();
  final ChatbotService _fallbackService = ChatbotService();
  String? _apiKey;

  /// Initialize and load API key from preferences, falling back to default
  Future<void> initialize() async {
    _apiKey = await getApiKey();
  }

  /// Get stored API key, falling back to the built-in default
  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_apiKeyPrefsKey);
      return (stored != null && stored.isNotEmpty) ? stored : _defaultApiKey;
    } catch (e) {
      _logger.e('Error getting Grok API key', error: e);
      return _defaultApiKey;
    }
  }

  /// Save API key to preferences
  Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_apiKeyPrefsKey, apiKey);
      if (success) {
        _apiKey = apiKey;
      }
      return success;
    } catch (e) {
      _logger.e('Error saving Grok API key', error: e);
      return false;
    }
  }

  /// Clear API key from preferences
  Future<bool> clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = null;
      return await prefs.remove(_apiKeyPrefsKey);
    } catch (e) {
      _logger.e('Error clearing Grok API key', error: e);
      return false;
    }
  }

  /// Always configured because a default key is bundled
  bool get isConfigured => true;

  /// Send a message to Gemini and receive a hostel-tailored response.
  /// Falls back to local ChatbotService on API errors.
  Future<String> sendMessage({
    required String message,
    String? context,
    String? studentId,
  }) async {
    try {
      final effectiveKey = _apiKey ?? _defaultApiKey;
      _logger.i('Sending message to Gemini API');

      final fullPrompt = context != null
          ? '$_systemPrompt\n\nContext about the student\'s hostel data:\n$context\n\nStudent question: $message'
          : '$_systemPrompt\n\nStudent question: $message';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$effectiveKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 256,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Gemini API response received');
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final text =
              candidates[0]['content']['parts'][0]['text'] as String?;
          return text?.trim() ??
              'I couldn\'t generate a response. Please try again.';
        } else {
          _logger.w('No candidates in Gemini response');
          return 'I couldn\'t generate a response. Please try rephrasing your question.';
        }
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        _logger.w('Gemini API unavailable (${response.statusCode}) — using local fallback');
        return await _fallbackService.processMessage(
          studentId: studentId ?? 'guest',
          message: message,
        );
      } else if (response.statusCode == 429) {
        _logger.e('Gemini rate limit exceeded');
        return 'Too many requests. Please wait a moment and try again.';
      } else {
        _logger.e('Gemini API error: ${response.statusCode} - ${response.body}');
        return await _fallbackService.processMessage(
          studentId: studentId ?? 'guest',
          message: message,
        );
      }
    } catch (e) {
      _logger.e('Error calling Gemini API', error: e);
      return 'Sorry, I couldn\'t connect to the AI service. Please check your internet connection and try again.';
    }
  }

  /// Get hostel-specific context to enrich Gemini's response
  String getHostelContext(String intent) {
    const contextMap = {
      'complaint_status':
          'The student is asking about their complaint submissions. Complaints can be about maintenance, cleanliness, security, mess food quality, etc. Status values are: pending, in-progress, resolved.',
      'fee_info':
          'The student is asking about fees. Hostel fees include room rent, mess charges, and maintenance levy. Payment status can be pending, paid, or overdue.',
      'mess_menu':
          'The student is asking about the mess (cafeteria) menu. Three meals are served daily: breakfast, lunch, and dinner.',
      'room_info':
          'The student is asking about their room or accommodation. Rooms are categorized by block, floor, type (single/double/triple/quad), and current occupancy.',
      'rules_regulations':
          'The student is asking about hostel rules such as curfew timings, visitor policy, noise restrictions, and cleanliness standards.',
      'maintenance':
          'The student needs help with a maintenance or repair issue. They should submit a complaint with details and a photo via the Complaints section.',
      'help':
          'The student needs general help navigating the hostel management app.',
    };

    return contextMap[intent] ??
        'General hostel query from a college student resident.';
  }
}
