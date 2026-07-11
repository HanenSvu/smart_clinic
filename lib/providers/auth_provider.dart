import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'dart:developer' as developer;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.getCurrentUser();
      _user = user;
      _isAuthenticated = user != null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
  developer.log('📤 إرسال طلب تسجيل الدخول إلى API', name: 'AUTH');
  
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    developer.log('📡 محاولة الاتصال بـ API', name: 'AUTH');    
    final result = await _authService.login(email, password);
    
    developer.log('📨 استجابة من API: $result', name: 'AUTH');
    
    if (result['success']) {
      _user = result['user'];
      _isAuthenticated = true;
      _error = null;
      developer.log('✅ تسجيل الدخول ناجح للمستخدم: ${_user?.fullName}', name: 'AUTH');
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isAuthenticated = false;
      developer.log('❌ فشل تسجيل الدخول: $_error', name: 'AUTH');
      notifyListeners();
      return false;
    }
  } catch (e, stack) {
    _error = e.toString();
    _isAuthenticated = false;
    developer.log('💥 استثناء في تسجيل الدخول', name: 'AUTH', error: e, stackTrace: stack);
    notifyListeners();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
Future<bool> register({
  required String fullName,
  required String email,
  required String password,
  required String role,
  int? specialtyId,
  double? consultationFee,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final result = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      specialtyId: specialtyId,
      consultationFee: consultationFee,
    );

    if (result['success']) {
      _user = result['user'];
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    _error = e.toString();
    _isAuthenticated = false;
    notifyListeners();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}


  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
}