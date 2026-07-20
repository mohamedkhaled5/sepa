import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seba/features/auth/auth_service.dart';

enum _AccountRole { teacher, assistant }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  _AccountRole selectedRole = _AccountRole.teacher;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final inviteCodeController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (selectedRole == _AccountRole.teacher) {
        await _authService.registerTeacher(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        // AuthWrapper هيلاحظ تسجيل الدخول ويوديه للـ Home تلقائيًا.
      } else {
        await _authService.registerAssistant(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          inviteCode: inviteCodeController.text.trim(),
        );
        // AuthWrapper هيلاحظ إن الحساب "pending" ويوديه لشاشة انتظار
        // الموافقة تلقائيًا، مش للـ Home مباشرة.
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = _mapAuthError(e.code));
    } catch (e) {
      setState(
        () => errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "البريد الإلكتروني مستخدم بالفعل";
      case 'weak-password':
        return "كلمة المرور ضعيفة جدًا";
      case 'invalid-email':
        return "البريد الإلكتروني غير صحيح";
      default:
        return "حدث خطأ، حاول مرة أخرى";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إنشاء حساب")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================== اختيار الدور ==================
              const Text(
                "نوع الحساب",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_AccountRole>(
                segments: const [
                  ButtonSegment(
                    value: _AccountRole.teacher,
                    label: Text("مدرس"),
                    icon: Icon(Icons.school),
                  ),
                  ButtonSegment(
                    value: _AccountRole.assistant,
                    label: Text("مساعد"),
                    icon: Icon(Icons.support_agent),
                  ),
                ],
                selected: {selectedRole},
                onSelectionChanged: (selection) {
                  setState(() => selectedRole = selection.first);
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "الاسم",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "ادخل الاسم" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "البريد الإلكتروني",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return "ادخل البريد الإلكتروني";
                  if (!v.contains('@')) return "بريد إلكتروني غير صحيح";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "كلمة المرور",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "ادخل كلمة المرور";
                  if (v.length < 6)
                    return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "تأكيد كلمة المرور",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v != passwordController.text)
                    return "كلمتا المرور غير متطابقتين";
                  return null;
                },
              ),

              // ================== كود المدرس (للمساعد فقط) ==================
              if (selectedRole == _AccountRole.assistant) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: "كود المدرس",
                    hintText: "مثال: SBL84K",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (selectedRole == _AccountRole.assistant &&
                        (v == null || v.trim().isEmpty)) {
                      return "ادخل كود المدرس";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  "احصل على الكود من المدرس اللي هتشتغل معاه. بعد التسجيل "
                  "هيتبعتلك طلب انضمام لحد ما المدرس يوافق عليك.",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],

              const SizedBox(height: 20),

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
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("إنشاء حساب"),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لديك حساب بالفعل؟ تسجيل الدخول"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
