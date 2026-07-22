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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF16213E)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF16213E), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: const Color(0xFF16213E),
        title: const Text(
          "إنشاء حساب",
          style: TextStyle(
            fontFamily: "cairo",
            fontWeight: FontWeight.bold,
            color: Color(0xFF16213E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              //================== Logo ==================
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Image.asset(
                      "assets/icon/seba.png",
                      width: 105,
                      height: 105,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "إنشاء حساب جديد",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16213E),
                  fontFamily: "cairo",
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "أنشئ حسابًا كمدرس أو كمساعد للبدء في استخدام التطبيق",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontFamily: "cairo"),
              ),

              const SizedBox(height: 28),
              // ================== اختيار الدور ==================
              const Text(
                "نوع الحساب",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6EAF0)),
                ),
                child: SegmentedButton<_AccountRole>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF16213E);
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return const Color(0xFF16213E);
                    }),
                    side: WidgetStateProperty.all(BorderSide.none),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: _AccountRole.teacher,
                      icon: Icon(Icons.school),
                      label: Text("مدرس"),
                    ),
                    ButtonSegment(
                      value: _AccountRole.assistant,
                      icon: Icon(Icons.support_agent),
                      label: Text("مساعد"),
                    ),
                  ],
                  selected: {selectedRole},
                  onSelectionChanged: (selection) {
                    setState(() => selectedRole = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                decoration: _inputDecoration(
                  label: "الاسم",
                  icon: Icons.person_outline,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "ادخل الاسم" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  label: "البريد الإلكتروني",
                  icon: Icons.email_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "ادخل البريد الإلكتروني";
                  }

                  if (!v.contains("@")) {
                    return "بريد إلكتروني غير صحيح";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration:
                    _inputDecoration(
                      label: "كلمة المرور",
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "ادخل كلمة المرور";
                  }

                  if (v.length < 6) {
                    return "كلمة المرور يجب أن تكون 6 أحرف على الأقل";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration:
                    _inputDecoration(
                      label: "تأكيد كلمة المرور",
                      icon: Icons.lock_reset_outlined,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                validator: (v) {
                  if (v != passwordController.text) {
                    return "كلمتا المرور غير متطابقتين";
                  }
                  return null;
                },
              ),

              // ================== كود المدرس (للمساعد فقط) ==================
              if (selectedRole == _AccountRole.assistant) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: "كود المدرس",
                    hint: "مثال : SBL84K",
                    icon: Icons.vpn_key_outlined,
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
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "احصل على كود الدعوة من المدرس، وبعد التسجيل سيصل إليه طلب انضمام ليوافق عليه.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontFamily: "cairo",
                          ),
                        ),
                      ),
                    ],
                  ),
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

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.person_add_alt_1_rounded, size: 22),
                            SizedBox(width: 10),
                            Text(
                              "إنشاء الحساب",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'cairo',
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'cairo',
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: "لديك حساب بالفعل؟ "),
                        TextSpan(
                          text: "تسجيل الدخول",
                          style: TextStyle(
                            color: Color(0xFF16213E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
