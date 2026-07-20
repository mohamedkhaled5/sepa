import 'package:flutter/material.dart';
import 'package:seba/features/auth/auth_service.dart';

enum AssistantStatusKind { pending, rejected, removed }

/// شاشة موحّدة لأي حالة "مساعد بدون وصول فعّال حاليًا":
/// - pending: طلبه لسه قيد المراجعة، مفيش حاجة يعملها غير الانتظار.
/// - rejected: المدرس رفض طلبه - يقدر يبعت طلب جديد بكود.
/// - removed: المدرس شاله من فريقه - يقدر يبعت طلب جديد بكود كمان.
class AssistantStatusScreen extends StatefulWidget {
  const AssistantStatusScreen({super.key, required this.kind});

  final AssistantStatusKind kind;

  @override
  State<AssistantStatusScreen> createState() => _AssistantStatusScreenState();
}

class _AssistantStatusScreenState extends State<AssistantStatusScreen> {
  final _authService = AuthService();
  final _inviteCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitNewCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.resubmitJoinRequest(
        inviteCode: _inviteCodeController.text.trim(),
      );
      // مفيش داعي لأي Navigator هنا؛ AuthWrapper بيراقب المستند بشكل حي
      // وهيحوّل الشاشة تلقائيًا لـ "قيد المراجعة" بمجرد ما الـ status
      // يتحدث لـ pending.
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData get _icon {
    switch (widget.kind) {
      case AssistantStatusKind.pending:
        return Icons.hourglass_top;
      case AssistantStatusKind.rejected:
        return Icons.cancel_outlined;
      case AssistantStatusKind.removed:
        return Icons.link_off;
    }
  }

  Color get _iconColor {
    switch (widget.kind) {
      case AssistantStatusKind.pending:
        return Colors.orange;
      case AssistantStatusKind.rejected:
      case AssistantStatusKind.removed:
        return Colors.red;
    }
  }

  String get _title {
    switch (widget.kind) {
      case AssistantStatusKind.pending:
        return "طلبك قيد المراجعة";
      case AssistantStatusKind.rejected:
        return "تم رفض طلب الانضمام";
      case AssistantStatusKind.removed:
        return "تم إلغاء ارتباطك بالمدرس";
    }
  }

  String get _description {
    switch (widget.kind) {
      case AssistantStatusKind.pending:
        return "لسه المدرس ماوافقش على طلب انضمامك. هتقدر تدخل التطبيق "
            "تلقائيًا بمجرد ما يوافق عليك.";
      case AssistantStatusKind.rejected:
        return "المدرس رفض طلب انضمامك كمساعد. تقدر تتواصل معه لمعرفة "
            "السبب، أو تدخل كود دعوة جديد تحت وتبعت طلب من الأول.";
      case AssistantStatusKind.removed:
        return "المدرس أزالك من فريقه. تقدر تدخل كود دعوة جديد (لنفس "
            "المدرس أو مدرس تاني) وتبعت طلب انضمام جديد.";
    }
  }

  bool get _canResubmit =>
      widget.kind == AssistantStatusKind.rejected ||
      widget.kind == AssistantStatusKind.removed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, size: 64, color: _iconColor),
                const SizedBox(height: 20),
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),

                if (_canResubmit) ...[
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _inviteCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: "كود المدرس الجديد",
                            hintText: "مثال: SBL84K",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "ادخل كود المدرس"
                              : null,
                        ),
                        const SizedBox(height: 12),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitNewCode,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("إرسال طلب انضمام جديد"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("تسجيل الخروج"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
