import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/user.dart';
import 'book_appointment.dart';
import 'my_appointments.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    print('🔄 جاري تحميل قائمة الأطباء...');
    
    try {
      if (!mounted) return;
      
      final appointmentProvider = context.read<AppointmentProvider>();
      await appointmentProvider.loadDoctors();
      
      if (mounted) {
        print('✅ تم تحميل ${appointmentProvider.doctors.length} طبيب');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print('❌ خطأ في تحميل الأطباء: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToBookAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BookAppointment(),
      ),
    ).then((_) {
      if (mounted) {
        _loadDoctors();
      }
    });
  }

  void _navigateToMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyAppointments(),
      ),
    );
  }

  void _navigateToBookWithDoctor(Doctor doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookAppointment(
          doctorId: doctor.id,
          doctorName: doctor.displayName,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadDoctors();
      }
    });
  }

  Future<void> _handleLogout(AuthProvider auth) async {
    await auth.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المريض'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(auth),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToBookAppointment,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'حجز موعد جديد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToMyAppointments,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  'مواعيدي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الأطباء المتاحون:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (appointmentProvider.isLoading || _isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل الأطباء...'),
                    ],
                  ),
                ),
              )
            else if (appointmentProvider.doctors.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد أطباء متاحون حالياً',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: appointmentProvider.doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = appointmentProvider.doctors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          doctor.displaySpecialty,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${doctor.consultationFee} ₪',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _navigateToBookWithDoctor(doctor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'حجز',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}