import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ✅ متغيرات للتحقق من صحة الحقول
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ دالة التحقق من صحة الإيميل
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  // ✅ دالة التحقق من صحة كلمة المرور
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  Future<void> _login() async {
    // ✅ التحقق من صحة الحقول قبل الإرسال
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        final user = auth.user;
        if (user?.role == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/patient-dashboard');
        }
      } else {
        // ✅ عرض رسائل خطأ محددة بناءً على رسالة السيرفر
        final errorMessage = auth.error ?? 'فشل تسجيل الدخول';
        
        if (errorMessage.contains('email') || errorMessage.contains('credentials') || errorMessage.contains('Invalid')) {
          setState(() {
            _emailError = 'البريد الإلكتروني غير صحيح';
            _passwordError = 'كلمة المرور غير صحيحة';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ البريد الإلكتروني أو كلمة المرور غير صحيحة'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ خطأ في تسجيل الدخول: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'العيادة الذكية',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Clinic',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // ✅ حقل البريد الإلكتروني مع رسائل الخطأ
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'example@email.com',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  errorText: _emailError,
                  errorMaxLines: 2,
                ),
                onChanged: (_) {
                  // ✅ إزالة رسالة الخطأ عند الكتابة
                  if (_emailError != null) {
                    setState(() {
                      _emailError = _validateEmail(_emailController.text);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // ✅ حقل كلمة المرور مع رسائل الخطأ
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  hintText: 'أدخل كلمة المرور',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  errorText: _passwordError,
                  errorMaxLines: 2,
                ),
                onChanged: (_) {
                  // ✅ إزالة رسالة الخطأ عند الكتابة
                  if (_passwordError != null) {
                    setState(() {
                      _passwordError = _validatePassword(_passwordController.text);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),

              // ✅ زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ رابط إنشاء حساب جديد
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب؟',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}