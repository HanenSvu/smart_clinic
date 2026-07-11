import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/user.dart';
import '../models/specialty.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();
  
  List<Doctor> _doctors = [];
  List<Appointment> _appointments = [];
  List<Specialty> _specialties = [];
  bool _isLoading = false;
  String? _error;

  // ✅ Getters
  List<Doctor> get doctors => _doctors;
  List<Appointment> get appointments => _appointments;
  List<Specialty> get specialties => _specialties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ Getters للمواعيد المقسمة
  List<Appointment> get upcomingAppointments {
    final now = DateTime.now();
    return _appointments.where((app) {
      final appDate = DateTime.parse(app.appointmentDate);
      return (appDate.isAfter(now) || appDate.isAtSameMomentAs(now)) &&
             app.status != 'cancelled' && 
             app.status != 'completed';
    }).toList();
  }

  List<Appointment> get pastAppointments {
    final now = DateTime.now();
    return _appointments.where((app) {
      final appDate = DateTime.parse(app.appointmentDate);
      return appDate.isBefore(now) || 
             app.status == 'cancelled' || 
             app.status == 'completed';
    }).toList();
  }

  // ✅ تحميل الأطباء
  Future<void> loadDoctors({int? specialtyId}) async {
    print('🔍 AppointmentProvider: بدء تحميل الأطباء');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctors = await _appointmentService.getDoctors(specialtyId: specialtyId);
      print('✅ تم تحميل ${_doctors.length} طبيب');
      
      for (var doctor in _doctors) {
        print('   👨‍⚕️ ${doctor.displayName} - ${doctor.displaySpecialty}');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في تحميل الأطباء: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ تحميل التخصصات
  Future<void> loadSpecialties() async {
    print('🔍 AppointmentProvider: بدء تحميل التخصصات');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _specialties = await _appointmentService.getSpecialties();
      print('✅ تم تحميل ${_specialties.length} تخصص');
      print('📋 التخصصات: ${_specialties.map((s) => s.name).toList()}');
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في تحميل التخصصات: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ تحميل مواعيد المريض
  Future<void> loadPatientAppointments() async {
    print('🔍 AppointmentProvider: بدء تحميل مواعيد المريض');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _appointmentService.getPatientAppointments();
      print('✅ تم تحميل ${_appointments.length} موعد');
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في تحميل مواعيد المريض: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ تحميل مواعيد الطبيب
  Future<void> loadDoctorAppointments(int doctorId, {String? date}) async {
    print('🔍 AppointmentProvider: بدء تحميل مواعيد الطبيب');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _appointmentService.getDoctorAppointments(doctorId, date: date);
      print('✅ تم تحميل ${_appointments.length} موعد للطبيب');
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في تحميل مواعيد الطبيب: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ حجز موعد جديد (تم الإصلاح)
  Future<bool> bookAppointment({
    required int doctorId,
    required String date,
    required String time,
  }) async {
    print('🔍 AppointmentProvider: بدء حجز موعد');
    print('📋 doctorId: $doctorId, date: $date, time: $time');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _appointmentService.bookAppointment(
        doctorId: doctorId,
        date: date,
        time: time,
      );
      
      if (result['success']) {
        print('✅ تم حجز الموعد بنجاح');
        await loadPatientAppointments();
        return true;
      } else {
        _error = result['message'];
        print('❌ فشل حجز الموعد: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في حجز الموعد: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ إلغاء موعد
  Future<bool> cancelAppointment(int appointmentId) async {
    print('🔍 AppointmentProvider: بدء إلغاء الموعد: $appointmentId');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _appointmentService.cancelAppointment(appointmentId);
      
      if (result['success']) {
        print('✅ تم إلغاء الموعد بنجاح');
        await loadPatientAppointments();
        return true;
      } else {
        _error = result['message'];
        print('❌ فشل إلغاء الموعد: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في إلغاء الموعد: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ تحديث حالة الموعد
  Future<bool> updateAppointmentStatus(int appointmentId, String status) async {
    print('🔍 AppointmentProvider: تحديث حالة الموعد: $appointmentId -> $status');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _appointmentService.updateAppointmentStatus(
        appointmentId,
        status,
      );
      
      if (result['success']) {
        print('✅ تم تحديث الحالة بنجاح');
        return true;
      } else {
        _error = result['message'];
        print('❌ فشل تحديث الحالة: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في تحديث الحالة: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ إضافة ملاحظات طبية
  Future<bool> addDoctorNotes(int appointmentId, String notes) async {
    print('🔍 AppointmentProvider: إضافة ملاحظات طبية للموعد: $appointmentId');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _appointmentService.addDoctorNotes(appointmentId, notes);
      
      if (result['success']) {
        print('✅ تم إضافة الملاحظات بنجاح');
        return true;
      } else {
        _error = result['message'];
        print('❌ فشل إضافة الملاحظات: $_error');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ خطأ في إضافة الملاحظات: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}