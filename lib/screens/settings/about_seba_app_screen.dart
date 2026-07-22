import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحة "عن التطبيق والتواصل". مقسّمة لجزئين:
/// 1) معلومات عني وطرق التواصل (واتساب، إيميل، فيسبوك...).
/// 2) قسم فاضي جاهز لأي إعدادات مستقبلية تحب تضيفها هنا بدل ما تتوه
///    وسط شاشة الإعدادات الرئيسية.
///
/// ⚠️ غيّر القيم داخل _ContactInfo دي ببياناتك الحقيقية قبل النشر.
class _ContactInfoApp {
  static const String developerName = "SEBA ";
  static const String aboutText =
      "تطبيق صبا \n"
      "تطبيق صبا هو واحد من تطبيقات مجموعة سبيل\n لإدارة المجموعات والطلاب   "
      "تم تطويره لتسهيل متابعة المدرسين لطلابهم.";

  // static const String whatsappNumber = "+201010834302"; // بصيغة دولية
  // static const String phoneNumber = "+201010834302";
  // static const String email = "mk2020mohamed@email.com";
  // static const String facebookUrl = "https://facebook.com/yourpage";
}

class AboutSebaAppScreen extends StatelessWidget {
  const AboutSebaAppScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تعذر فتح الرابط")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "عن التطبيق",
          style: TextStyle(
            color: Color(0xFF16213E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================== عن المطوّر ==================
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F5EC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      Image.asset(
                        "assets/icon/seba.png",
                        width: 108,
                        height: 108,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "SEBA",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16213E),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEBEEF3)),
                  ),
                  child: const Text(
                    "تطبيق صبا هو أحد تطبيقات مجموعة سبيل، ويهدف إلى تسهيل إدارة المجموعات الدراسية ومتابعة الطلاب وحضورهم ونتائجهم، مع توفير تجربة استخدام بسيطة وعملية للمدرس.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.7,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================== طرق التواصل ==================
          // const Text(
          //   "تواصل معي",
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          // ),
          const SizedBox(height: 10),

          // ListTile(
          //   leading: const Icon(Icons.chat, color: Colors.green),
          //   title: const Text("واتساب"),
          //   subtitle: const Text(_ContactInfoApp.whatsappNumber),
          //   onTap: () => _launch(
          //     context,
          //     Uri.parse(
          //       "https://wa.me/${_ContactInfoApp.whatsappNumber.replaceAll('+', '')}",
          //     ),
          //   ),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.phone, color: Colors.blue),
          //   title: const Text("اتصال هاتفي"),
          //   subtitle: const Text(_ContactInfoApp.phoneNumber),
          //   onTap: () => _launch(
          //     context,
          //     Uri.parse("tel:${_ContactInfoApp.phoneNumber}"),
          //   ),
          // ),
          // ListTile(
          //   leading: const Icon(Icons.email, color: Colors.orange),
          //   title: const Text("البريد الإلكتروني"),
          //   subtitle: const Text(_ContactInfoApp.email),
          //   onTap: () =>
          //       _launch(context, Uri.parse("mailto:${_ContactInfoApp.email}")),
          // ),

          // ListTile(
          //   leading: const Icon(Icons.facebook, color: Colors.indigo),
          //   title: const Text("فيسبوك"),
          //   onTap: () => _launch(context, Uri.parse(_ContactInfoApp.facebookUrl)),
          // ),
          const Divider(height: 40),

          // ================== إعدادات مستقبلية ==================
          // const Text(
          //   "إعدادات أخرى",
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          // ),
          // const SizedBox(height: 10),
          // const Text(
          //   "هذا المكان جاهز لأي إعدادات تضيفها لاحقًا "
          //   "(مثل: الوضع الليلي، النسخ الاحتياطي، إشعارات...).",
          //   style: TextStyle(color: Colors.black54),
          // ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEEF3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: Colors.green),
                SizedBox(width: 12),
                Text("الإصدار 1.0.0"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
