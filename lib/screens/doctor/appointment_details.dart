import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';

class AppointmentDetails extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetails({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedStatus = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.appointment.status;
    _notesController.text = widget.appointment.doctorNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ✅ تحديث حالة الموعد
  Future<void> _updateStatus(String status) async {
    if (status == widget.appointment.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ الحالة هي نفسها الحالية'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppointmentProvider>();
      final success = await provider.updateAppointmentStatus(
        widget.appointment.id,
        status,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _selectedStatus = status;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث حالة الموعد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${provider.error ?? "فشل تحديث الحالة"}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ في تحديث الحالة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // ✅ إضافة ملاحظات طبية
  Future<void> _saveNotes() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إدخال الملاحظات الطبية'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppointmentProvider>();
      final success = await provider.addDoctorNotes(
        widget.appointment.id,
        _notesController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _selectedStatus = 'completed';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة الملاحظات الطبية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        // العودة إلى الصفحة السابقة
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${provider.error ?? "فشل إضافة الملاحظات"}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ في إضافة الملاحظات: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;

    // ✅ تحديد لون الحالة
    Color statusColor;
    String statusText;

    switch (appointment.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'مؤكد';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'مكتمل';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'ملغي';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير معروف';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الموعد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ معلومات المريض
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
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
                            appointment.patient?.fullName ?? 'مريض',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'رقم الموعد: #${appointment.id}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ✅ معلومات الموعد
              _buildInfoCard(
                '📅 التاريخ',
                appointment.appointmentDate,
                Icons.date_range,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                '🕐 الوقت',
                appointment.appointmentTime,
                Icons.access_time,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                '📌 الحالة الحالية',
                statusText,
                Icons.info,
                color: statusColor,
              ),
              const SizedBox(height: 20),

              // ✅ تغيير الحالة
              const Text(
                'تغيير حالة الموعد:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusButton('مؤكد', 'confirmed', Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatusButton('مكتمل', 'completed', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatusButton('ملغي', 'cancelled', Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ إضافة ملاحظات طبية
              const Text(
                'الملاحظات الطبية:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'أدخل الملاحظات الطبية هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveNotes,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ الملاحظات'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, Color color) {
    final isSelected = _selectedStatus == status;

    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _updateStatus(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}