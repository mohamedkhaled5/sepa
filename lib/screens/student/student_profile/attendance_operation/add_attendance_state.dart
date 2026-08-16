import 'package:flutter/material.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/features/auth/firestore_path.dart';

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري ومريح للعين
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

class AddAttendanceState extends StatefulWidget {
  final StudentModel student;
  final String groupId;

  const AddAttendanceState({
    super.key,
    required this.student,
    required this.groupId,
  });

  @override
  State<AddAttendanceState> createState() => _AddAttendanceStateState();
}

class _AddAttendanceStateState extends State<AddAttendanceState> {
  @override
  void initState() {
    super.initState();
    date = DateTime.now();
  }

  TextEditingController noteController = TextEditingController();
  bool useCustomDate = false;
  late DateTime date;
  bool? isPresent = false;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2050),
    );

    if (picked != null) setState(() => date = picked);
  }

  Future<void> addAttendance() async {
    await FirestorePaths.studentActivities(widget.student.id!).add(
      ActivityModel(
        type: "attendance",
        date: date.toIso8601String(),
        groupId: widget.groupId,
        attendancePresent: isPresent == true,
        note: noteController.text,
      ).toMap(),
    );
  }

  // ================== بطاقة موحّدة للتصميم ==================
  Widget _cardShell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
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
      onSelected: (_) => setState(() => isPresent = present),
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
          "تسجيل حضور",
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
            // ================== ملاحظات ==================
            _cardShell(
              child: TextField(
                controller: noteController,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 14,
                  color: _kNavy,
                ),
                decoration: InputDecoration(
                  hintText: "إضافة ملاحظات حول الحضور...",
                  hintStyle: const TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13.5,
                    color: _kHint,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: _kPrimary,
                    size: 24,
                  ),
                ),
                maxLines: 2,
              ),
            ),

            // ================== اختيار تاريخ آخر ==================
            _cardShell(
              child: Row(
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
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _kPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: _kPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "حالة الطالب اليوم",
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
                  await addAttendance();
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: _kPrimary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "حفظ الحضور",
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
