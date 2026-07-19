import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/auth/login_screen.dart';
import 'package:seba/screens/home/home_page_screen.dart';

/// يراقب حالة تسجيل الدخول باستمرار عبر authStateChanges، وبيبدّل
/// الشاشة تلقائيًا بين Login و Home بدون ما أي شاشة تانية تحتاج
/// تفحص حالة تسجيل الدخول بنفسها.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePageScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
