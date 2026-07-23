// lib/features/subscription/data/repositories/subscription_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seba/features/subscription/domain/models/subscription_code_model.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 1. جلب كود الاشتراك والتحقق منه
  Future<SubscriptionCodeModel?> getSubscriptionCode(String code) async {
    final query = await _firestore
        .collection('subscription_codes')
        .where('code', isEqualTo: code.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return SubscriptionCodeModel.fromFirestore(query.docs.first);
  }

  /// 2. تفعيل الكود أثناء إنشاء حساب جديد (Registration Flow)
  Future<void> registerWithSubscriptionCode({
    required String uid,
    required String name,
    required String email,
    required SubscriptionCodeModel codeModel,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final codeRef = _firestore
          .collection('subscription_codes')
          .doc(codeModel.id);
      final userRef = _firestore.collection('users').doc(uid);

      final codeSnap = await transaction.get(codeRef);
      if (!codeSnap.exists) throw Exception("كود الاشتراك غير موجود.");

      final isUsed = codeSnap.data()?['used'] ?? false;
      if (isUsed) throw Exception("هذا الكود تم استخدامه بالفعل.");

      final now = DateTime.now();

      // 🟢 تعديل: الحساب بالثواني مع تحويل القيمة لـ int بأمان
      final endDate = now.add(
        Duration(seconds: codeModel.durationDays.toInt()),
      );

      final subscription = SubscriptionModel(
        active: true,
        plan: codeModel.plan,
        startDate: now,
        endDate: endDate,
      );

      transaction.set(userRef, {
        'name': name,
        'email': email,
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'subscription': subscription.toMap(),
      });

      transaction.update(codeRef, {
        'used': true,
        'usedBy': uid,
        'usedAt': Timestamp.fromDate(now),
      });
    });
  }

  /// 3. تفعيل كود جديد لمستخدم مسجل بالفعل (Renewal Flow)
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
      if (codeSnap.data()?['used'] == true)
        throw Exception("هذا الكود تم استخدامه بالفعل.");

      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) throw Exception("المستخدم غير موجود.");

      final now = DateTime.now();

      // 🟢 تعديل: الحساب بالثواني
      final int secondsToAdd = codeModel.durationDays.toInt();

      DateTime startDate = now;
      DateTime endDate = now.add(Duration(seconds: secondsToAdd));

      final userData = userSnap.data();
      if (userData != null && userData['subscription'] != null) {
        final currentSub = SubscriptionModel.fromMap(userData['subscription']);

        if (currentSub.endDate.isAfter(now)) {
          // 🟢 إضافة الثواني فوق الاشتراك الحالي
          endDate = currentSub.endDate.add(Duration(seconds: secondsToAdd));
          startDate = currentSub.startDate;
        }
      }

      final updatedSubscription = SubscriptionModel(
        active: true,
        plan: codeModel.plan,
        startDate: startDate,
        endDate: endDate,
      );

      transaction.update(userRef, {
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
