import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gemini API service for AI chatbot responses
/// Integrates with Google's Gemini API for intelligent conversations
class GeminiService {
  static const String _apiKeyPrefsKey = 'gemini_api_key';

  final Logger _logger = Logger();
  String? _apiKey;

  /// Initialize and load API key from preferences
  Future<void> initialize() async {
    _apiKey = await getApiKey();
  }

  /// Get stored API key
  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_apiKeyPrefsKey);
    } catch (e) {
      _logger.e('Error getting API key', error: e);
      return null;
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
      _logger.e('Error saving API key', error: e);
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
      _logger.e('Error clearing API key', error: e);
      return false;
    }
  }

  /// Check if API key is configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Send message to Gemini API and get response
  Future<String> sendMessage({required String message, String? context}) async {
    if (!isConfigured) {
      return 'Please configure your Gemini API key in settings (top-right icon).';
    }

    try {
      _logger.i('Sending message to Gemini API');

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey',
      );

      // Build the prompt with context
      final fullPrompt = context != null
          ? '''You are a helpful AI assistant for a hostel management system. 
          
Context: $context

Student Question: $message

Please provide a helpful, friendly, and concise response. If the question is about complaints, fees, mess menu, or room information, use the context provided. Keep responses under 150 words.'''
          : '''You are a helpful AI assistant for a hostel management system.

Student Question: $message

Please provide a helpful, friendly, and concise response about hostel-related queries (complaints, fees, mess menu, rooms, rules, etc.). Keep responses under 150 words.''';

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
            'topP': 0.8,
            'topK': 40,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Gemini API response received');

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text.toString().trim();
        } else {
          _logger.w('No candidates in Gemini response');
          return 'I apologize, but I couldn\'t generate a response. Please try rephrasing your question.';
        }
      } else if (response.statusCode == 400) {
        _logger.e('Invalid API key or request: ${response.body}');
        return 'Invalid API key. Please check your API key in settings.';
      } else if (response.statusCode == 429) {
        _logger.e('Rate limit exceeded');
        return 'Too many requests. Please wait a moment and try again.';
      } else {
        _logger.e(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
        return 'Sorry, I encountered an error (${response.statusCode}). Please try again later.';
      }
    } catch (e) {
      _logger.e('Error calling Gemini API', error: e);
      return 'Sorry, I couldn\'t connect to the AI service. Please check your internet connection and try again.';
    }
  }

  /// Get hostel-specific context for better responses
  Future<String> getHostelContext({
    String? studentId,
    required String intent,
  }) async {
    // This can be enhanced to fetch real data from Firestore
    // For now, providing general context
    final contextMap = {
      'complaint_status':
          'Students can submit complaints about maintenance, cleanliness, etc. Admins review and resolve them.',
      'fee_info':
          'Students have fees for room rent, mess, and maintenance. Payment status shows pending, paid, or overdue.',
      'mess_menu':
          'Daily mess menu shows breakfast, lunch, and dinner items. Students can provide feedback.',
      'room_info':
          'Rooms are in blocks A, B, C, D with different types: single, double, triple, quad. Each has amenities.',
      'rules_regulations':
          'Hostel rules include curfew times, visitor policies, cleanliness standards, and noise restrictions.',
      'maintenance':
          'For maintenance issues, submit a complaint with details and photos. Admin will review and assign priority.',
      'help':
          'This chatbot can help with complaints, fees, mess menu, room info, and general hostel queries.',
    };

    return contextMap[intent] ??
        'General hostel management queries can be answered here.';
  }
}
