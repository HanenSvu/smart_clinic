// حذف import غير المستخدم
// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_clinic_frontend/main.dart';

void main() {
  testWidgets('Smart Clinic app starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartClinicApp());

    // Verify that the login screen is shown
    expect(find.text('Smart Clinic'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}