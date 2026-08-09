import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/assistant/manage_assistants/Pending_joining_requests.dart';
import 'package:seba/features/assistant/manage_assistants/accepted_assistants.dart';
import 'package:seba/features/assistant/manage_assistants/invite_code.dart';
import 'package:seba/features/auth/auth_service.dart';

/// شاشة إدارة المساعدين - خاصة بالمدرس فقط.
/// فيها: كود الدعوة (لمشاركته)، طلبات الانضمام المعلّقة (موافقة/رفض)،
/// وقائمة المساعدين المقبولين مع إمكانية تعديل صلاحيات كل واحد فيهم.
class ManageAssistantsScreen extends StatefulWidget {
  const ManageAssistantsScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  State<ManageAssistantsScreen> createState() => _ManageAssistantsScreenState();
}

class _ManageAssistantsScreenState extends State<ManageAssistantsScreen> {
  final _authService = AuthService();
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    _loadInviteCode();
  }

  Future<void> _loadInviteCode() async {
    // ensureInviteCode بتضمن ظهور كود دايمًا، حتى لو الحساب قديم
    // ومكانش فيه كود أصلًا وقت إنشائه.
    final code = await _authService.ensureInviteCode(widget.teacherId);
    if (mounted) setState(() => _inviteCode = code);
  }

  void _copyInviteCode() {
    if (_inviteCode == null) return;
    Clipboard.setData(ClipboardData(text: _inviteCode!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("تم نسخ الكود")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        centerTitle: false,
        foregroundColor: const Color(0xFF16213E),
        title: const Text(
          "إدارة المساعدين",
          style: TextStyle(
            fontFamily: "cairo",
            fontWeight: FontWeight.bold,
            color: Color(0xFF16213E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================== كود الدعوة ==================
          InviteCodeContainer(
            inviteCode: _inviteCode,
            copyInviteCode: _copyInviteCode,
          ),
          const SizedBox(height: 24),

          // ================== طلبات الانضمام المعلّقة ==================
          PendingJoiningRequests(teacherId: widget.teacherId),
          const SizedBox(height: 24),

          // ================== المساعدون المقبولون ==================
          AcceptedAssistants(teacherId: widget.teacherId),
        ],
      ),
    );
  }
}
