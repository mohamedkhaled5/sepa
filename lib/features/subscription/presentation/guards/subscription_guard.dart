import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/auth/login_screen.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';
import 'package:seba/features/subscription/domain/services/subscription_service.dart';
import 'package:seba/features/subscription/presentation/screens/redeem_code_screen.dart';

/// يحرس الوصول لكل شاشات التطبيق، بالاعتماد دايمًا على اشتراك
/// *المدرس* - مش المستخدم الحالي بذاته. للمدرس ده نفس حسابه هو،
/// وللمساعد ده حساب المدرس التابع له (AppSession.effectiveTeacherId)،
/// لأن المساعد مالوش اشتراك مستقل خالص - هو بيرث حالة اشتراك مدرسه
/// زي ما بيرث كل بياناته بالظبط.
///
/// ⚠️ لازم يتحط في شجرة الودجات *بعد* ما AuthWrapper يحدد الدور
/// وينادي AppSession.setSession(...) - قبل كده effectiveTeacherId
/// هيرمي StateError، فبنتحقق من isSessionLoaded الأول احتياطيًا.
class SubscriptionGuard extends StatelessWidget {
  final Widget child;

  const SubscriptionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // الأدمن مالوش اشتراك من الأساس (هو المسؤول عن إدارة الأكواد
    // نفسها)، فمايتقفلش أبدًا بفحص الاشتراك.
    if (AppSession.isAdmin) return child;

    if (!AppSession.isSessionLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subscriptionService = SubscriptionService();
    final teacherId = AppSession.effectiveTeacherId;

    return StreamBuilder<SubscriptionModel?>(
      stream: subscriptionService.watchSubscription(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final subscription = snapshot.data;
        final isValid = subscriptionService.isSubscriptionValid(subscription);

        if (isValid) return child;

        return ExpiredSubscriptionScreen(canRenew: AppSession.isTeacher);
      },
    );
  }
}

/// شاشة تظهر عند انتهاء اشتراك المدرس (أو المدرس المرتبط بالمساعد).
/// المدرس بس هو اللي يقدر يجدد بكود من هنا - لو المساعد أدخل كود من
/// حسابه هو، الكود هيتفعّل على حساب المساعد نفسه مش حساب مدرسه، وده
/// غلط تمامًا، فبنمنع ظهور حقل الكود له خالص ونوريه رسالة توضيحية بس.
class ExpiredSubscriptionScreen extends StatelessWidget {
  final bool canRenew;

  const ExpiredSubscriptionScreen({super.key, this.canRenew = true});

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
              Text(
                canRenew
                    ? 'عذراً، انتهت صلاحية اشتراكك الحالية. يرجى إدخال '
                          'كود تجديد للاستمرار في استخدام ميزات التطبيق.'
                    : 'عذراً، انتهت صلاحية اشتراك المدرس المرتبط بحسابك. '
                          'يرجى التواصل معه لتجديد الاشتراك.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (canRenew)
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService().logout();
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => const LoginScreen(),
                  //   ),
                  // );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  ' تسجيل الخروج من الحساب ',
                  style: TextStyle(color: Colors.red),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red),
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
