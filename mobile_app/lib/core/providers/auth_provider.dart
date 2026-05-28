import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _error;
  String? _devOtp;
  String? _pendingMobile;
  String? _pendingPurpose;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String? get devOtp => _devOtp;
  String? get pendingMobile => _pendingMobile;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Dual-read for reliability
    _token = await _storage.read(key: 'accessToken') ?? prefs.getString('token');
    
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String mobile,
    required String email,
    required String password,
    required String village,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.register(
        fullName: fullName,
        mobile: mobile,
        email: email,
        password: password,
        village: village,
        state: state,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
      );
      
      _pendingMobile = mobile;
      _pendingPurpose = 'registration';
      _devOtp = response['devOtp'];
      
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String mobile, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(mobile: mobile, password: password);
      
      _pendingMobile = mobile;
      _pendingPurpose = 'login';
      _devOtp = response['devOtp'];
      
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_pendingMobile == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.verifyOtp(
        mobile: _pendingMobile!,
        otp: otp,
        purpose: _pendingPurpose!,
      );
      
      _token = response['token'] ?? response['accessToken'];
      _user = response['user'];
      _pendingMobile = null;
      _pendingPurpose = null;
      _devOtp = null;
      
      // Persist Token Securely
      await _storage.write(key: 'accessToken', value: _token!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user!));
      
      if (response['refreshToken'] != null) {
        await _storage.write(key: 'refreshToken', value: response['refreshToken']);
        await prefs.setString('refreshToken', response['refreshToken']);
      }
      
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- RESTORED PROFILE METHODS ---

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String village,
    required String state,
    required String pincode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.updateProfile(
        fullName: fullName,
        email: email,
        village: village,
        state: state,
        pincode: pincode,
      );
      
      _user = response['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!));
      
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfilePhoto(String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.updateProfilePhoto(imagePath);
      _user!['profile_photo_url'] = response['photoUrl'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!));
      
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _api.getMe();
      if (response['success']) {
        _user = response['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
    _token = null; _user = null;
    notifyListeners();
  }

  Future<bool> resendOtp() async {
    if (_pendingMobile == null) return false;
    try {
      final response = await _api.resendOtp(mobile: _pendingMobile!);
      _devOtp = response['devOtp'];
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword({required String mobile, required String newPassword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.resetPassword(mobile: mobile, newPassword: newPassword);
      return true;
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatError(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check if the backend is running and matches the correct IP.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Connection error. Please check your network or backend IP configuration.';
      }
    }
    if (e.toString().contains('401')) return 'Unauthorized: Please check your credentials.';
    if (e.toString().contains('400')) return 'Bad Request: Please check your input.';
    return e.toString();
  }
}