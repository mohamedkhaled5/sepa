import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seba/features/auth/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final emailController = TextEditingController();

  bool isLoading = false;
  String? message;
  bool isError = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      await _authService.resetPassword(emailController.text.trim());
      setState(() {
        isError = false;
        message = "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        isError = true;
        message = e.code == 'user-not-found'
            ? "لا يوجد حساب بهذا البريد الإلكتروني"
            : "حدث خطأ، حاول مرة أخرى";
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("نسيت كلمة المرور")),
      body: Padding(
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
              const SizedBox(height: 20),

              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    message!,
                    style: TextStyle(
                      color: isError ? Colors.red : Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton(
                onPressed: isLoading ? null : _sendResetLink,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("إرسال رابط إعادة تعيين كلمة المرور"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
