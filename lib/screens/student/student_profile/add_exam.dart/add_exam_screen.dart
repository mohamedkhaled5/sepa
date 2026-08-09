import 'package:flutter/material.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/features/auth/firestore_path.dart';

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة للأيقونات
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kSuccess = Color(0xFF10B981); // أخضر زمردي
const _kSuccessBg = Color(0xFFECFDF5); // خلفية الحضور الخفيفة
const _kDanger = Color(0xFFEF4444); // أحمر مرجاني
const _kDangerBg = Color(0xFFFEF2F2); // خلفية التنبيه الخفيفة

class AddExamScreen extends StatefulWidget {
  final StudentModel student;
  final String groupId;

  const AddExamScreen({
    super.key,
    required this.student,
    required this.groupId,
  });

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  @override
  void initState() {
    super.initState();
    date = DateTime.now();
  }

  bool useCustomDate = false;
  late DateTime date;
  bool? isPresent = false;
  final currentDegreeController = TextEditingController();
  final maxDegreeController = TextEditingController();
  final examNameController = TextEditingController();

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) setState(() => date = picked);
  }

  Future<void> addExam() async {
    await FirestorePaths.studentActivities(widget.student.id!).add(
      ActivityModel(
        type: "exam",
        date: date.toIso8601String(),
        groupId: widget.groupId,
        attendancePresent: isPresent,
        examName: examNameController.text.trim(),
        examStatus: isPresent == true ? "حاضر" : "غائب",
        currentDegree: currentDegreeController.text,
        maxDegree: maxDegreeController.text,
      ).toMap(),
    );
  }

  @override
  void dispose() {
    examNameController.dispose();
    currentDegreeController.dispose();
    maxDegreeController.dispose();
    super.dispose();
  }

  // ================== عنصر البطاقة العام لكل حقل ==================
  Widget _fieldCard({
    required IconData icon,
    required String label,
    String? valueText,
    String placeholder = "",
    Widget? customChild,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                fontSize: 14.5,
                                color: _kNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              valueText ?? placeholder,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 13,
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
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _kPrimary, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip({required bool present}) {
    final selected = isPresent == present;
    final color = present ? _kSuccess : _kDanger;
    final bgColor = present ? _kSuccessBg : _kDangerBg;

    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              present ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 20,
              color: selected ? color : _kHint,
            ),
            const SizedBox(width: 8),
            Text(
              present ? "حاضر" : "غائب",
              style: TextStyle(
                fontFamily: "cairo",
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected ? color : _kNavyLight,
              ),
            ),
          ],
        ),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          isPresent = present;
          if (!present) {
            currentDegreeController.text = "0";
          } else {
            currentDegreeController.clear();
          }
        });
      },
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: Colors.white,
      selectedColor: bgColor,
      side: BorderSide(
        color: selected ? color : _kCardBorder,
        width: selected ? 1.8 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        centerTitle: false,
        title: const Text(
          "إضافة اختبار",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: _kNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================== اسم الاختبار ==================
            _fieldCard(
              icon: Icons.assignment_rounded,
              label: "اسم الاختبار",
              customChild: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "اسم الاختبار",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: examNameController,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kNavyLight,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "اكتب اسم الاختبار",
                      hintStyle: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 13,
                        color: _kHint,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================== اختيار تاريخ آخر ==================
            _fieldCard(
              icon: Icons.calendar_today_rounded,
              label: "تاريخ الاختبار",
              customChild: Row(
                children: [
                  Switch.adaptive(
                    value: useCustomDate,
                    activeColor: _kPrimary,
                    onChanged: (value) async {
                      setState(() => useCustomDate = value);
                      if (value) {
                        await pickDate();
                      } else {
                        setState(() => date = DateTime.now());
                      }
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "اختيار تاريخ آخر",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: _kNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: useCustomDate ? pickDate : null,
                          child: Text(
                            "${date.day}/${date.month}/${date.year}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: useCustomDate ? _kPrimary : _kHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================== الدرجات (جنب بعض) ==================
            Row(
              children: [
                Expanded(
                  child: _fieldCard(
                    icon: Icons.grade_rounded,
                    label: "درجة الطالب",
                    customChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "درجة الطالب",
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
                          controller: currentDegreeController,
                          keyboardType: TextInputType.number,
                          enabled: isPresent == true,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kNavyLight,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: "الدرجة",
                            hintStyle: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 13,
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
                  child: _fieldCard(
                    icon: Icons.star_rounded,
                    label: "الدرجة النهائية",
                    customChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "الدرجة النهائية",
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
                          controller: maxDegreeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kNavyLight,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: "النهائية",
                            hintStyle: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 13,
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

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "حالة الطالب",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _kNavy,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statusChip(present: true)),
                const SizedBox(width: 12),
                Expanded(child: _statusChip(present: false)),
              ],
            ),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  if (examNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("أدخل اسم الاختبار")),
                    );
                    return;
                  }
                  if (maxDegreeController.text.isEmpty) return;
                  if (isPresent == true &&
                      currentDegreeController.text.isEmpty) {
                    return;
                  }

                  await addExam();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: _kPrimary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "حفظ الاختبار",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.save_rounded, size: 22),
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
