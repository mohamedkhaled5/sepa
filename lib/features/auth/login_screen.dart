import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/auth/register_screen.dart';
import 'package:seba/features/auth/forgot_password_screen.dart';

const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kPageBg = Color(0xFFF6F8FB);
const _kCardBorder = Color(0xFFEBEEF3);
const _kIconBg = Color(0xFFEAF8EF);
const _kHint = Color(0xFF9AA3B2);
const _kDanger = Color(0xFFD1483F);
const _kDangerBg = Color(0xFFFBE9E7);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // AuthWrapper هو اللي هيوديك للـ Home تلقائيًا.
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = _mapError(e.code));
    } catch (e) {
      setState(() => errorMessage = "حدث خطأ، حاول مرة أخرى");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      setState(() => errorMessage = "تعذر تسجيل الدخول عبر Google");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return "لا يوجد حساب بهذا البريد الإلكتروني";
      case 'wrong-password':
      case 'invalid-credential':
        return "كلمة المرور غير صحيحة";
      case 'invalid-email':
        return "البريد الإلكتروني غير صحيح";
      default:
        return "حدث خطأ، حاول مرة أخرى";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _kNavy,
        title: const Text(
          "تسجيل الدخول",
          style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 15),

                //=================== Logo ===================
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: _kIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: Image.asset("assets/icon/seba.png"),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "مرحبًا بك",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "سجل الدخول للوصول إلى حسابك",
                  style: TextStyle(color: _kHint),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "البريد الإلكتروني",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "ادخل البريد الإلكتروني"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "كلمة المرور",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "ادخل كلمة المرور"
                            : null,
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text("نسيت كلمة المرور؟"),
                        ),
                      ),

                      if (errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kDangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kDanger),
                          ),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _kDanger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "تسجيل الدخول",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kCardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading ? null : _loginWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 32),
                          label: const Text("الدخول بواسطة Google"),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "الدخول بواسطة Google متاح للمدرسين فقط.\nإذا كنت مساعدًا فاستخدم البريد الإلكتروني.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _kHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text("ليس لديك حساب؟ إنشاء حساب جديد"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
