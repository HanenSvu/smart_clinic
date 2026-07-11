import 'specialty.dart';

class User {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final Doctor? doctor;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.doctor,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
    };
  }
}

class Doctor {
  final int id;
  final int? specialtyId;
  final double consultationFee;
  final Specialty? specialty;
  final User? user;

  Doctor({
    required this.id,
    this.specialtyId,
    required this.consultationFee,
    this.specialty,
    this.user,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    double fee = 0.0;
    if (json['consultation_fee'] != null) {
      if (json['consultation_fee'] is String) {
        fee = double.tryParse(json['consultation_fee']) ?? 0.0;
      } else if (json['consultation_fee'] is num) {
        fee = (json['consultation_fee'] as num).toDouble();
      }
    }

    return Doctor(
      id: json['id'] ?? 0,
      specialtyId: json['specialty_id'] ?? json['specialtyId'],
      consultationFee: fee,
      specialty: json['specialty'] != null 
          ? Specialty.fromJson(json['specialty']) 
          : null,
      user: json['user'] != null 
          ? User.fromJson(json['user']) 
          : null,
    );
  }

  String get displayName => user?.fullName ?? 'طبيب غير معروف';
  String get displaySpecialty => specialty?.name ?? 'تخصص غير محدد';
}