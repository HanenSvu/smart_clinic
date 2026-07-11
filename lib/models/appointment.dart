import 'package:flutter/material.dart';  // أضف هذا السطر
import 'user.dart';

class Appointment {
  final int id;
  final int patientId;
  final int doctorId;
  final String appointmentDate;
  final String appointmentTime;
  final String status;
  final String? doctorNotes;
  final User? patient;
  final User? doctor;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.doctorNotes,
    this.patient,
    this.doctor,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      appointmentDate: json['appointment_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      status: json['status'] ?? 'pending',
      doctorNotes: json['doctor_notes'],
      patient: json['patient'] != null ? User.fromJson(json['patient']) : null,
      doctor: json['doctor'] != null ? User.fromJson(json['doctor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'status': status,
      'doctor_notes': doctorNotes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  bool get isUpcoming {
    final now = DateTime.now();
    try {
      final date = DateTime.parse(appointmentDate);
      return date.isAfter(now) || date.isAtSameMomentAs(now);
    } catch (e) {
      return false;
    }
  }
}