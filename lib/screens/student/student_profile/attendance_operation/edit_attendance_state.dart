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

class EditAttendanceState extends StatefulWidget {
  final StudentModel student;
  final ActivityModel activity;

  const EditAttendanceState({
    super.key,
    required this.student,
    required this.activity,
  });

  @override
  State<EditAttendanceState> createState() => _EditAttendanceStateState();
}

class _EditAttendanceStateState extends State<EditAttendanceState> {
  bool? isPresent;
  late DateTime date;
  bool editDate = false;
  bool isLoading = false;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: widget.activity.note ?? '');
    date = DateTime.parse(widget.activity.date ?? DateTime.now().toString());
    isPresent = widget.activity.attendancePresent ?? true;
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> updateAttendance() async {
    final activityId = widget.activity.id;
    final studentId = widget.student.id;

    if (activityId == null ||
        activityId.isEmpty ||
        studentId == null ||
        studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: تعذر العثور على معرّف النشاط أو الطالب'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirestorePaths.studentActivities(studentId).doc(activityId).update({
        "date": date.toIso8601String(),
        "attendancePresent": isPresent ?? true,
        "note": noteController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات بنجاح'),
          backgroundColor: _kSuccess,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التحديث: $e'),
          backgroundColor: _kDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) setState(() => date = picked);
  }

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
          "تعديل الحضور",
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

            // ================== التاريخ ==================
            _cardShell(
              child: Row(
                children: [
                  Switch.adaptive(
                    value: editDate,
                    activeColor: _kPrimary,
                    onChanged: (value) => setState(() => editDate = value),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "تعديل التاريخ",
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
                          onTap: editDate ? pickDate : null,
                          child: Text(
                            "${date.day}/${date.month}/${date.year}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: editDate ? _kPrimary : _kHint,
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

            // ================== زر التحديث ==================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: _kPrimary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "تحديث الحضور",
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
