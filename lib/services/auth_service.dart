import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final data = {
        'email': email,
        'password': password,
      };

      final response = await apiClient.post('/login', data: data);

      if (response.statusCode == 200) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('user', jsonEncode(data['user']));

        return {
          'success': true,
          'user': User.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'فشل تسجيل الدخول',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    int? specialtyId,
    double? consultationFee,
  }) async {
    try {
      // ✅ تحضير البيانات الأساسية
      final Map<String, dynamic> data = {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
      };

      // ✅ إضافة بيانات الطبيب إذا كان الدور طبيباً
      if (role == 'doctor') {
        if (specialtyId != null) {
          data['specialty_id'] = specialtyId;  // ✅ الآن يعمل بشكل صحيح
        }
        if (consultationFee != null) {
          data['consultation_fee'] = consultationFee;  // ✅ الآن يعمل بشكل صحيح
        }
      }

      print('📦 بيانات التسجيل: $data');

      final response = await apiClient.post('/register', data: data);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response.data['access_token']);
        await prefs.setString('user', jsonEncode(response.data['user']));

        return {
          'success': true,
          'user': User.fromJson(response.data['user']),
        };
      } else {
        // ✅ معالجة أخطاء التحقق (422)
        if (response.statusCode == 422 && response.data.containsKey('errors')) {
          final errors = response.data['errors'];
          String errorMessage = '';
          
          if (errors.containsKey('email')) {
            errorMessage = errors['email'][0];
          } else if (errors.containsKey('password')) {
            errorMessage = errors['password'][0];
          } else if (errors.containsKey('full_name')) {
            errorMessage = errors['full_name'][0];
          } else {
            errorMessage = 'بيانات غير صحيحة';
          }
          
          return {
            'success': false,
            'message': errorMessage,
          };
        }
        
        return {
          'success': false,
          'message': response.data['message'] ?? 'فشل التسجيل',
        };
      }
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/logout');
    } catch (e) {
      // تجاهل الأخطاء
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}