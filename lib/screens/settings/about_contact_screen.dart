import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const String email = "mk2020mohamed@email.com";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عن المطوّر")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================== عن المطوّر ==================
          CircleAvatar(
            radius: 40,
            child: Image.asset("assets/icon/sapeel.png"),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _ContactInfo.developerName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ContactInfo.aboutText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),

          const Divider(height: 40),

          // ================== طرق التواصل ==================
          const Text(
            "تواصل معي",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title: const Text("واتساب"),
            subtitle: const Text(_ContactInfo.whatsappNumber),
            // onTap: () => _launch(
            //   context,
            //   Uri.parse(
            //     "https://wa.me/${_ContactInfo.whatsappNumber.replaceAll('+', '')}",
            //   ),
            // ),
          ),
          // ListTile(
          //   leading: const Icon(Icons.phone, color: Colors.blue),
          //   title: const Text("اتصال هاتفي"),
          //   subtitle: const Text(_ContactInfo.phoneNumber),
          //   // onTap: () =>
          //   //     _launch(context, Uri.parse("tel:${_ContactInfo.phoneNumber}")),
          // ),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.orange),
            title: const Text("البريد الإلكتروني"),
            subtitle: const Text(_ContactInfo.email),
            // onTap: () =>
            //     _launch(context, Uri.parse("mailto:${_ContactInfo.email}")),
          ),

          // ListTile(
          //   leading: const Icon(Icons.facebook, color: Colors.indigo),
          //   title: const Text("فيسبوك"),
          //   onTap: () => _launch(context, Uri.parse(_ContactInfo.facebookUrl)),
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
          Center(
            child: Text(
              "الإصدار 1.0.0",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
