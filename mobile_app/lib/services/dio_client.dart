import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late Dio dio;
  final _storage = const FlutterSecureStorage();

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          String? token = await _storage.read(key: 'accessToken') ?? prefs.getString('token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔑 Auth Header Added: Bearer ${token.substring(0, 10)}...');
          } else {
            debugPrint('⚠️ Auth Header MISSING: No token found in storage!');
          }

          // Debug Logging
          debugPrint('🌐 REQUEST: [${options.method}] ${options.baseUrl}${options.path}');
          if (options.data != null) {
            debugPrint('📦 Request Body: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Debug Logging
          debugPrint('✅ RESPONSE: [${response.statusCode}] ${response.requestOptions.path}');
          debugPrint('📝 Response Body: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Debug Logging
          debugPrint('❌ ERROR: [${e.response?.statusCode}] ${e.requestOptions.path}');
          debugPrint('💬 Error Message: ${e.message}');
          if (e.response?.data != null) {
            debugPrint('📝 Error Response Body: ${e.response?.data}');
          }

          if (e.response?.statusCode == 401) {
            // Attempt to refresh token
            final success = await _refreshToken();
            if (success) {
              // Retry the original request
              final options = e.requestOptions;
              final newToken = await _storage.read(key: 'accessToken');
              options.headers['Authorization'] = 'Bearer $newToken';
              
              final response = await dio.request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              );
              return handler.resolve(response);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = await _storage.read(key: 'refreshToken') ?? prefs.getString('refreshToken');
      if (refreshToken == null) return false;

      final response = await dio.post('/auth/refresh-token', data: {'refreshToken': refreshToken});
      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        await _storage.write(key: 'accessToken', value: newAccessToken);
        await prefs.setString('token', newAccessToken);
        return true;
      }
    } catch (e) {
      print('❌ Refresh token failed: $e');
    }
    return false;
  }

  Dio get instance => dio;
}
