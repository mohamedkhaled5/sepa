import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/select_group_tree_widget.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);

/// شاشة إضافة طالب مستقلة تُفتح من الصفحة الرئيسية.
class AddStudentGeneralScreen extends StatefulWidget {
  const AddStudentGeneralScreen({super.key});

  @override
  State<AddStudentGeneralScreen> createState() =>
      _AddStudentGeneralScreenState();
}

class _AddStudentGeneralScreenState extends State<AddStudentGeneralScreen> {
  bool conectWithPhone = false;
  bool conectWithWhatsApp = false;

  final studentNameController = TextEditingController();
  final studentParentNameController = TextEditingController();
  final parentRelationController = TextEditingController();
  final studentPhoneController = TextEditingController();

  final List<GroupModel> selectedGroups = [];

  Future<void> saveStudent() async {
    final doc = FirestorePaths.students.doc();

    final student = StudentModel(
      id: doc.id,
      groupIds: selectedGroups.map((g) => g.id!).toList(),
      name: studentNameController.text,
      parentName: studentParentNameController.text,
      parentRelation: parentRelationController.text,
      phone: studentPhoneController.text,
      conectWithPhone: conectWithPhone,
      conectWithWhatsApp: conectWithWhatsApp,
    );

    await doc.set(student.toJson());
  }

  void _openAddGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: SelectGroupTreeWidget(
              excludeGroupIds: selectedGroups.map((g) => g.id!).toList(),
              onGroupSelected: (GroupModel group) {
                setState(() {
                  selectedGroups.add(group);
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    studentNameController.dispose();
    studentParentNameController.dispose();
    parentRelationController.dispose();
    studentPhoneController.dispose();
    super.dispose();
  }

  // ================== عنصر البطاقة العام لكل حقل ==================
  Widget _fieldCard({
    required IconData icon,
    required String label,
    required String? valueText,
    required String placeholder,
    Widget? trailing,
    VoidCallback? onTap,
    Widget? customChild,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16213E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (trailing != null) trailing,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        customChild ??
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              valueText ?? placeholder,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 12.5,
                                color: valueText == null ? _kHint : _kNavyLight,
                                fontWeight: valueText == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _kIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _kNavy, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        foregroundColor: _kNavy,
        title: Text(
          "إنشاء طالب جديد",
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: _kIconBg,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/icon/sepa_without_ground.png",
                width: 33,
                height: 33,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "مجموعات الطالب",
              style: TextStyle(
                fontFamily: "cairo",
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _kNavy,
              ),
            ),

            const SizedBox(height: 12),

            if (selectedGroups.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Center(
                  child: Text(
                    "لم يتم اختيار أي مجموعة",
                    style: TextStyle(fontFamily: "cairo", color: _kHint),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedGroups.map((g) {
                  return Chip(
                    label: Text(
                      "${g.subject ?? ''} • ${g.grade ?? ''}",
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.w600,
                        color: _kNavy,
                      ),
                    ),
                    backgroundColor: _kIconBg,
                    deleteIcon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _kNavy,
                    ),
                    side: const BorderSide(color: _kCardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onDeleted: () {
                      setState(() => selectedGroups.remove(g));
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _openAddGroupSheet,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: _kNavy,
                ),
                label: const Text(
                  "إضافة مجموعة",
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontWeight: FontWeight.bold,
                    color: _kNavy,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _kCardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const Divider(height: 40),

            // ================== اسم الطالب  وولي الأمر وصلة القرابه (حقل نصي فعلي) ==================
            _fieldCard(
              icon: Icons.groups_2_rounded,
              label: "اسم الطالب بالكامل",
              valueText: null,
              placeholder: "",
              customChild: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "اسم الطالب بالكامل",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: studentNameController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _kNavyLight,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: " اسم الطالب بالكامل",
                      hintStyle: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12.5,
                        color: _kHint,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child:
                      // ================== اسم الطالب  وولي الأمر وصلة القرابه (حقل نصي فعلي) ==================
                      _fieldCard(
                        icon: Icons.groups_2_rounded,
                        label: "صلة ولي الأمر بالطالب",
                        valueText: null,
                        placeholder: "",
                        customChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "صله ولي الأمر بالطالب",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            TextField(
                              controller: parentRelationController,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _kNavyLight,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: "صله ولي الأمر بالطالب",
                                hintStyle: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 12.5,
                                  color: _kHint,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      // ================== اسم الطالب  وولي الأمر وصلة القرابه (حقل نصي فعلي) ==================
                      _fieldCard(
                        icon: Icons.groups_2_rounded,
                        label: "اسم  ولي الأمر",
                        valueText: null,
                        placeholder: "",
                        customChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "اسم ولي الأمر ",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            TextField(
                              controller: studentParentNameController,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _kNavyLight,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                hintText: "اسم ولي الأمر ",
                                hintStyle: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 12.5,
                                  color: _kHint,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "اختر وسائل التواصل المناسبه",
              style: TextStyle(
                fontFamily: "cairo",
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilterChip(
                  label: const Text(
                    "الهاتف",
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: const Icon(Icons.phone_rounded, size: 18),
                  selected: conectWithPhone,
                  onSelected: (value) {
                    setState(() => conectWithPhone = value);
                  },
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.white,
                  selectedColor: _kIconBg,
                  side: BorderSide(
                    color: conectWithPhone ? _kNavy : _kCardBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                FilterChip(
                  label: const Text(
                    "واتساب",
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: const Icon(Icons.chat_rounded, size: 18),
                  selected: conectWithWhatsApp,
                  onSelected: (value) {
                    setState(() => conectWithWhatsApp = value);
                  },
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.white,
                  selectedColor: _kIconBg,
                  side: BorderSide(
                    color: conectWithWhatsApp ? _kNavy : _kCardBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ==================  رقم ولي امر الطالب==================
            _fieldCard(
              icon: Icons.groups_2_rounded,
              label: "رقم ولي امر الطالب",
              valueText: null,
              placeholder: "",
              customChild: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "رقم ولي امر الطالب",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: studentPhoneController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _kNavyLight,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "رقم ولي الأمر",
                      hintStyle: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12.5,
                        color: _kHint,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            // ================== زر الحفظ ==================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedGroups.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("اختر مجموعة واحدة على الأقل"),
                      ),
                    );
                    return;
                  }
                  if (studentNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل اسم الطالب")),
                    );
                    return;
                  }
                  if (studentPhoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل رقم الطالب")),
                    );
                    return;
                  }
                  if (studentParentNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل اسم ولي الأمر")),
                    );
                    return;
                  }
                  if (parentRelationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ادخل صلة ولي الأمر بالطالب  "),
                      ),
                    );
                    return;
                  }

                  await saveStudent();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حفظ الطالب بنجاح")),
                  );

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "حفظ الطالب",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.save_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
