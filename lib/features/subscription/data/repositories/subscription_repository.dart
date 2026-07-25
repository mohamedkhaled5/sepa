import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seba/features/subscription/domain/models/subscription_code_model.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// دالة توليد نص عشوائي قوي للأكواد (مثل: SB-9X2K4P)
  String generateRandomCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // بدون حروف متشابهة
    final rand = Random();
    final randomString = List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    return 'SB-$randomString';
  }

  /// إنشاء كود اشتراك جديد في Firestore (خاص بالأدمن)
  Future<void> createSubscriptionCode({
    required String code,
    required int durationDays,
    required String plan,
    required int maxAssistants,
    // 👈 أضف هذه المعلمة
  }) async {
    final cleanCode = code.trim().toUpperCase();

    await _firestore.collection('subscription_codes').doc(cleanCode).set({
      'code': cleanCode,
      'durationDays': durationDays,
      'plan': plan,
      'maxAssistants': maxAssistants, // 👈 حد المساعدين المسموح به
      // 👈 حفظها في الفايربيس
      'used': false,
      'usedAt': null,
      'usedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> redeemSubscriptionCode({
    required String code,
    required String teacherUid,
  }) async {
    final codeDoc = await _firestore
        .collection('subscription_codes')
        .doc(code)
        .get();

    if (!codeDoc.exists) {
      throw Exception('كود الاشتراك غير صحيح');
    }

    final data = codeDoc.data()!;

    // 👈 قراءة سقف الصلاحيات المحددة من الأدمن لهذا الكود

    final int durationDays = data['durationDays'] ?? 30;
    final DateTime newExpiryDate = DateTime.now().add(
      Duration(days: durationDays),
    );

    // 👈 تحديث بيانات المدرس بالـ Firestore مع حفظ سقف الصلاحيات
    await _firestore.collection('users').doc(teacherUid).update({
      'subscriptionCode': code,
      'subscriptionExpiry': Timestamp.fromDate(newExpiryDate),
      'plan': data['plan'] ?? 'Pro',
      'maxAssistants': data['maxAssistants'] ?? 2,
      // 🔥 هذا هو السطر المهم الذي يقوم بنقل الصلاحيات لحساب المدرس
    });

    // تعليم الكود كـ مستخدم
    await _firestore.collection('subscription_codes').doc(code).update({
      'isUsed': true,
      'usedBy': teacherUid,
      'usedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تفعيل الكود وحفظ بيانات الاشتراك والمساعدين المسموح بهم على حساب المدرس عند التسجيل لأول مرة
  /// تفعيل الكود وحفظ بيانات الاشتراك والمساعدين المسموح بهم على حساب المدرس عند التسجيل لأول مرة
  Future<void> registerWithSubscriptionCode({
    required String uid,
    required String name,
    required String email,
    required SubscriptionCodeModel
    codeModel, // 👈 تغيير نوع المعامل هنا ليقبل Model مباشرة
  }) async {
    final int durationDays = codeModel.durationDays;
    final int maxAssistants = codeModel.maxAssistants;
    final String code = codeModel.code;

    final now = DateTime.now();
    final endDate = now.add(Duration(days: durationDays));

    final batch = _firestore.batch();

    // 1. تحديث مستند المدرس بالبيانات وميزة عدد المساعدين
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'uid': uid,
      'name': name,
      'email': email,
      'role': 'teacher',
      'maxAssistants': maxAssistants, // 👈 حفظ الحد الأقصى المباشر في المدرس
      'subscription': {
        'active': true,
        'plan': codeModel.plan,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'maxAssistants': maxAssistants,
      },
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. تعليم الكود كـ مستخدم (used = true)
    // نستخدم id الخاص بالـ model أو الكود مباشرة
    final codeRef = _firestore
        .collection('subscription_codes')
        .doc(codeModel.id.isNotEmpty ? codeModel.id : code);
    batch.update(codeRef, {
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
      'usedBy': uid,
    });

    await batch.commit();
  }

  /// 1. جلب كود الاشتراك والتحقق منه
  Future<SubscriptionCodeModel?> getSubscriptionCode(String code) async {
    final query = await _firestore
        .collection('subscription_codes')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return SubscriptionCodeModel.fromFirestore(query.docs.first);
  }

  /// 3. تفعيل كود جديد لمستخدم مسجل بالفعل (Renewal / Upgrade Flow)
  Future<void> redeemCodeForExistingUser({
    required String uid,
    required SubscriptionCodeModel codeModel,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final codeRef = _firestore
          .collection('subscription_codes')
          .doc(codeModel.id);
      final userRef = _firestore.collection('users').doc(uid);

      final codeSnap = await transaction.get(codeRef);
      if (!codeSnap.exists) throw Exception("كود الاشتراك غير موجود.");
      if (codeSnap.data()?['used'] == true) {
        throw Exception("هذا الكود تم استخدامه بالفعل.");
      }

      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception("المستخدم غير موجود.");

      final now = DateTime.now();

      // 🟢 تعديل: الحساب بالأيام مباشرة
      final int daysToAdd = codeModel.durationDays;

      DateTime startDate = now;
      DateTime endDate = now.add(Duration(days: daysToAdd));

      final userData = userSnap.data();
      if (userData != null && userData['subscription'] != null) {
        final currentSub = SubscriptionModel.fromMap(userData['subscription']);

        if (currentSub.endDate.isAfter(now)) {
          // إضافة الأيام فوق الاشتراك الحالي المتوفر
          endDate = currentSub.endDate.add(Duration(days: daysToAdd));
          startDate = currentSub.startDate;
        }
      }

      final updatedSubscription = SubscriptionModel(
        active: true,
        plan: codeModel.plan,
        startDate: startDate,
        endDate: endDate,
        maxAssistants: codeModel.maxAssistants, // 👈 تحديث عدد المساعدين الجديد
      );

      // تحديث بيانات المدرس بالكامل بالـ maxAssistants الجديد
      transaction.update(userRef, {
        'maxAssistants':
            codeModel.maxAssistants, // 👈 تحديث الحقليْن بالخطة الجديدة
        'subscription': updatedSubscription.toMap(),
      });

      transaction.update(codeRef, {
        'used': true,
        'usedBy': uid,
        'usedAt': Timestamp.fromDate(now),
      });
    });
  }

  /// 4. قراءة بيانات اشتراك المستخدم الحالي بشكل حي (Stream)
  Stream<SubscriptionModel?> streamUserSubscription(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null || data['subscription'] == null) return null;
      return SubscriptionModel.fromMap(data['subscription']);
    });
  }
}
