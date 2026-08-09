// ================== المساعدون المقبولون ==================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/manage_assistants/assistant_permissions.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/model/user_model.dart';



class AcceptedAssistants extends StatefulWidget {
  const AcceptedAssistants({super.key, required this.teacherId});
  final String teacherId;
  @override
  State<AcceptedAssistants> createState() => _AcceptedAssistantsState();
}

class _AcceptedAssistantsState extends State<AcceptedAssistants> {
  final _authService = AuthService();

  Future<void> _editPermissions(UserModel assistant) async {
    final updated = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PermissionsEditorSheet(assistant: assistant),
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
    return Container(
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
                child: Icon(Icons.groups_2_rounded, color: Color(0xFF16213E)),
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
            stream: _authService.approvedAssistantsStream(widget.teacherId),
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
                                          style: TextStyle(color: Colors.white),
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
    );
  }
}
