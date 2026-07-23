// lib/features/subscription/domain/models/subscription_code_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionCodeModel {
  final String id;
  final String code;
  final String plan;
  final int durationDays;
  final bool used;
  final String? usedBy;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  SubscriptionCodeModel({
    required this.id,
    required this.code,
    required this.plan,
    required this.durationDays,
    required this.used,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
    this.expiresAt,
  });

  /// فحص صلاحية الكود قبل الاستخدام
  bool get isValid {
    if (used) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  factory SubscriptionCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      plan: data['plan'] ?? 'pro',
      durationDays: data['durationDays'] ?? 30,
      used: data['used'] ?? false,
      usedBy: data['usedBy'],
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}
