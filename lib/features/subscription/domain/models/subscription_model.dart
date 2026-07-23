// lib/features/subscription/domain/models/subscription_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final bool active;
  final String plan;
  final DateTime startDate;
  final DateTime endDate;

  SubscriptionModel({
    required this.active,
    required this.plan,
    required this.startDate,
    required this.endDate,
  });

  /// التحقق المباشر من انتهاء الاشتراك زمنياً
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// هل الاشتراك فعال ومستمر؟
  bool get isCurrentlyActive => active && !isExpired;

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      active: map['active'] ?? false,
      plan: map['plan'] ?? 'free',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'active': active,
      'plan': plan,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }
}
