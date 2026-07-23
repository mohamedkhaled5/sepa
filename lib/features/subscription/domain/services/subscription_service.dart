// lib/features/subscription/domain/services/subscription_service.dart
import 'package:seba/features/subscription/data/repositories/subscription_repository.dart';
import 'package:seba/features/subscription/domain/models/subscription_model.dart';

class SubscriptionService {
  final SubscriptionRepository _repository;

  SubscriptionService({SubscriptionRepository? repository})
    : _repository = repository ?? SubscriptionRepository();

  /// فحص وتفعيل كود لمدرس مسجل حالياً داخل التطبيق
  Future<void> redeemCode({
    required String uid,
    required String inputCode,
  }) async {
    final cleanCode = inputCode.trim();
    if (cleanCode.isEmpty) {
      throw Exception('يرجى إدخال كود التفعيل.');
    }

    // 1. البحث عن الكود في قاعدة البيانات
    final codeModel = await _repository.getSubscriptionCode(cleanCode);

    if (codeModel == null) {
      throw Exception(
        'كود التفعيل غير صحيح، يرجى التأكد من الكود وإعادة المحاولة.',
      );
    }

    if (codeModel.used) {
      throw Exception('عذراً، هذا الكود تم استخدامه من قبل.');
    }

    // 2. تطبيق الكود وتمديد/تفعيل الاشتراك
    await _repository.redeemCodeForExistingUser(uid: uid, codeModel: codeModel);
  }

  /// متابعة حالة اشتراك المستخدم
  Stream<SubscriptionModel?> watchSubscription(String uid) {
    return _repository.streamUserSubscription(uid);
  }

  /// التحقق السريع من صلاحية الاشتراك
  bool isSubscriptionValid(SubscriptionModel? subscription) {
    if (subscription == null) return false;
    return subscription.active && subscription.endDate.isAfter(DateTime.now());
  }
}
