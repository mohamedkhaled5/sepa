import 'package:flutter/material.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/features/auth/firestore_path.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kSuccess = Color(0xFF2E9E6B);
const _kSuccessBg = Color(0xFFE4F5EC);
const _kDanger = Color(0xFFD1483F);
const _kDangerBg = Color(0xFFFBE9E7);

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

  Widget _statusChip({required bool present}) {
    final selected = isPresent == present;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: present ? _kSuccess : _kDanger,
          ),
          const SizedBox(width: 6),
          Text(
            present ? "حاضر" : "غائب",
            style: const TextStyle(
              fontFamily: "cairo",
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      selectedColor: present ? _kSuccessBg : _kDangerBg,
      side: BorderSide(
        color: selected ? (present ? _kSuccess : _kDanger) : _kCardBorder,
        width: 1.2,
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
        foregroundColor: _kNavy,
        centerTitle: false,
        title: const Text(
          "إضافة اختبار",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: examNameController,
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
                      hintText: "اكتب اسم الاختبار",
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

            // ================== اختيار تاريخ آخر ==================
            _fieldCard(
              icon: Icons.calendar_today_rounded,
              label: "تاريخ الاختبار",
              customChild: Row(
                children: [
                  Switch(
                    value: useCustomDate,
                    activeThumbColor: _kNavy,
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
                            fontSize: 14,
                            color: Colors.black87,
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: useCustomDate ? _kNavy : _kHint,
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
                            color: Colors.black87,
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
                            fontSize: 12.5,
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
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextField(
                          controller: maxDegreeController,
                          keyboardType: TextInputType.number,
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
                            hintText: "النهائية",
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

            const SizedBox(height: 6),
            const Text(
              "حالة الطالب",
              style: TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statusChip(present: true),
                _statusChip(present: false),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
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
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
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
                    Icon(Icons.save_rounded, size: 20),
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
