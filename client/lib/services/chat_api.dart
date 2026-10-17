import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class ChatApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 10);
  final http.Client _client = http.Client();

  Future<List<Conversation>> getConversations({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['conversations'] as List? ?? []) as List;
      return items.map((e) => Conversation.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to load conversations';
      throw Exception(error);
    }
  }

  Future<Conversation> getConversation({
    required String conversationId,
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/conversations/$conversationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Conversation.fromJson(data['conversation'] as Map<String, dynamic>);
    } else if (response.statusCode == 403) {
      throw Exception('You are not a participant in this conversation');
    } else if (response.statusCode == 404) {
      throw Exception('Conversation not found');
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to load conversation';
      throw Exception(error);
    }
  }

  Future<List<Message>> getMessages({
    required String conversationId,
    required String accessToken,
    int limit = 50,
    String? before,
  }) async {
    final uri = Uri.parse('$baseUrl/conversations/$conversationId/messages').replace(
      queryParameters: {
        if (before != null) 'before': before,
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['messages'] as List? ?? []) as List;
      return items.map((e) => Message.fromJson(Map<String, dynamic>.from(e))).toList();
    } else if (response.statusCode == 403) {
      throw Exception('You are not a participant in this conversation');
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to load messages';
      throw Exception(error);
    }
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String accessToken,
    required String contentType,
    required String contentText,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'content_type': contentType,
        'content_text': contentText,
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // The backend returns { success: true, messageId, created_at }
      // We need to fetch the full message to construct a Message object
      // For now, construct a minimal one from the response
      return Message(
        id: data['messageId'] as String? ?? '',
        conversationId: conversationId,
        senderId: '', // Will be filled when we refresh messages
        senderUsername: '',
        contentType: contentType,
        contentText: contentText,
        createdAt: DateTime.parse(data['created_at'] as String),
      );
    } else if (response.statusCode == 403) {
      throw Exception('You are not a participant in this conversation');
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to send message';
      throw Exception(error);
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required String accessToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/search').replace(
        queryParameters: {'q': query},
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['users'] as List? ?? []) as List;
      return items.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Invalid search query';
      throw Exception(error);
    } else {
      throw Exception('Failed to search users');
    }
  }

  Future<Map<String, dynamic>> createConversation({
    required String accessToken,
    required String targetUserId,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'target_user_id': targetUserId}),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 403) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Cannot create conversation';
      throw Exception(error);
    } else if (response.statusCode == 409) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Conversation already exists';
      throw Exception(error);
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to create conversation';
      throw Exception(error);
    }
  }

  Future<User> getMyProfile({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to load profile';
      throw Exception(error);
    }
  }

  void dispose() => _client.close();
}
