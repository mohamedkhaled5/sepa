import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';
import 'package:seba/features/subscription/domain/services/subscription_service.dart';
import 'package:seba/features/subscription/presentation/screens/redeem_code_screen.dart';

class SubscriptionGuard extends StatelessWidget {
  final Widget child;

  const SubscriptionGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // إذا لم يكن هناك مستخدم مسجل، ارجع الشاشة كما هي (سيتعامل معها AuthGuard)
    if (user == null) return child;

    final subscriptionService = SubscriptionService();

    return StreamBuilder<SubscriptionModel?>(
      stream: subscriptionService.watchSubscription(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final subscription = snapshot.data;
        final isValid = subscriptionService.isSubscriptionValid(subscription);

        // إذا كان الاشتراك فعالاً، عرض الشاشة المطلوبة
        if (isValid) {
          return child;
        }

        // إذا كان الاشتراك منتهياً أو غير موجود، عرض شاشة التنبيه والتجديد
        return const ExpiredSubscriptionScreen();
      },
    );
  }
}

/// شاشة تظهر للمعلم عند انتهاء اشتراكه
class ExpiredSubscriptionScreen extends StatelessWidget {
  const ExpiredSubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                size: 90,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'انتهت فترة الاشتراك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'عذراً، انتهت صلاحية اشتراكك الحالية. يرجى إدخال كود تجديد للاستمرار في استخدام ميزات التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RedeemCodeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.vpn_key_rounded),
                label: const Text('إدخال كود التجديد'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
