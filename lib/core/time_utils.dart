import 'package:flutter/material.dart';

/// أدوات تحويل الوقت المخزّن كنص (زي "10:00 AM" اللي بيرجعه
/// TimeOfDay.format) لدقائق منذ منتصف الليل - عشان نقدر نحسب مواقع
/// وأطوال بطاقات الجدول الزمني بدقة، ونقارن بين أوقات المجموعات
/// لاكتشاف التعارضات.
class TimeUtils {
  TimeUtils._();

  /// يحوّل "10:00 AM" أو "2:30 PM" أو حتى "22:00" (صيغة 24 ساعة، لو
  /// المجموعة اتسجلت وقت ما كان هاتف المستخدم على نظام 24 ساعة، لأن
  /// TimeOfDay.format(context) بيتبع إعداد الساعة في نظام الهاتف نفسه
  /// مش صيغة ثابتة) لعدد الدقائق منذ منتصف الليل (0-1439).
  /// يرجع null لو النص مش قابل للتفسير خالص، بدل ما يرمي استثناء - أي
  /// مجموعة بتاريخ/وقت غير سليم بتتجاهل بأمان في الجدول بدل ما توقف
  /// الشاشة كلها.
  static int? parseToMinutes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([APap][Mm]\.?|ص|م)?$',
    ).firstMatch(raw.trim());

    if (match == null) return null;

    int hour = int.tryParse(match.group(1)!) ?? -1;
    final minute = int.tryParse(match.group(2)!) ?? -1;
    final period = match.group(3)?.toLowerCase();

    if (period != null) {
      // صيغة 12 ساعة: AM/PM إنجليزي أو ص/م عربي.
      final isPm = period.startsWith('p') || period == 'م';
      final isAm = period.startsWith('a') || period == 'ص';
      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
    }
    // لو مفيش period خالص، يبقى النص أصلًا بصيغة 24 ساعة ("22:00")
    // ومحتاجش أي تحويل إضافي.

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h >= 12 ? "PM" : "AM";
    final displayHour = h % 12 == 0 ? 12 : h % 12;
    return "$displayHour:${m.toString().padLeft(2, '0')} $period";
  }
}
