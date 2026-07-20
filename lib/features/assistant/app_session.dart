/// حالة الجلسة الحالية في الذاكرة (مش في Firestore). بيتحمّل مرة واحدة
/// بعد تسجيل الدخول عبر AuthWrapper، وكل الشاشات بعد كده بتقرأ منه:
///
/// - effectiveTeacherId: الـ uid اللي كل بيانات Firestore (مجموعات/طلاب/
///   مواد/صفوف) بتتخزن تحته. لو المستخدم مدرس -> نفس الـ uid بتاعه.
///   لو المستخدم مساعد -> uid بتاع المدرس اللي هو تابع له.
/// - role: "teacher" أو "assistant".
/// - permissions: خريطة الصلاحيات، بتتجاهل تمامًا لو role == teacher
///   (المدرس عنده كل الصلاحيات دايمًا).
class AppSession {
  AppSession._();

  static String? _effectiveTeacherId;
  static String? _role;
  static Map<String, bool> _permissions = {};

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
  static bool get isTeacher => _role == 'teacher';
  static bool get isAssistant => _role == 'assistant';

  /// المدرس عنده كل الصلاحيات دايمًا بدون استثناء. المساعد بس بيتقيّد
  /// بالخريطة اللي المدرس حددها له.
  static bool hasPermission(String key) {
    if (isTeacher) return true;
    return _permissions[key] ?? false;
  }

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
