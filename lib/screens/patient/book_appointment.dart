import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';

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
  int? _selectedDoctorUserId;
  int? _selectedSpecialtyId;
  bool _isLoading = false;
  bool _isBooking = false;

  // ✅ نطاق الوقت المسموح (9 صباحاً - 5 مساءً)
  static const int _minHour = 9;
  static const int _maxHour = 17;

  // ✅ قائمة الأوقات المحجوزة
  List<String> _bookedSlots = [];

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

      for (var doctor in provider.doctors) {
        print('👨‍⚕️ الطبيب: doctor.id=${doctor.id}, user.id=${doctor.user?.id}, Name=${doctor.displayName}');
      }

      // ✅ إذا تم اختيار طبيب وتاريخ، جلب المواعيد المحجوزة
      if (_selectedDoctorUserId != null && _selectedDate != null) {
        await _loadBookedSlots();
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

  // ✅ دالة لجلب المواعيد المحجوزة
  Future<void> _loadBookedSlots() async {
    // ✅ التحقق من mounted قبل استخدام context
    if (!mounted) return;
    
    try {
      final provider = context.read<AppointmentProvider>();
      
      // ✅ جلب مواعيد الطبيب في التاريخ المحدد
      await provider.loadDoctorAppointments(
        _selectedDoctorUserId!,
        date: _selectedDate,
      );

      // ✅ تصفية المواعيد المحجوزة (pending أو confirmed)
      final booked = provider.appointments
          .where((app) => 
              app.status == 'pending' || 
              app.status == 'confirmed')
          .map((app) => app.appointmentTime)
          .toList();

      setState(() {
        _bookedSlots = booked;
      });

      // ✅ إذا كان الوقت المختار محجوزاً، إلغاء اختياره
      if (_selectedTime != null && _bookedSlots.contains(_selectedTime)) {
        setState(() {
          _selectedTime = null;
        });
        
        // ✅ التحقق من mounted قبل استخدام ScaffoldMessenger
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ هذا الوقت محجوز بالفعل، يرجى اختيار وقت آخر'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      print('📋 الأوقات المحجوزة: $_bookedSlots');
      
    } catch (e) {
      print('❌ خطأ في جلب المواعيد المحجوزة: $e');
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
          _selectedTime = null;
          _bookedSlots = [];
        });
        print('📅 التاريخ المختار: $_selectedDate');
        
        // ✅ جلب المواعيد المحجوزة للتاريخ الجديد
        if (_selectedDoctorUserId != null && mounted) {
          await _loadBookedSlots();
        }
      }
    } catch (e) {
      print('❌ خطأ في اختيار التاريخ: $e');
      if (mounted) {
        _showDateTextField();
      }
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
              _selectedTime = null;
              _bookedSlots = [];
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_selectedDate != null && _selectedDoctorUserId != null) {
                setState(() {});
                if (mounted) {
                  await _loadBookedSlots();
                }
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  // ✅ دالة الأوقات المتاحة (مع إزالة المحجوزة)
  List<String> _getAvailableTimeSlots() {
    List<String> slots = [];
    for (int hour = _minHour; hour < _maxHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        // ✅ إزالة الأوقات المحجوزة
        if (!_bookedSlots.contains(time)) {
          slots.add(time);
        }
      }
    }
    return slots;
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

      final selectedDoctor = provider.doctors.firstWhere(
        (d) => d.user?.id == _selectedDoctorUserId,
        orElse: () => provider.doctors.first,
      );

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
        doctorId: doctorIdToSend,
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

    // ✅ قائمة الأوقات المتاحة (مع إزالة المحجوزة)
    final availableSlots = _getAvailableTimeSlots();

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
                  const SizedBox(height: 24),
                  
                  // ✅ التخصص
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
                          _bookedSlots = [];
                          _selectedTime = null;
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // ✅ الطبيب
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
                          value: doctor.user?.id,
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
                          _bookedSlots = [];
                          _selectedTime = null;
                          // ✅ جلب المواعيد المحجوزة عند اختيار طبيب جديد
                          if (_selectedDate != null && mounted) {
                            _loadBookedSlots();
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 16),

                  // ✅ التاريخ
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

                  // ✅ الوقت (مع إزالة المحجوزة)
                  const Text(
                    'اختر الوقت:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('اختر الوقت'),
                        value: _selectedTime,
                        items: availableSlots.map((slot) {
                          return DropdownMenuItem<String>(
                            value: slot,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(slot),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTime = value;
                          });
                          print('🕐 الوقت المختار: $_selectedTime');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ✅ عرض معلومات الوقت المسموح وعدد الأوقات المتاحة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⏰ من ${_minHour.toString().padLeft(2, '0')}:00 إلى ${_maxHour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${availableSlots.length} وقت متاح',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // ✅ عرض الأوقات المحجوزة (Debug)
                  if (_bookedSlots.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '🔴 محجوز: ${_bookedSlots.join(", ")}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[400],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ✅ زر تأكيد الحجز
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

                  // ✅ معلومات Debug
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
                        Text(
                          'الأوقات المتاحة: ${availableSlots.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'الأوقات المحجوزة: ${_bookedSlots.length}',
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