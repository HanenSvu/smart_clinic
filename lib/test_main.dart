import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('اختبار التطبيق'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            '✅ التطبيق يعمل!',
            style: TextStyle(fontSize: 32, color: Colors.green),
          ),
        ),
      ),
    );
  }
}