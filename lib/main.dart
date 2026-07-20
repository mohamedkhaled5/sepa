import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:seba/firebase_options.dart';
import 'package:seba/features/auth/auth_wrapper.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  theme:
  ThemeData(
    colorSchemeSeed: Colors.green,
    useMaterial3: true,
    fontFamily: 'cairo',
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ar');
  runApp(const SebaApp());
}

class SebaApp extends StatelessWidget {
  const SebaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seba',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),

      // AuthWrapper هي المسؤولة عن تحديد أول شاشة يشوفها المستخدم:
      // Login لو مش مسجل دخول، أو Home لو مسجل بالفعل.
      home: const AuthWrapper(),
    );
  }
}
