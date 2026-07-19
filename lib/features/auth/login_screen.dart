import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/features/auth/register_screen.dart';
import 'package:seba/features/auth/forgot_password_screen.dart';

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
      appBar: AppBar(title: const Text("تسجيل الدخول")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "البريد الإلكتروني",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "ادخل البريد الإلكتروني"
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "كلمة المرور",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "ادخل كلمة المرور" : null,
              ),
              const SizedBox(height: 8),

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
              const SizedBox(height: 12),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("تسجيل الدخول"),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: isLoading ? null : _loginWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text("الدخول بواسطة Google"),
              ),
              const SizedBox(height: 20),

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
    );
  }
}
