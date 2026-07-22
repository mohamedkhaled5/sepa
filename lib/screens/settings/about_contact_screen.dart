import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _kNavy = Color(0xFF16213E);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);

/// صفحة "عن التطبيق والتواصل". مقسّمة لجزئين:
/// 1) معلومات عني وطرق التواصل (واتساب، إيميل، فيسبوك...).
/// 2) قسم فاضي جاهز لأي إعدادات مستقبلية تحب تضيفها هنا بدل ما تتوه
///    وسط شاشة الإعدادات الرئيسية.
///
/// ⚠️ غيّر القيم داخل _ContactInfo دي ببياناتك الحقيقية قبل النشر.
class _ContactInfo {
  static const String developerName = "sapeel organization";
  static const String aboutText = "سبيل هي منظمه برمجيه تحت الإنشاء ";

  static const String whatsappNumber = "+201010834302"; // بصيغة دولية
  static const String phoneNumber = "+201010834302";
  static const String email = "mk2020mohamed@gmail.com";
  // static const String facebookUrl = "https://facebook.com/yourpage";
}

class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تعذر فتح الرابط")));
    }
  }

  Widget _contactTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
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
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: "cairo",
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontFamily: "cairo", color: _kHint),
        ),
        trailing: onTap != null
            ? const Icon(Icons.open_in_new_rounded, size: 18)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kPageBg,
        foregroundColor: _kNavy,
        title: const Text(
          "عن المطور",
          style: TextStyle(fontFamily: "cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================== عن المطور ==================
          Center(
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: SizedBox(
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
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),

                                Positioned(
                                  child: Image.asset(
                                    "assets/icon/sapeel.png",
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  _ContactInfo.developerName,
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _ContactInfo.aboutText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "cairo",
                      color: _kHint,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 40),

          // ================== طرق التواصل ==================
          const SizedBox(height: 30),

          const Text(
            "وسائل التواصل",
            style: TextStyle(
              fontFamily: "cairo",
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 14),
          _contactTile(
            icon: Icons.chat_rounded,
            color: Colors.green,
            title: "واتساب",
            subtitle: _ContactInfo.whatsappNumber,
            onTap: () => _launch(
              context,
              Uri.parse(
                "https://wa.me/${_ContactInfo.whatsappNumber.replaceAll("+", "")}",
              ),
            ),
          ),

          _contactTile(
            icon: Icons.email_rounded,
            color: Colors.orange,
            title: "البريد الإلكتروني",
            subtitle: _ContactInfo.email,
            onTap: () =>
                _launch(context, Uri.parse("mailto:${_ContactInfo.email}")),
          ),
          const SizedBox(height: 35),

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
