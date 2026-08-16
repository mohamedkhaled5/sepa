import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/assistant/manage_assistants/manage_assistants_screen.dart';
import 'package:seba/screens/settings/about_contact_screen.dart';
import 'package:seba/screens/settings/manage_subjects_grades_screen.dart';
import 'package:seba/screens/settings/user_profile_screen.dart';

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kIconBg = Color(0xFFF1F5F9); // خلفية الأيقونات
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kDanger = Color(0xFFEF4444); // أحمر مرجاني
const _kDangerBg = Color(0xFFFEF2F2); // خلفية التنبيه الخفيفة

/// الشاشة الرئيسية للإعدادات. كل قسم إعدادات جديد يُضاف هنا كـ ListTile
/// يفتح شاشته الخاصة، عشان الشاشة دي تفضل قائمة تنقل بسيطة ومنظمة.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  final bool comingSoon = true;

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: danger ? _kDanger.withValues(alpha: 0.3) : _kCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: danger
                ? _kDanger.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: danger ? _kDangerBg : _kIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: danger ? _kDanger : iconColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: "cairo",
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: danger ? _kDanger : _kNavy,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontFamily: "cairo",
              color: _kHint,
              fontSize: 12.5,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: _kHint,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _kPageBg,
        foregroundColor: _kNavy,
        centerTitle: false,
        title: const Text(
          "الإعدادات",
          style: TextStyle(
            fontFamily: "cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _kNavy,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (AppSession.hasPermission('manageSubjectsGrades')) ...[
            _settingsTile(
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF10B981), // أخضر زمردي
              title: "المواد والصفوف",
              subtitle: "إضافة أو حذف المواد الدراسية والصفوف",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageSubjectsGradesScreen(),
                  ),
                );
              },
            ),
          ],

          // إدارة المساعدين تظهر للمدرس والـ Admin فقط
          if (AppSession.isTeacher || AppSession.isAdmin) ...[
            _settingsTile(
              icon: Icons.groups_2_rounded,
              iconColor: const Color(0xFF8B5CF6), // بنفسجي ناعم
              title: "إدارة المساعدين",
              subtitle: "نسخه تجريبيه",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageAssistantsScreen(
                      teacherId: AppSession.effectiveTeacherId,
                    ),
                  ),
                );
                // AwesomeDialog(
                //   context: context,
                //   dialogType: DialogType.info,
                //   animType: AnimType.scale,
                //   title: 'الميزة قادمة قريبًا 🚀',
                //   desc:
                //       'نعمل حاليًا على تطوير هذه الميزة، وستكون متاحة في تحديث قادم.',
                //   btnOkText: 'حسنًا',
                //   btnOkOnPress: () {},
                // ).show();
              },
            ),
          ],

          _settingsTile(
            icon: Icons.person_rounded,
            iconColor: _kPrimary,
            title: "الملف الشخصي",
            subtitle: "معلوماتك الشخصية وعرض البيانات",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),

          _settingsTile(
            icon: Icons.info_rounded,
            iconColor: const Color(0xFF0EA5E9), // أزرق سماوي
            title: "التواصل",
            subtitle: "معلومات التواصل والدعم",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutContactScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          _settingsTile(
            danger: true,
            icon: Icons.logout_rounded,
            iconColor: _kDanger,
            title: "تسجيل الخروج",
            subtitle: "الخروج من الحساب الحالي",
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  title: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: _kDangerBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: _kDanger,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "تسجيل الخروج",
                          style: TextStyle(
                            fontFamily: "cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _kNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "هل أنت متأكد من تسجيل الخروج؟\n\n"
                    "سيتوجب عليك تسجيل الدخول مرة أخرى لاستخدام التطبيق.",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontSize: 13.5,
                      color: _kNavyLight,
                      height: 1.6,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "إلغاء",
                        style: TextStyle(
                          fontFamily: "cairo",
                          color: _kHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kDanger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "تسجيل الخروج",
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await authService.logout();

                  // نفرّغ الـ Navigator بالكامل عشان AuthWrapper يظهر فورًا
                  if (context.mounted) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).popUntil((route) => route.isFirst);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("حدث خطأ أثناء تسجيل الخروج: $e")),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
