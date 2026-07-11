import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ أضف هذا
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    print('❌ Flutter Error: ${details.exception}');
    print('📚 Stack: ${details.stack}');
  };

  runApp(const SmartClinicApp());
}

class SmartClinicApp extends StatelessWidget {
  const SmartClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Clinic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        locale: const Locale('ar', 'SY'),
        supportedLocales: const [
          Locale('ar', 'SY'),
          Locale('en', 'US'),
        ],
        // ✅ الطريقة الصحيحة لإضافة localizationsDelegates
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/patient-dashboard': (context) => const PatientDashboard(),
          '/doctor-dashboard': (context) => const DoctorDashboard(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<AuthProvider>().checkAuthStatus();
      } catch (e) {
        print('❌ خطأ في AuthWrapper: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('جاري التحميل...'),
                  ],
                ),
              ),
            );
          }

          if (auth.isAuthenticated && auth.user != null) {
            if (auth.user!.role == 'doctor') {
              return const DoctorDashboard();
            } else {
              return const PatientDashboard();
            }
          }

          return const LoginScreen();
        },
      );
    } catch (e) {
      print('❌ خطأ في build: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text('حدث خطأ: $e'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  runApp(const SmartClinicApp());
                },
                child: const Text('إعادة تحميل'),
              ),
            ],
          ),
        ),
      );
    }
  }
}