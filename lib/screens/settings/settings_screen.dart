import 'package:flutter/material.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/assistant/manage_assistants_screen.dart';
import 'package:seba/screens/settings/about_contact_screen.dart';
import 'package:seba/screens/settings/about_seba_app_screen.dart';
import 'package:seba/screens/settings/manage_subjects_grades_screen.dart';

const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kDanger = Color(0xFFD1483F);

/// الشاشة الرئيسية للإعدادات. كل قسم إعدادات جديد يُضاف هنا كـ ListTile
/// يفتح شاشته الخاصة، عشان الشاشة دي تفضل قائمة تنقل بسيطة ومنظمة.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  //
  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16213E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: _kIconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: "cairo",
            fontWeight: FontWeight.bold,
            color: danger ? _kDanger : _kNavy,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: "cairo",
            color: _kHint,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 17,
          color: _kHint,
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
        backgroundColor: _kPageBg,
        foregroundColor: _kNavy,
        title: const Text(
          "الإعدادات",
          style: TextStyle(fontFamily: "cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          if (AppSession.hasPermission('manageSubjectsGrades')) ...[
            _settingsTile(
              icon: Icons.menu_book_rounded,
              iconColor: Colors.green,
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
            const Divider(height: 1),
          ],

          // إدارة المساعدين تظهر للمدرس فقط - المساعد مالوش صلاحية
          // يدير مساعدين تانيين أو يشوف كود الدعوة.
          if (AppSession.isTeacher) ...[
            _settingsTile(
              icon: Icons.groups_2_rounded,
              iconColor: Colors.deepPurple,
              title: "إدارة المساعدين",
              subtitle: "كود الدعوة، طلبات الانضمام، والصلاحيات",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageAssistantsScreen(
                      teacherId: AppSession.effectiveTeacherId,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
          ],

          _settingsTile(
            icon: Icons.info_rounded,
            iconColor: Colors.teal,
            title: "عن التطبيق",
            subtitle: "معلومات عن التطبيق",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutSebaAppScreen()),
              );
            },
          ),
          const Divider(height: 1),

          _settingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: "التواصل",
            subtitle: "معلومات التواصل",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutContactScreen()),
              );
            },
          ),
          const Divider(height: 1),

          _settingsTile(
            danger: true,
            icon: Icons.logout_rounded,
            iconColor: Colors.red,
            title: "تسجيل الخروج",
            subtitle: "الخروج من الحساب الحالي",
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  title: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: _kDanger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: _kDanger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "تسجيل الخروج",
                          style: TextStyle(
                            fontFamily: "cairo",
                            fontWeight: FontWeight.bold,
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
                    style: TextStyle(fontFamily: "cairo", height: 1.6),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  actions: [
                    SizedBox(
                      width: 100,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kNavy,
                          side: const BorderSide(color: _kCardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("إلغاء"),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kDanger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("تسجيل الخروج"),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await authService.logout();

                  // نفرّغ الـ Navigator بالكامل عشان AuthWrapper يظهر فورًا
                  // بدل ما يفضل مخبي تحت الشاشات المفتوحة قبل الخروج.
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
