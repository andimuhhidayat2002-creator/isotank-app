import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _role;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    
    if (_token != null) {
      _isAuthenticated = true;
      _apiService.setToken(_token!);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      if (kDebugMode) {
        print('📡 Login Response: $response');
      }

      final bool isSuccess = response['success'] == true || 
                             response['status'] == 'success' || 
                             response['status'] == true;
      
      if (isSuccess) {
        _token = response['token'] ?? response['data']?['token'];
        
        // Robust user data extraction
        final userData = response['user'] ?? 
                        response['data']?['user'] ?? 
                        response['data'];
        
        _user = userData is Map<String, dynamic> ? userData : null;
        
        // Robust role extraction
        _role = userData?['role']?.toString() ?? 
                response['role']?.toString() ?? 
                response['data']?['role']?.toString();
        
        if (kDebugMode) {
          print('🎉 Login successful!');
          print('👤 User: ${_user?['name']}');
          print('🔑 Role: $_role');
        }
        
        if (_token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          if (_role != null) {
            await prefs.setString('role', _role!);
          }
          
          _apiService.setToken(_token!);
          _isAuthenticated = true;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Ignore
    }

    _token = null;
    _role = null;
    _user = null;
    _isAuthenticated = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }
}
