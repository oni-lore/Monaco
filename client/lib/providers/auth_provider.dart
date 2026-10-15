import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_api.dart';

class AuthProvider extends ChangeNotifier {
  // final AuthApiService _api = AuthApiService();

  User? _user;
  AuthTokens? _tokens;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  AuthTokens? get tokens => _tokens;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _tokens != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');

      if (accessToken != null && refreshToken != null) {
        _tokens = AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
        await _loadUserProfile();
      }
    } catch (e) {
      await _clearAuthData();
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_tokens == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (e) {
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
