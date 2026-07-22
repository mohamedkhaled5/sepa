import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/model/user_model.dart';

const _kNavy = Color(0xFF16213E);
const _kPageBg = Color(0xFFF6F8FB);
const _kCardBorder = Color(0xFFEBEEF3);
const _kIconBg = Color(0xFFEAF1FB);
const _kSuccess = Color(0xFF2E9E6B);
const _kDanger = Color(0xFFD1483F);

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

  Future<void> _editPermissions(UserModel assistant) async {
    final updated = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PermissionsEditorSheet(assistant: assistant),
    );

    if (updated != null) {
      await _authService.updateAssistantPermissions(assistant.uid, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث صلاحيات المساعد")),
        );
      }
    }
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
          //================== كود الدعوة ==================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEBEEF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A16213E),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _copyInviteCode,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF16213E),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          "كود الدعوة",
                          style: TextStyle(
                            fontFamily: "cairo",
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF16213E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "شارك هذا الكود مع المساعد",
                          style: TextStyle(
                            fontFamily: "cairo",
                            color: Color(0xFF9AA3B2),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF1FB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vpn_key_rounded,
                        color: Color(0xFF16213E),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _inviteCode ?? "...",
                      style: const TextStyle(
                        fontFamily: "cairo",
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 3,
                        color: Color(0xFF16213E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ================== طلبات الانضمام المعلّقة ==================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBEEF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A16213E),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFEAF1FB),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF16213E),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "طلبات الانضمام",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16213E),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _authService.pendingAssistantsStream(
                    widget.teacherId,
                  ),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFEAF1FB),
                              child: Icon(
                                Icons.group_off_rounded,
                                color: Color(0xFF16213E),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "لا توجد طلبات انضمام",
                              style: TextStyle(
                                fontFamily: "cairo",
                                color: Color(0xFF9AA3B2),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final assistant = UserModel.fromFirestore(doc);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFDFD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEBEEF3)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _authService.approveAssistant(
                                      assistant.uid,
                                    ),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _authService.rejectAssistant(
                                      assistant.uid,
                                    ),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      assistant.name,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: "cairo",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      assistant.email,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: "cairo",
                                        color: Color(0xFF9AA3B2),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAF1FB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF16213E),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ================== المساعدون المقبولون ==================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBEEF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A16213E),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFEAF1FB),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: Color(0xFF16213E),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "المساعدون",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16213E),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _authService.approvedAssistantsStream(
                    widget.teacherId,
                  ),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFEAF1FB),
                              child: Icon(
                                Icons.groups_outlined,
                                color: Color(0xFF16213E),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "لا يوجد مساعدون حتى الآن",
                              style: TextStyle(
                                fontFamily: "cairo",
                                color: Color(0xFF9AA3B2),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final assistant = UserModel.fromFirestore(doc);

                        final activeCount = assistant.permissions.values
                            .where((v) => v)
                            .length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFDFD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEBEEF3)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _editPermissions(assistant),
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.tune_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("إزالة المساعد"),
                                          content: Text(
                                            "هل تريد إزالة ${assistant.name} من فريقك؟",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("إلغاء"),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                "إزالة",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await _authService.removeAssistant(
                                          assistant.uid,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person_remove_rounded,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      assistant.name,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: "cairo",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF1FB),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "$activeCount صلاحية مفعلة",
                                        style: const TextStyle(
                                          fontFamily: "cairo",
                                          color: Color(0xFF16213E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAF1FB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF16213E),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//شيت سفلي بسيط لتعديل صلاحيات مساعد معين بسويتشات On/Off.
class _PermissionsEditorSheet extends StatefulWidget {
  const _PermissionsEditorSheet({required this.assistant});

  final UserModel assistant;

  @override
  State<_PermissionsEditorSheet> createState() =>
      _PermissionsEditorSheetState();
}

class _PermissionsEditorSheetState extends State<_PermissionsEditorSheet> {
  late Map<String, bool> permissions;

  static const _labels = {
    'attendance': 'تسجيل حضور وغياب',
    'exams': 'تسجيل نتائج الامتحانات',
    'notes': 'إضافة ملاحظات',
    'createStudent': 'إنشاء طالب جديد',
    'editStudent': 'تعديل بيانات طالب',
    'deleteStudent': 'حذف طالب',
    'transferStudent': 'نقل طالب بين المجموعات',
    'createGroup': 'إنشاء مجموعة',
    'editGroup': 'تعديل مجموعة',
    'deleteGroup': 'حذف مجموعة',
    'manageSubjectsGrades': 'إدارة المواد والصفوف',
    'reports': 'رؤية التقارير',
  };

  @override
  void initState() {
    super.initState();

    permissions = Map<String, bool>.from(widget.assistant.permissions);

    for (final key in _labels.keys) {
      permissions.putIfAbsent(key, () => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: _kPageBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // المقبض العلوي
              Container(
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "صلاحيات ${widget.assistant.name}",
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _kNavy,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _labels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = _labels.entries.elementAt(index);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _kCardBorder),
                      ),
                      child: SwitchListTile(
                        activeColor: _kSuccess,
                        inactiveThumbColor: Colors.grey,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),

                        title: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        value: permissions[entry.key] ?? false,

                        onChanged: (v) {
                          setState(() {
                            permissions[entry.key] = v;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    "حفظ الصلاحيات",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, permissions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
