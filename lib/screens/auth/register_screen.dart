import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  String _selectedRole = 'patient';
  int? _selectedSpecialtyId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // ✅ تحميل التخصصات عند فتح الصفحة
        context.read<AppointmentProvider>().loadSpecialties();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _consultationFeeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // ✅ التحقق من صحة البيانات الأساسية
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إدخال الاسم الكامل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إدخال البريد الإلكتروني'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إدخال كلمة المرور'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ كلمات المرور غير متطابقة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ التحقق من صحة بيانات الطبيب
    if (_selectedRole == 'doctor') {
      if (_selectedSpecialtyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ يرجى اختيار التخصص'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_consultationFeeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ يرجى إدخال رسوم الكشف'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final fee = double.tryParse(_consultationFeeController.text);
      if (fee == null || fee <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ يرجى إدخال رسوم كشف صحيحة (رقم موجب)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        specialtyId: _selectedRole == 'doctor' ? _selectedSpecialtyId : null,
        consultationFee: _selectedRole == 'doctor'
            ? double.tryParse(_consultationFeeController.text)
            : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء الحساب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        String errorMessage = auth.error ?? 'فشل إنشاء الحساب';

        if (errorMessage.contains('email') || errorMessage.contains('taken')) {
          errorMessage = '⚠️ البريد الإلكتروني مستخدم بالفعل. يرجى استخدام بريد آخر.';
        } else if (errorMessage.contains('password') && errorMessage.contains('6')) {
          errorMessage = '⚠️ كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ خطأ في التسجيل: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بإنشاء حساب للاستفادة من خدمات العيادة الذكية',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ✅ الاسم الكامل
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'أدخل اسمك الكامل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ البريد الإلكتروني
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ نوع الحساب
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'نوع الحساب',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_ind),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'patient',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20),
                          SizedBox(width: 8),
                          Text('مريض'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'doctor',
                      child: Row(
                        children: [
                          Icon(Icons.medical_services, size: 20),
                          SizedBox(width: 8),
                          Text('طبيب'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ✅ حقل التخصص (يظهر فقط للطبيب)
                if (_selectedRole == 'doctor') ...[
                  const Text(
                    'التخصص:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (appointmentProvider.isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (appointmentProvider.specialties.isEmpty)
                    const Text(
                      '⚠️ لا توجد تخصصات متاحة',
                      style: TextStyle(color: Colors.orange),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _selectedSpecialtyId,
                      hint: const Text('اختر التخصص'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: appointmentProvider.specialties.map((specialty) {
                        return DropdownMenuItem<int>(
                          value: specialty.id,
                          child: Text(specialty.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecialtyId = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // ✅ رسوم الكشف (يظهر فقط للطبيب)
                  TextFormField(
                    controller: _consultationFeeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'رسوم الكشف (₪)',
                      hintText: 'مثال: 150',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ✅ كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ تأكيد كلمة المرور
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    hintText: 'أعد إدخال كلمة المرور',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ زر إنشاء حساب
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'إنشاء حساب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ رابط تسجيل الدخول
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}