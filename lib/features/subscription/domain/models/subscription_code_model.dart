import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionCodeModel {
  final String id;
  final String code;
  final int durationDays;
  final String plan;
  final bool used;
  final String? usedBy;
  final DateTime? usedAt;

  SubscriptionCodeModel({
    required this.id,
    required this.code,
    required this.durationDays,
    this.plan = 'Pro',
    this.used = false,
    this.usedBy,
    this.usedAt,
  });

  factory SubscriptionCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubscriptionCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
      plan: data['plan'] ?? 'Pro',
      used: data['used'] ?? false,
      usedBy: data['usedBy'],
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'durationDays': durationDays,
      'plan': plan,
      'used': used,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }
}
