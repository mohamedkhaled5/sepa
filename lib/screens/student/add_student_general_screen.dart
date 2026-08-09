import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/select_group_tree_widget.dart';

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kIconBg = Color(0xFFF1F5F9); // خلفية الأيقونات
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kWarning = Color(0xFFF59E0B); // تحذير كهرماني
const _kWarningBg = Color(0xFFFEF3C7); // خلفية التحذير الناعمة

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
      name: studentNameController.text.trim(),
      parentName: studentParentNameController.text.trim(),
      parentRelation: parentRelationController.text.trim(),
      phone: studentPhoneController.text.trim(),
      conectWithPhone: conectWithPhone,
      conectWithWhatsApp: conectWithWhatsApp,
    );

    await doc.set(student.toJson());
  }

  void _openAddGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
                                color: _kNavy,
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
                    color: _kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _kPrimary, size: 20),
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
        scrolledUnderElevation: 0,
        foregroundColor: _kNavy,
        title: const Text(
          "إنشاء طالب جديد",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _kNavy,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  "assets/icon/sapeel.png",
                  width: 28,
                  height: 28,
                ),
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
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Center(
                  child: Text(
                    "لم يتم اختيار أي مجموعة حتى الآن",
                    style: TextStyle(
                      fontFamily: "cairo",
                      color: _kHint,
                      fontSize: 13,
                    ),
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
                        fontSize: 12.5,
                        color: _kPrimary,
                      ),
                    ),
                    backgroundColor: _kPrimaryLight,
                    deleteIcon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _kPrimary,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onDeleted: () {
                      setState(() => selectedGroups.remove(g));
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _openAddGroupSheet,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: _kPrimary,
                  size: 20,
                ),
                label: const Text(
                  "إضافة مجموعة",
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _kPrimary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, color: _kCardBorder),
            ),

            // ================== اسم الطالب بالكامل ==================
            _fieldCard(
              icon: Icons.person_rounded,
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
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: studentNameController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "اسم الطالب بالكامل",
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

            // ================== اسم ولي الأمر ==================
            _fieldCard(
              icon: Icons.family_restroom_rounded,
              label: "اسم ولي الأمر",
              valueText: null,
              placeholder: "",
              customChild: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "اسم ولي الأمر",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: studentParentNameController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "اسم ولي الأمر بالكامل",
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

            // ================== صلة القرابة ==================
            _fieldCard(
              icon: Icons.people_alt_rounded,
              label: "صلة ولي الأمر بالطالب",
              valueText: null,
              placeholder: "",
              customChild: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "صلة ولي الأمر بالطالب",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: parentRelationController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "مثال: ألب، أم، عم...",
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

            // ================== رقم هاتف ولي الأمر ==================
            _fieldCard(
              icon: Icons.phone_iphone_rounded,
              label: "رقم ولي أمر الطالب",
              valueText: null,
              placeholder: "",
              customChild: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "رقم ولي أمر الطالب",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _kNavy,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "أدخل رقم الهاتف",
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

            const SizedBox(height: 8),

            const Text(
              "اختر وسائل التواصل المناسبة",
              style: TextStyle(
                fontFamily: "cairo",
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _kNavy,
              ),
            ),
            const SizedBox(height: 12),

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
                  avatar: Icon(
                    Icons.phone_rounded,
                    size: 18,
                    color: conectWithPhone ? _kPrimary : _kHint,
                  ),
                  selected: conectWithPhone,
                  onSelected: (value) {
                    setState(() => conectWithPhone = value);
                  },
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.white,
                  selectedColor: _kPrimaryLight,
                  side: BorderSide(
                    color: conectWithPhone ? _kPrimary : _kCardBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                  avatar: Icon(
                    Icons.chat_rounded,
                    size: 18,
                    color: conectWithWhatsApp ? _kPrimary : _kHint,
                  ),
                  selected: conectWithWhatsApp,
                  onSelected: (value) {
                    setState(() => conectWithWhatsApp = value);
                  },
                  showCheckmark: false,
                  elevation: 0,
                  pressElevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.white,
                  selectedColor: _kPrimaryLight,
                  side: BorderSide(
                    color: conectWithWhatsApp ? _kPrimary : _kCardBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================== زر الحفظ ==================
            SizedBox(
              width: double.infinity,
              height: 54,
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
                  if (studentNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل اسم الطالب")),
                    );
                    return;
                  }
                  if (studentPhoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل رقم الطالب")),
                    );
                    return;
                  }
                  if (studentParentNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل اسم ولي الأمر")),
                    );
                    return;
                  }
                  if (parentRelationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ادخل صلة ولي الأمر بالطالب"),
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
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "حفظ الطالب",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_rounded, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================== تنبيه مهم ==================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kWarningBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kWarning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'تنبيه: لا تنسَ إضافة المجموعات المخصصة للطالب قبل إتمام الحفظ لضمان ظهوره في قوائم الحضور والغياب بشكل صحيح.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12.5,
                        color: Colors.amber.shade900,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kWarning.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_rounded,
                      color: _kWarning,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
