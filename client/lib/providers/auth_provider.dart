import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_api.dart';
import '../services/chat_api.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  AuthTokens? _tokens;
  bool _isLoading = false;
  bool _isLoggingIn = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  AuthTokens? get tokens => _tokens;
  bool get isLoading => _isLoading;
  bool get isLoggingIn => _isLoggingIn;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _tokens != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    debugPrint('AuthProvider._initializeAuth: started');
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');

      if (accessToken != null && refreshToken != null) {
        debugPrint('AuthProvider._initializeAuth: tokens found, loading profile');
        _tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
        await _loadUserProfile();
      } else {
        debugPrint('AuthProvider._initializeAuth: no tokens found');
      }
    } catch (e) {
      debugPrint('AuthProvider._initializeAuth: exception caught');
      await _clearAuthData();
    } finally {
      _isInitialized = true;
      _isLoading = false;
      debugPrint('AuthProvider._initializeAuth: finished, isInitialized=$_isInitialized');
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    debugPrint('AuthProvider._loadUserProfile: started');
    if (_tokens == null) {
      debugPrint('AuthProvider._loadUserProfile: no tokens, aborting');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
      try {
        final freshUser = await ChatApiService().getMyProfile(accessToken: _tokens!.accessToken);
        _user = freshUser;
        await _saveUserData(freshUser);
        debugPrint('AuthProvider._loadUserProfile: profile loaded from server');
      } catch (_) {
        debugPrint('AuthProvider._loadUserProfile: server unreachable, using cached data');
      }
    } catch (e) {
      debugPrint('AuthProvider._loadUserProfile: exception caught');
      await _clearAuthData();
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String email,
  }) async {
    _setLoading(true);
    try {
      final response = await AuthApiService().register(
        username: username,
        password: password,
        email: email,
      );
      await _saveAuthData(response);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login({required String username, required String password}) async {
    if (_isLoggingIn) return;
    _isLoggingIn = true;
    _setLoading(true);
    try {
      final response = await AuthApiService().login(username: username, password: password);
      await _saveAuthData(response);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
      _isLoggingIn = false;
    }
  }

  /// Attempt to refresh the access token using the refresh token.
  /// Requires a /auth/refresh endpoint on the backend.
  Future<bool> refreshAccessToken() async {
    if (_tokens == null) return false;
    _setLoading(true);
    try {
      // Note: The backend currently does not have a /auth/refresh endpoint.
      // When added, call it here and update _tokens with the new access token.
      // For now, return false to indicate refresh is not available.
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> _saveAuthData(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', response.tokens.accessToken);
    await prefs.setString('refresh_token', response.tokens.refreshToken);
    await prefs.setString('user_data', jsonEncode(response.user.toJson()));

    _tokens = response.tokens;
    _user = response.user;
    notifyListeners();
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_tokens != null) {
      try {
        await AuthApiService().logout(refreshToken: _tokens!.refreshToken);
      } catch (_) {
        // Ignore logout errors
      }
    }
    await _clearAuthData();
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    _user = null;
    _tokens = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
