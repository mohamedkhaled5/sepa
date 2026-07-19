import 'package:flutter/material.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/screens/settings/about_seba_app_screen.dart';
import 'package:seba/screens/settings/manage_subjects_grades_screen.dart';

/// الشاشة الرئيسية للإعدادات. كل قسم إعدادات جديد يُضاف هنا كـ ListTile
/// يفتح شاشته الخاصة، عشان الشاشة دي تفضل قائمة تنقل بسيطة ومنظمة.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.green),
            title: const Text("المواد والصفوف"),
            subtitle: const Text("إضافة أو حذف المواد الدراسية والصفوف"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

          ListTile(
            leading: const Icon(Icons.details, color: Colors.green),
            title: const Text(" عن التطبيق"),
            subtitle: const Text("معلومات عن التطبيق"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutSebaAppScreen()),
              );
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text("التواصل"),
            subtitle: const Text("معلومات التواصل"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        const Text("التواصل"),
                        const Icon(Icons.warning_rounded, color: Colors.red),
                      ],
                    ),
                    content: const Text(
                      "مطور التطبيق لا يريد التواصل مع أحد  \n شكراً.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("حسنًا"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "تسجيل الخروج",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("تسجيل الخروج"),
                  content: const Text(
                    "--هل أنت متأكد من تسجيل الخروج؟ --\nبعد تسجيل الخروج قم بالرجوع للصفحة الرئيسية \n     لتأكد من تسجيل الخروج",
                  ),

                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("إلغاء"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("تسجيل الخروج"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await authService.logout();
                  // AuthWrapper هيلاحظ تغيّر حالة تسجيل الدخول ويرجّعك
                  // لشاشة Login تلقائيًا بدون أي Navigator يدوي هنا.
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
