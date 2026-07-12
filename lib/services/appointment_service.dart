import '../models/appointment.dart';
import '../models/user.dart';
import '../models/specialty.dart';
import 'api_client.dart';

class AppointmentService {
  final ApiClient apiClient = ApiClient();

  // ✅ جلب الأطباء
  Future<List<Doctor>> getDoctors({int? specialtyId}) async {
    print('========================================');
    print('📡 جلب الأطباء من API');
    
    try {
      String endpoint = '/doctors';
      if (specialtyId != null) {
        endpoint += '?specialty_id=$specialtyId';
      }
      
      print('🌐 الاتصال بـ: $endpoint');
      
      final response = await apiClient.get(endpoint);
      
      print('📨 Status Code: ${response.statusCode}');
      print('📨 Response Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        List<Doctor> doctors = [];
        
        if (response.data is List) {
          print('✅ البيانات هي List مباشرة');
          final List list = response.data;
          
          for (var item in list) {
            print('📋 معالجة طبيب: ${item['user']?['full_name'] ?? 'Unknown'}');
            try {
              final doctor = Doctor.fromJson(item);
              doctors.add(doctor);
              print('   ✅ تم إضافة: ${doctor.displayName}');
            } catch (e) {
              print('   ❌ خطأ في تحويل طبيب: $e');
            }
          }
        } 
        else if (response.data is Map && response.data.containsKey('data')) {
          print('✅ البيانات في المفتاح "data"');
          final List list = response.data['data'] ?? [];
          for (var item in list) {
            try {
              doctors.add(Doctor.fromJson(item));
            } catch (e) {
              print('❌ خطأ في تحويل طبيب: $e');
            }
          }
        }
        
        print('✅ تم جلب ${doctors.length} طبيب');
        
        for (var doctor in doctors) {
          print('   👨‍⚕️ ${doctor.displayName} - ${doctor.displaySpecialty} (${doctor.consultationFee} ₪)');
        }
        
        print('========================================');
        return doctors;
      }
      
      print('❌ فشل جلب الأطباء: ${response.statusCode}');
      print('========================================');
      return [];
      
    } catch (e) {
      print('❌ خطأ في جلب الأطباء: $e');
      print('========================================');
      return [];
    }
  }

  // ✅ جلب التخصصات
  Future<List<Specialty>> getSpecialties() async {
    print('========================================');
    print('📡 جلب التخصصات من API');
    
    try {
      final response = await apiClient.get('/specialties');
      print('📨 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List data = [];
        
        if (response.data is Map<String, dynamic>) {
          if (response.data.containsKey('data')) {
            data = response.data['data'];
          } else if (response.data.containsKey('specialties')) {
            data = response.data['specialties'];
          }
        } else if (response.data is List) {
          data = response.data;
        }
        
        print('✅ تم جلب ${data.length} تخصص');
        print('📋 التخصصات: ${data.map((s) => s['name']).toList()}');
        print('========================================');
        return data.map((json) => Specialty.fromJson(json)).toList();
      }
      print('❌ فشل جلب التخصصات: ${response.statusCode}');
      print('========================================');
      return [];
    } catch (e) {
      print('❌ خطأ في جلب التخصصات: $e');
      print('========================================');
      return [];
    }
  }

  // ✅ جلب مواعيد المريض
  Future<List<Appointment>> getPatientAppointments() async {
    print('📡 جلب مواعيد المريض');
    
    try {
      final response = await apiClient.get('/my-appointments');
      
      if (response.statusCode == 200) {
        final List appointments = response.data['data']['all'] ?? [];
        print('✅ تم جلب ${appointments.length} موعد');
        return appointments.map((json) => Appointment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ خطأ في جلب مواعيد المريض: $e');
      return [];
    }
  }

  // ✅ جلب مواعيد الطبيب
  Future<List<Appointment>> getDoctorAppointments(int doctorId, {String? date}) async {
    print('📡 جلب مواعيد الطبيب');
    
    try {
      String endpoint = '/doctor/appointments/$doctorId';
      if (date != null) {
        endpoint += '?date=$date';
      }
      
      final response = await apiClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final List data = response.data['data']['appointments'] ?? [];
        print('✅ تم جلب ${data.length} موعد للطبيب');
        return data.map((json) => Appointment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ خطأ في جلب مواعيد الطبيب: $e');
      return [];
    }
  }

  // ✅ حجز موعد جديد (تم الإصلاح)
  Future<Map<String, dynamic>> bookAppointment({
    required int doctorId,
    required String date,
    required String time,
  }) async {
    print('========================================');
    print('📡 حجز موعد جديد');
    print('📋 doctorId: $doctorId (نوع: ${doctorId.runtimeType})');
    print('📋 date: $date');
    print('📋 time: $time');
    print('========================================');
    
    try {
      // ✅ التحقق من صحة البيانات
      if (doctorId <= 0) {
        return {
          'success': false,
          'message': 'معرف الطبيب غير صحيح',
        };
      }
      
      if (date.isEmpty || time.isEmpty) {
        return {
          'success': false,
          'message': 'التاريخ والوقت مطلوبان',
        };
      }
      
      // ✅ تحضير البيانات
      final Map<String, dynamic> data = {
        'doctor_id': doctorId,
        'appointment_date': date,
        'appointment_time': time,
      };
      
      print('📦 البيانات المرسلة: $data');
      
      final response = await apiClient.post('/appointments/book', data: data);
      
      print('📨 Status Code: ${response.statusCode}');
      print('📨 Response: ${response.data}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم حجز الموعد بنجاح',
          'appointment': response.data['appointment'] != null 
              ? Appointment.fromJson(response.data['appointment']) 
              : null,
        };
      } else {
        // ✅ عرض رسالة الخطأ من السيرفر
        final errorMessage = response.data['message'] ?? response.data['error'] ?? 'فشل حجز الموعد';
        print('❌ فشل حجز الموعد: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('❌ خطأ في حجز الموعد: $e');
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }

  // ✅ إلغاء موعد
  Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    print('📡 إلغاء الموعد: $appointmentId');
    
    try {
      final response = await apiClient.delete('/appointments/$appointmentId/cancel');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'فشل إلغاء الموعد',
        };
      }
    } catch (e) {
      print('❌ خطأ في إلغاء الموعد: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ✅ تحديث حالة الموعد
  Future<Map<String, dynamic>> updateAppointmentStatus(
    int appointmentId,
    String status,
  ) async {
    print('📡 تحديث حالة الموعد: $appointmentId -> $status');
    
    try {
      final response = await apiClient.put(
        '/appointments/$appointmentId/status',
        data: {'status': status},
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'فشل تحديث الحالة',
        };
      }
    } catch (e) {
      print('❌ خطأ في تحديث الحالة: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ✅ إضافة ملاحظات طبية
  Future<Map<String, dynamic>> addDoctorNotes(int appointmentId, String notes) async {
    print('📡 إضافة ملاحظات طبية للموعد: $appointmentId');
    
    try {
      final response = await apiClient.post(
        '/appointments/$appointmentId/notes',
        data: {'doctor_notes': notes},
      );
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'فشل إضافة الملاحظات',
        };
      }
    } catch (e) {
      print('❌ خطأ في إضافة الملاحظات: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}