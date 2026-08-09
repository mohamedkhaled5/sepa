//شيت سفلي بسيط لتعديل صلاحيات مساعد معين بسويتشات On/Off.
import 'package:flutter/material.dart';
import 'package:seba/model/user_model.dart';

const _kNavy = Color(0xFF16213E);
const _kPageBg = Color(0xFFF6F8FB);
const _kCardBorder = Color(0xFFEBEEF3);
const _kIconBg = Color(0xFFEAF1FB);
const _kSuccess = Color(0xFF2E9E6B);
const _kDanger = Color(0xFFD1483F);

class PermissionsEditorSheet extends StatefulWidget {
  const PermissionsEditorSheet({super.key, required this.assistant});

  final UserModel assistant;

  @override
  State<PermissionsEditorSheet> createState() => _PermissionsEditorSheetState();
}

class _PermissionsEditorSheetState extends State<PermissionsEditorSheet> {
  late Map<String, bool> permissions;

  static const _labels = {
    'attendance': 'تسجيل حضور وغياب',
    'exams': 'تسجيل نتائج الامتحانات',
    // 'notes': 'إضافة ملاحظات',
    'createStudent': 'إنشاء طالب جديد',
    'editStudent': 'تعديل بيانات طالب',
    'deleteStudent': 'حذف طالب',
    // 'transferStudent': 'نقل طالب بين المجموعات',
    // 'createGroup': 'إنشاء مجموعة',
    // 'editGroup': 'تعديل مجموعة',
    // 'deleteGroup': 'حذف مجموعة',
    // 'manageSubjectsGrades': 'إدارة المواد والصفوف',
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
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = _labels.entries.elementAt(index);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _kCardBorder),
                      ),
                      child: SwitchListTile(
                        activeThumbColor: _kSuccess,
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
