// lib/features/subscription/presentation/guards/subscription_guard.dart
import 'package:flutter/material.dart';
import 'package:seba/features/subscription/presentation/screens/subscription_expired_screen.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/services/subscription_service.dart';

class SubscriptionGuard extends StatelessWidget {
  final Widget child;
  final SubscriptionService _subscriptionService = SubscriptionService();

  SubscriptionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel?>(
      stream: _subscriptionService.currentUserSubscriptionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final subscription = snapshot.data;

        // إذا لم توجد بيانات اشتراك أو كان الاشتراك منتهياً زمنياً
        if (subscription == null || subscription.isExpired) {
          return SubscriptionExpiredScreen(endDate: subscription?.endDate);
        }

        // الاشتراك فعال -> الانتقال للتطبيق
        return child;
      },
    );
  }
}
