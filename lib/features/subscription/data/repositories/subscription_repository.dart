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
    return 'SAPEEL-$randomString';
  }

  /// إنشاء كود اشتراك جديد في Firestore (خاص بالأدمن)
  Future<void> createSubscriptionCode({
    required String code,
    required int durationDays,
    required String plan,
    required int maxAssistants,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    await _firestore.collection('subscription_codes').doc(cleanCode).set({
      'code': cleanCode,
      'durationDays': durationDays,
      'plan': plan,
      'maxAssistants': maxAssistants,
      'used': false,
      'usedAt': null,
      'usedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// تفعيل الكود وحفظ بيانات الاشتراك والمساعدين المسموح بهم على حساب
  /// المدرس عند التسجيل لأول مرة.
  ///
  /// ⚠️ لازم تبقى Transaction وليس batch: الـ batch بيكتب من غير أي
  /// فحص شرطي وقت الكتابة، فلو اتنين مستخدمين حاولوا يسجّلوا بنفس
  /// الكود في نفس اللحظة، الاتنين كانوا هينجحوا ويتفعّلهم اشتراك كامل
  /// رغم إن الكود المفروض يتستخدم مرة واحدة بس. الـ Transaction بتقرا
  /// حالة الكود *جوه* نفس العملية اللي بتكتب بيها، وFirestore بيرفض/
  /// يعيد أي Transaction بيتعارض مع واحدة تانية خلصت قبله (Optimistic
  /// Concurrency)، فمستخدم واحد بس هو اللي ينجح مهما كان التوقيت متقارب.
  Future<void> registerWithSubscriptionCode({
    required String uid,
    required String name,
    required String email,
    required SubscriptionCodeModel codeModel,
  }) async {
    final codeRef = _firestore
        .collection('subscription_codes')
        .doc(codeModel.id.isNotEmpty ? codeModel.id : codeModel.code);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      // نعيد قراءة الكود من جوه الـ Transaction نفسها - ده أساس الحماية
      // من التكرار، مش مجرد فحص قبلي منفصل زي ما كان في النسخة القديمة.
      final codeSnap = await transaction.get(codeRef);

      if (!codeSnap.exists) {
        throw Exception('كود الاشتراك غير موجود');
      }

      final codeData = codeSnap.data()!;

      if (codeData['used'] == true) {
        throw Exception(
          'عذراً، هذا الكود تم استخدامه بالفعل من قِبل مستخدم آخر',
        );
      }

      final int durationDays = (codeData['durationDays'] as num?)?.toInt() ?? 0;
      if (durationDays <= 0) {
        throw Exception('مدة الاشتراك الخاصة بهذا الكود غير صالحة');
      }

      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));
      final plan = codeData['plan'] as String? ?? codeModel.plan;
      final maxAssistants =
          (codeData['maxAssistants'] as num?)?.toInt() ??
          codeModel.maxAssistants;

      transaction.set(userRef, {
        'uid': uid,
        'name': name,
        'email': email,
        'role': 'teacher',
        'maxAssistants': maxAssistants,
        'subscription': {
          'active': true,
          'plan': plan,
          'startDate': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(endDate),
          'maxAssistants': maxAssistants,
        },
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.update(codeRef, {
        'used': true,
        'usedAt': FieldValue.serverTimestamp(),
        'usedBy': uid,
      });
    });
  }

  /// جلب كود الاشتراك والتحقق منه
  Future<SubscriptionCodeModel?> getSubscriptionCode(String code) async {
    final query = await _firestore
        .collection('subscription_codes')
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return SubscriptionCodeModel.fromFirestore(query.docs.first);
  }

  /// تفعيل كود جديد لمستخدم مسجل بالفعل (Renewal / Upgrade Flow)
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
      final int daysToAdd = codeModel.durationDays;

      DateTime startDate = now;
      DateTime endDate = now.add(Duration(days: daysToAdd));

      final userData = userSnap.data();
      if (userData != null && userData['subscription'] != null) {
        final currentSub = SubscriptionModel.fromMap(userData['subscription']);

        if (currentSub.endDate.isAfter(now)) {
          endDate = currentSub.endDate.add(Duration(days: daysToAdd));
          startDate = currentSub.startDate;
        }
      }

      final updatedSubscription = SubscriptionModel(
        active: true,
        plan: codeModel.plan,
        startDate: startDate,
        endDate: endDate,
        maxAssistants: codeModel.maxAssistants,
      );

      transaction.update(userRef, {
        'maxAssistants': codeModel.maxAssistants,
        'subscription': updatedSubscription.toMap(),
      });

      transaction.update(codeRef, {
        'used': true,
        'usedBy': uid,
        'usedAt': Timestamp.fromDate(now),
      });
    });
  }

  /// قراءة بيانات اشتراك المستخدم الحالي بشكل حي (Stream)
  Stream<SubscriptionModel?> streamUserSubscription(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null || data['subscription'] == null) return null;
      return SubscriptionModel.fromMap(data['subscription']);
    });
  }
}
