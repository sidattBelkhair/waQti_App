import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _loading = true;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    try {
      final token = await _api.getAccessToken();
      if (token != null) {
        final res = await _api.getProfile();
        _user = User.fromJson(res.data['user']);
        SocketService().connect();
        SocketService().joinUser(_user!.id);
      }
    } catch (_) {
      await _api.clearTokens();
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String identifier, String mdp) async {
    try {
      _error = null;
      final res = await _api.login(identifier, mdp);
      return res.data['userId'];
    } catch (e) {
      _error = _getError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyOTP(String userId, String code) async {
    try {
      _error = null;
      final res = await _api.verifyOTP(userId, code);
      await _api.saveTokens(res.data['accessToken'], res.data['refreshToken']);
      _user = User.fromJson(res.data['user']);
      SocketService().connect();
      SocketService().joinUser(_user!.id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getError(e);
      notifyListeners();
      return false;
    }
  }

  Future<String?> register(String nom, String email, String tel, String mdp, String role) async {
    try {
      _error = null;
      final res = await _api.register(nom, email, tel, mdp, role);
      return res.data['userId'];
    } catch (e) {
      _error = _getError(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    try { await _api.logout(); } catch (_) {}
    await _api.clearTokens();
    SocketService().disconnect();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _api.getProfile();
      _user = User.fromJson(res.data['user']);
      notifyListeners();
    } catch (_) {}
  }

  String _getError(dynamic e) {
    if (e is dynamic && e.response?.data != null) return e.response.data['error'] ?? 'Erreur';
    return 'Erreur de connexion';
  }
}
