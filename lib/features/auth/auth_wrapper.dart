// lib/features/auth/auth_wrapper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/assistant/assistant_status_screen.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/auth/login_screen.dart';
import 'package:seba/features/subscription/presentation/guards/subscription_guard.dart';
import 'package:seba/model/user_model.dart';
import 'package:seba/screens/home/home_page_screen.dart';

/// يراقب حالة تسجيل الدخول، وبعدها بيراقب مستند users/{uid} في Firestore
/// بشكل حي (Stream مش Future مرة واحدة). ده يخلي أي تغيير يحصل من المدرس
/// (تعديل صلاحية، قبول، رفض، إزالة مساعد) يوصل للمساعد فورًا من غير ما
/// يحتاج يعمل تسجيل خروج/دخول من جديد.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          AppSession.clear();
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (docSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    "حدث خطأ في تحميل بيانات الحساب: ${docSnapshot.error}",
                  ),
                ),
              );
            }

            // المستند لسه ما اتكتبش (سباق مؤقت وقت التسجيل مباشرة)
            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userModel = UserModel.fromFirestore(docSnapshot.data!);

            // ================== Admin ==================
            if (userModel.role == 'admin') {
              AppSession.setSession(
                effectiveTeacherId: user.uid,
                role: 'admin',
              );

              return const HomePageScreen();
            }

            // ================== Teacher ==================
            if (userModel.role == 'teacher') {
              AppSession.setSession(
                effectiveTeacherId: user.uid,
                role: 'teacher',
              );

              return const SubscriptionGuard(child: HomePageScreen());
            }

            // ================== Assistant ==================
            switch (userModel.status) {
              case 'approved':
                if (userModel.teacherId == null) {
                  return const AssistantStatusScreen(
                    kind: AssistantStatusKind.removed,
                  );
                }

                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userModel.teacherId)
                      .snapshots(),
                  builder: (context, teacherDocSnapshot) {
                    if (teacherDocSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // 🔴 التحقق من وجود المدرس وصلاحية اشتراكه
                    if (!teacherDocSnapshot.hasData ||
                        !teacherDocSnapshot.data!.exists ||
                        !AppSession.isTeacherSubscriptionValid(
                          teacherDocSnapshot.data!.data(),
                        )) {
                      // إذا كان اشتراك المدرس منتهياً أو حسابه غير موجود يتم تحويله لشاشة الحالة
                      return const AssistantStatusScreen(
                        kind: AssistantStatusKind.removed,
                      );
                    }

                    // 🟢 المدرس اشتراكه ساري -> ضبط الجلسة وتوجيه المساعد
                    AppSession.setSession(
                      effectiveTeacherId: userModel.teacherId!,
                      role: 'assistant',
                      permissions: userModel.permissions,
                    );

                    return const HomePageScreen();
                  },
                );

              case 'pending':
                return const AssistantStatusScreen(
                  kind: AssistantStatusKind.pending,
                );

              case 'rejected':
                return const AssistantStatusScreen(
                  kind: AssistantStatusKind.rejected,
                );

              default:
                // status == null أو 'removed'
                return const AssistantStatusScreen(
                  kind: AssistantStatusKind.removed,
                );
            }
          },
        );
      },
    );
  }
}
