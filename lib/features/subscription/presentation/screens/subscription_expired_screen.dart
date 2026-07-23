// lib/features/subscription/presentation/screens/subscription_expired_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  final DateTime? endDate;

  const SubscriptionExpiredScreen({super.key, this.endDate});

  @override
  Widget build(BuildContext context) {
    final formattedDate = endDate != null
        ? DateFormat('yyyy-MM-dd').format(endDate!)
        : 'غير محدد';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_off_outlined, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'عذراً، انتهت فترة الاشتراك',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'انتهت صلاحية حسابك بتاريخ $formattedDate. يرجى التواصل مع الإدارة لتجديد الاشتراك.',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
