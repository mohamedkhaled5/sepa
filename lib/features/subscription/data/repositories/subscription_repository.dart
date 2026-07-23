// lib/features/subscription/data/repositories/subscription_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seba/features/subscription/domain/models/subscription_code_model.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// جلب كود الاشتراك والتحقق منه
  Future<SubscriptionCodeModel?> getSubscriptionCode(String code) async {
    final query = await _firestore
        .collection('subscription_codes')
        .where('code', isEqualTo: code.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return SubscriptionCodeModel.fromFirestore(query.docs.first);
  }

  /// تنفيذ عملية تفعيل كود الاشتراك وإنشاء الحساب في Transaction مع المدرس/المستخدم
  Future<void> registerWithSubscriptionCode({
    required String uid,
    required String name,
    required String email,
    required SubscriptionCodeModel codeModel,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final codeRef = _firestore
        .collection('subscription_codes')
        .doc(codeModel.id);

    final now = DateTime.now();
    final endDate = now.add(Duration(days: codeModel.durationDays));

    final subscription = SubscriptionModel(
      active: true,
      plan: codeModel.plan,
      startDate: now,
      endDate: endDate,
    );

    // استخدام WriteBatch لضمان معالجة متكاملة (Atomic)
    final batch = _firestore.batch();

    // 1. إنشاء وثيقة المستخدم مع الاشتراك
    batch.set(userRef, {
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'subscription': subscription.toMap(),
    });

    // 2. تحديث الكود ليصبح مستخدماً
    batch.update(codeRef, {
      'used': true,
      'usedBy': uid,
      'usedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
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
