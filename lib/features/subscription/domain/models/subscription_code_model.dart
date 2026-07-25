import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionCodeModel {
  final String id;
  final String code;
  final int durationDays;
  final String plan;
  final int maxAssistants; // 👈 عدد المساعدين المسموح بانشاء
  final bool used;
  final String? usedBy;
  final DateTime? usedAt;

  SubscriptionCodeModel({
    required this.id,
    required this.code,
    required this.durationDays,
    this.plan = 'Pro',
    this.maxAssistants = 0,
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
      maxAssistants:
          (data['maxAssistants'] as num?)?.toInt() ??
          2, // 👈 3. قراءة الحقل مع قيمة افتراضية (2)
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
      'maxAssistants': maxAssistants, // 👈 4. تضمينه عند الحفظ
      'used': used,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }
}
