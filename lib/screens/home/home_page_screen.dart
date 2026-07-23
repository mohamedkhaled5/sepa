import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';
import 'package:seba/features/subscription/presentation/screens/subscription_expired_screen.dart';
import 'package:seba/screens/home/group_screens/groups_display_screen.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  Timer? _subscriptionTimer;

  @override
  void initState() {
    super.initState();
    _startSubscriptionCheck();
  }

  void _startSubscriptionCheck() {
    // يفحص حالة الاشتراك كل 5 ثواني
    _subscriptionTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          if (data.containsKey('subscription') &&
              data['subscription'] != null) {
            final subModel = SubscriptionModel.fromMap(
              Map<String, dynamic>.from(data['subscription']),
            );

            // 🔴 الفحص: إذا انتهت مدة الاشتراك أو أصبح active = false
            if (!subModel.isValid) {
              timer.cancel(); // إيقاف المؤقت

              if (mounted) {
                // توجيه المدرس لشاشة التجديد وتفريغ الـ Stack لمنعه من الرجوع
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SubscriptionExpiredScreen(), // 👈 ضع شاشة التجديد هنا
                  ),
                  (route) => false,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error checking subscription: $e");
      }
    });
  }

  @override
  void dispose() {
    // ⚠️ مهم جداً إلغاء الـ Timer عند الخروج من الصفحة
    _subscriptionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const GroupsDisplayScreen();
  }
}
// import 'package:flutter/material.dart';
// import 'package:seba/screens/home/group_screens/groups_display_screen.dart';

// /// الصفحة الرئيسية للتطبيق. لا تحتوي على Scaffold خاص بها لتفادي ظهور
// /// AppBar مزدوج، لأن GroupsDisplayScreen تحتها لها Scaffold وAppBar
// /// وأزرار (FAB) خاصة بها بالفعل، بما فيها زرار "إضافة طالب" العام.
// class HomePageScreen extends StatelessWidget {
//   const HomePageScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const GroupsDisplayScreen();
//   }
// }
