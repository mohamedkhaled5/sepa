import 'package:flutter/material.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/features/auth/firestore_path.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kSuccess = Color(0xFF2E9E6B);
const _kSuccessBg = Color(0xFFE4F5EC);
const _kDanger = Color(0xFFD1483F);
const _kDangerBg = Color(0xFFFBE9E7);

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
  bool isLoading = false; // 💡 حالة التحميل لمنع التكرار
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: widget.activity.note ?? '');
    date = DateTime.parse(widget.activity.date ?? DateTime.now().toString());
    isPresent =
        widget.activity.attendancePresent ??
        true; // 💡 قيمة افتراضية لتفادي الـ Null
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> updateAttendance() async {
    final activityId = widget.activity.id;
    final studentId = widget.student.id;

    // 💡 التحقق من وجود المعرفات قبل الاتصال بالفايربيس
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

      Navigator.pop(context, true); // 💡 إرجاع true لتأكيد التحديث
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: child,
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
      onSelected: (_) => setState(() => isPresent = present),
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
          "تعديل الحضور",
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
            // ================== ملاحظات ==================
            _cardShell(
              child: TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: "إضافة ملاحظات",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            // ================== التاريخ ==================
            _cardShell(
              child: Row(
                children: [
                  Switch(
                    value: editDate,
                    activeThumbColor: _kNavy,
                    onChanged: (value) => setState(() => editDate = value),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 14),
                        const Text(
                          "تعديل التاريخ",
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
                          onTap: editDate ? pickDate : null,
                          child: Text(
                            "${date.day}/${date.month}/${date.year}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: editDate ? _kNavy : _kHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: _kNavy,
                      size: 20,
                    ),
                  ),
                ],
              ),
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

            // ================== زر التحديث ==================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
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
