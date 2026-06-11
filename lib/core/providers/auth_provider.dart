import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonarota_shared/tonarota_shared.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Usuario? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  Usuario? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    tryAutoLogin();
  }

  /// Tenta restaurar a sessão salva no armazenamento local
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('user_profile');

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        _currentUser = Usuario.fromJson(jsonDecode(savedUserJson) as Map<String, dynamic>);
        _apiService.setToken(_token);
      }
    } catch (e) {
      print('Erro ao tentar auto-login: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/v1/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _token = data['token'] as String;
        _currentUser = Usuario.fromJson(data['user'] as Map<String, dynamic>);
        
        _apiService.setToken(_token);

        // Salva localmente as credenciais para persistir sessão
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_profile', jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _error = data['error'] as String? ?? 'Falha ao autenticar.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro de rede: Não foi possível conectar ao servidor.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _apiService.setToken(null);
    
    // Limpa os dados persistidos no armazenamento local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');

    notifyListeners();
  }

  Future<void> updateCurrentUser(Usuario user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(user.toJson()));
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
