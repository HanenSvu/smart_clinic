import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
//import '../../models/user.dart';  // ✅ تأكد من import

class BookAppointment extends StatefulWidget {
  final int? doctorId;
  final String? doctorName;

  const BookAppointment({super.key, this.doctorId, this.doctorName});

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  String? _selectedDate;
  String? _selectedTime;
  int? _selectedDoctorUserId;  // ✅ user_id الخاص بالطبيب
  int? _selectedSpecialtyId;
  bool _isLoading = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctorUserId = widget.doctorId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppointmentProvider>();

      print('📌 تحميل التخصصات...');
      await provider.loadSpecialties();
      print('📌 عدد التخصصات: ${provider.specialties.length}');

      print('📌 تحميل الأطباء...');
      await provider.loadDoctors();
      print('📌 عدد الأطباء: ${provider.doctors.length}');

      // ✅ طباعة تفاصيل الأطباء مع user_id
      for (var doctor in provider.doctors) {
        print('👨‍⚕️ الطبيب: doctor.id=${doctor.id}, user.id=${doctor.user?.id}, Name=${doctor.displayName}');
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        locale: const Locale('ar'),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.blue,
              colorScheme: const ColorScheme.light(primary: Colors.blue),
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedDate = picked.toIso8601String().split('T')[0];
        });
        print('📅 التاريخ المختار: $_selectedDate');
      }
    } catch (e) {
      print('❌ خطأ في اختيار التاريخ: $e');
      _showDateTextField();
    }
  }

  void _showDateTextField() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أدخل التاريخ'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'YYYY-MM-DD',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _selectedDate = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_selectedDate != null) {
                setState(() {});
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime() async {
    try {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.blue,
              colorScheme: const ColorScheme.light(primary: Colors.blue),
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && mounted) {
        final String timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        setState(() {
          _selectedTime = timeString;
        });
        print('🕐 الوقت المختار: $_selectedTime');
      }
    } catch (e) {
      print('❌ خطأ في اختيار الوقت: $e');
      _showTimeTextField();
    }
  }

  void _showTimeTextField() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أدخل الوقت'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'HH:MM',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _selectedTime = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_selectedTime != null) {
                setState(() {});
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Future<void> _testApiDirectly() async {
    print('🧪 اختبار مباشر للـ API');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      final dio = Dio();
      final response = await dio.get(
        'http://localhost:8000/api/doctors',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      print('✅ نتيجة الاختبار المباشر: ${response.statusCode}');
      print('📨 عدد الأطباء: ${(response.data as List).length}');
      
      for (var doctor in response.data as List) {
        print('👨‍⚕️ دكتور: doctor.id=${doctor['id']}, user_id=${doctor['user_id']}, Name=${doctor['user']['full_name']}');
      }
    } catch (e) {
      print('❌ خطأ في الاختبار المباشر: $e');
    }
  }

  Future<void> _handleBooking(AppointmentProvider provider) async {
    if (_selectedDoctorUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار الطبيب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار التاريخ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى اختيار الوقت'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isBooking) return;

    setState(() => _isBooking = true);

    try {
      final auth = context.read<AuthProvider>();
      
      if (auth.user?.role != 'patient') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ يجب أن تكون مريضاً لحجز موعد'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isBooking = false);
        return;
      }

      // ✅ التحقق من أن الطبيب موجود
      final selectedDoctor = provider.doctors.firstWhere(
        (d) => d.user?.id == _selectedDoctorUserId,
        orElse: () => provider.doctors.first,
      );

      // ✅ إرسال user_id الصحيح
      final doctorIdToSend = selectedDoctor.user?.id ?? _selectedDoctorUserId!;

      print('========================================');
      print('🚀 بدء عملية حجز الموعد');
      print('👤 المستخدم: ${auth.user?.fullName} (${auth.user?.role})');
      print('📋 _selectedDoctorUserId: $_selectedDoctorUserId');
      print('📋 doctorIdToSend: $doctorIdToSend');
      print('📅 date: $_selectedDate');
      print('🕐 time: $_selectedTime');
      print('========================================');

      final success = await provider.bookAppointment(
        doctorId: doctorIdToSend,  // ✅ استخدم user_id الخاص بالطبيب
        date: _selectedDate!,
        time: _selectedTime!,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حجز الموعد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${provider.error ?? "فشل الحجز"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ خطأ في عملية الحجز: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();

    final filteredDoctors = _selectedSpecialtyId != null
        ? appointmentProvider.doctors
            .where((d) => d.specialtyId == _selectedSpecialtyId)
            .toList()
        : appointmentProvider.doctors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorName != null
            ? 'حجز موعد مع ${widget.doctorName}'
            : 'حجز موعد جديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading || appointmentProvider.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل البيانات...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة تحميل البيانات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testApiDirectly,
                      icon: const Icon(Icons.api),
                      label: const Text('اختبار API مباشر'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'التخصص:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (appointmentProvider.specialties.isEmpty)
                    const Text(
                      'لا توجد تخصصات - تأكد من تشغيل Backend',
                      style: TextStyle(color: Colors.red),
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
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('جميع التخصصات'),
                        ),
                        ...appointmentProvider.specialties.map((specialty) {
                          return DropdownMenuItem<int>(
                            value: specialty.id,
                            child: Text(specialty.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecialtyId = value;
                          _selectedDoctorUserId = null;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'اختر الطبيب:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (appointmentProvider.doctors.isEmpty)
                    Column(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          size: 40,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'لا يوجد أطباء متاحون',
                          style: TextStyle(color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('إعادة تحميل'),
                        ),
                      ],
                    )
                  else if (filteredDoctors.isEmpty)
                    const Text(
                      'لا يوجد أطباء في هذا التخصص',
                      style: TextStyle(color: Colors.orange),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDoctorUserId,
                      hint: const Text('اختر الطبيب'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: filteredDoctors.map((doctor) {
                        return DropdownMenuItem<int>(
                          value: doctor.user?.id,  // ✅ استخدم user.id
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                doctor.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${doctor.displaySpecialty} - ${doctor.consultationFee} ₪',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctorUserId = value;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'اختر التاريخ:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate ?? 'اختر التاريخ',
                              style: TextStyle(
                                color: _selectedDate != null ? Colors.black : Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'اختر الوقت:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTime ?? 'اختر الوقت',
                              style: TextStyle(
                                color: _selectedTime != null ? Colors.black : Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedDoctorUserId != null &&
                              _selectedDate != null &&
                              _selectedTime != null &&
                              !_isBooking)
                          ? () => _handleBooking(appointmentProvider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: _selectedDoctorUserId != null &&
                                _selectedDate != null &&
                                _selectedTime != null
                            ? Colors.green
                            : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: _isBooking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('تأكيد الحجز', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔍 معلومات Debug:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'التخصصات: ${appointmentProvider.specialties.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'الأطباء: ${appointmentProvider.doctors.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'الأطباء المفلترين: ${filteredDoctors.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (_selectedDoctorUserId != null)
                          Text(
                            'الطبيب المختار (user_id): $_selectedDoctorUserId',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (_selectedDate != null)
                          Text(
                            'التاريخ: $_selectedDate',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (_selectedTime != null)
                          Text(
                            'الوقت: $_selectedTime',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}