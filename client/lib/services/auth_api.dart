import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';

class AuthApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 10);
  final http.Client _client = http.Client();

  Future<AuthResponse> register({
    required String username,
    required String password,
    required String email,
    String? phone,
    DateTime? birthday,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        if (phone != null) 'phone': phone,
        if (birthday != null) 'birthday': birthday.toIso8601String().split('T')[0],
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Registration failed';
      throw Exception(error);
    }
  }

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } else {
      final error = jsonDecode(response.body)['error'] as String? ?? 'Login failed';
      throw Exception(error);
    }
  }

  Future<void> logout({required String refreshToken}) async {
    await _client.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
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
      Uri.parse('$baseUrl/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
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
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
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
