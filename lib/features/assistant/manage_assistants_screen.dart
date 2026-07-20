import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/model/user_model.dart';

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
      appBar: AppBar(title: const Text("إدارة المساعدين")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================== كود الدعوة ==================
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("كود الدعوة الخاص بك"),
                        Text(
                          _inviteCode ?? "...",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyInviteCode,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ================== طلبات الانضمام المعلّقة ==================
          const Text(
            "طلبات الانضمام",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _authService.pendingAssistantsStream(widget.teacherId),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "لا توجد طلبات انضمام معلّقة",
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final assistant = UserModel.fromFirestore(doc);
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(assistant.name),
                      subtitle: Text(assistant.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            tooltip: "قبول",
                            onPressed: () =>
                                _authService.approveAssistant(assistant.uid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            tooltip: "رفض",
                            onPressed: () =>
                                _authService.rejectAssistant(assistant.uid),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // ================== المساعدون المقبولون ==================
          const Text(
            "المساعدون",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _authService.approvedAssistantsStream(widget.teacherId),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "لا يوجد مساعدون بعد",
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final assistant = UserModel.fromFirestore(doc);
                  final activeCount = assistant.permissions.values
                      .where((v) => v)
                      .length;

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(assistant.name),
                      subtitle: Text("$activeCount صلاحية مفعّلة"),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune),
                            tooltip: "تعديل الصلاحيات",
                            onPressed: () => _editPermissions(assistant),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                            ),
                            tooltip: "إزالة",
                            onPressed: () async {
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
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("إزالة"),
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
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// شيت سفلي بسيط لتعديل صلاحيات مساعد معين بسويتشات On/Off.
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "صلاحيات ${widget.assistant.name}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._labels.entries.map((entry) {
              return SwitchListTile(
                title: Text(entry.value),
                value: permissions[entry.key] ?? false,
                onChanged: (v) => setState(() => permissions[entry.key] = v),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, permissions),
                child: const Text("حفظ"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
