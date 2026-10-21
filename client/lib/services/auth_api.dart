import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';

class AuthApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 8);
  final http.Client _client = http.Client();

  Future<AuthResponse> _postWithRetry(
    String endpoint,
    Map<String, dynamic> body, {
    int maxRetries = 1,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(_requestTimeout);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return AuthResponse.fromJson(data);
        } else {
          final error = jsonDecode(response.body)['error'] as String? ?? 'Request failed';
          throw Exception(error);
        }
      } on SocketException {
        if (attempts > maxRetries) {
          throw Exception('Unable to connect to the server. Please check your connection and try again.');
        }
        await Future.delayed(const Duration(seconds: 1));
      } on TimeoutException {
        if (attempts > maxRetries) {
          throw Exception('The login request timed out. Please try again.');
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Request failed after multiple attempts');
  }

  Future<AuthResponse> register({
    required String username,
    required String password,
    required String email,
    String? phone,
    DateTime? birthday,
  }) async {
    return _postWithRetry('/register', {
      'username': username,
      'password': password,
      'email': email,
      if (phone != null) 'phone': phone,
      if (birthday != null) 'birthday': birthday.toIso8601String().split('T')[0],
    }, maxRetries: 1);
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    return _postWithRetry('/login', {
      'username': username,
      'password': password,
    }, maxRetries: 1);
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    ).timeout(_requestTimeout);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to change password';
      throw Exception(error);
    }
  }

  Future<void> changeEmail({
    required String newEmail,
    required String accessToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/change-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'email': newEmail}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to change email';
      throw Exception(error);
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to request password reset';
      throw Exception(error);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to reset password';
      throw Exception(error);
    }
  }

  Future<void> deleteAccount({required String accessToken, required String password}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/auth/delete-account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'password': password}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to delete account';
      throw Exception(error);
    }
  }

  Future<List<SessionInfo>> getActiveSessions({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/sessions'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['sessions'] as List).map((e) => SessionInfo.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch sessions');
    }
  }

  Future<void> revokeSession({required String sessionId, required String accessToken}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/auth/sessions/$sessionId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke session');
    }
  }

  Future<void> revokeAllOtherSessions({required String accessToken}) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/auth/sessions'),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to revoke other sessions');
    }
  }

  Future<Map<String, String>> refreshAccessToken({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'access_token': data['access_token'] as String,
        'refresh_token': data['refresh_token'] as String,
      };
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Failed to refresh token';
      throw Exception(error);
    }
  }

  void dispose() => _client.close();
}

class SessionInfo {
  final String id;
  final String deviceInfo;
  final String ipAddress;
  final String userAgent;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isCurrent;

  SessionInfo({
    required this.id,
    required this.deviceInfo,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
    id: json['id'] as String,
    deviceInfo: json['device_info'] as String? ?? 'Unknown device',
    ipAddress: json['ip_address'] as String? ?? 'Unknown',
    userAgent: json['user_agent'] as String? ?? 'Unknown',
    createdAt: DateTime.parse(json['created_at'] as String),
    lastActiveAt: DateTime.parse(json['last_active_at'] as String),
    isCurrent: json['is_current'] as bool? ?? false,
  );
}
