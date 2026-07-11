import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // ✅ استخدم localhost أو IP الحقيقي
  static const String baseUrl = 'http://192.168.1.106:8000/api';
  
  late Dio dio;
  
  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),  // ✅ زيادة الوقت
      receiveTimeout: const Duration(seconds: 60),  // ✅ زيادة الوقت
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('🌐 [REQUEST] ${options.method} ${options.path}');
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ [ERROR] ${error.message}');
        if (error.response?.statusCode == 401) {
          final prefs = SharedPreferences.getInstance();
          prefs.then((p) {
            p.remove('access_token');
            p.remove('user');
          });
        }
        return handler.next(error);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<Response> get(String endpoint) async {
    return dio.get(endpoint);
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    return dio.post(endpoint, data: data);
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    return dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    return dio.delete(endpoint);
  }
}