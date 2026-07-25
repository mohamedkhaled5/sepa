// lib/features/assistant/app_session.dart

/// حالة الجلسة الحالية في الذاكرة (مش في Firestore). بيتحمّل مرة واحدة
/// بعد تسجيل الدخول عبر AuthWrapper، وكل الشاشات بعد كده بتقرأ منه.
class AppSession {
  AppSession._();

  static String? _effectiveTeacherId;
  static String? _role;
  static Map<String, bool> _permissions =
      {}; // الصلاحيات الممنوحة للمساعد من المدرس

  static String get effectiveTeacherId {
    final id = _effectiveTeacherId;
    if (id == null) {
      throw StateError(
        'لم يتم تحميل بيانات الجلسة بعد - تأكد من استدعاء AppSession.setSession أولًا',
      );
    }
    return id;
  }

  static bool get isSessionLoaded => _effectiveTeacherId != null;

  static String? get role => _role;
  static bool get isAdmin => _role == 'admin';
  static bool get isTeacher => _role == 'teacher';
  static bool get isAssistant => _role == 'assistant';

  /// الأدمن والمدرس عندهم كل الصلاحيات دايمًا بدون استثناء.
  /// المساعد بيتقيّد بالتقاطع بين (ما منحه المدرس) و (ما تسمح به باقة المدرس).
  static bool hasPermission(String key) {
    if (isAdmin || isTeacher) {
      return true;
    }

    if (isAssistant) {
      final grantedByTeacher = _permissions[key] ?? false;
      // إذا لم تُحدد باقة المدرس سقفًا صريحًا لمفتاح معين، نعتبره مسموحًا افتراضيًا (true)
    }

    return false;
  }

  /// هل يحق للمدرس تفعيل هذه الصلاحية لمساعده في شاشة الإعدادات؟
  /// (تُستخدم لإظهار أو تعطيل مفاتيح التشغيل Switches للمدرس)

  static void setSession({
    required String effectiveTeacherId,
    required String role,
    Map<String, bool> permissions = const {},
  }) {
    _effectiveTeacherId = effectiveTeacherId;
    _role = role;
    _permissions = permissions;
  }

  static void clear() {
    _effectiveTeacherId = null;
    _role = null;
    _permissions = {};
  }
}
