import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _error;
  bool _isLoading = false;
  
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get error => _error;
  bool get isLoading => _isLoading;
  
  AuthProvider() {
    _checkLoginStatus();
  }
  
  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await apiService.isLoggedIn();
    notifyListeners();
  }
  
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await apiService.register(email, password);
      _isLoggedIn = true;
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await apiService.login(email, password);
      _isLoggedIn = true;
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      await apiService.logout();
    } catch (e) {
      print('Logout error: $e');
    }
    _isLoggedIn = false;
    _userEmail = null;
    _error = null;
    notifyListeners();
  }
  
  void clearLogoutState() {
    _isLoggedIn = false;
    _userEmail = null;
    _error = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
