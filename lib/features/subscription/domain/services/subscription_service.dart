// lib/features/subscription/domain/services/subscription_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';
import 'package:seba/features/subscription/data/repositories/subscription_repository.dart';

class SubscriptionService {
  final SubscriptionRepository _repository;
  final FirebaseAuth _auth;

  SubscriptionService({SubscriptionRepository? repository, FirebaseAuth? auth})
    : _repository = repository ?? SubscriptionRepository(),
      _auth = auth ?? FirebaseAuth.instance;

  /// تسجيل حساب جديد والتحقق الكامل من كود الاشتراك
  Future<void> registerUserWithCode({
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    // 1. التحقق من وجود وصلاحية الكود
    final codeModel = await _repository.getSubscriptionCode(code);

    if (codeModel == null) {
      throw Exception('كود الاشتراك غير صحيح');
    }
    if (codeModel.used) {
      throw Exception('هذا الكود مستخدم من قبل');
    }
    if (!codeModel.isValid) {
      throw Exception('منتهي الصلاحية أو غير صالح للاستخدام');
    }

    // 2. إنشاء المستخدم في Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user?.uid;
    if (uid == null) {
      throw Exception('فشل في إنشاء الحساب، يرجى المحاولة لاحقاً');
    }

    // 3. ربط الاشتراك بالحساب وتحديد الكود كمستخدم
    await _repository.registerWithSubscriptionCode(
      uid: uid,
      name: name,
      email: email,
      codeModel: codeModel,
    );
  }

  /// الاستماع لحالة اشتراك المستخدم الحالي
  Stream<SubscriptionModel?> get currentUserSubscriptionStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _repository.streamUserSubscription(uid);
  }
}
