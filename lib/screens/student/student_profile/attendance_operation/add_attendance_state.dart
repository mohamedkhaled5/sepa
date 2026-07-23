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

  bool useCustomDate = false;
  late DateTime date;
  bool? isPresent = false;

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
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
      ).toMap(),
    );
  }

  // ================== بطاقة موحّدة (تعريف اسم الحقل + أيقونة) ==================
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
          "تسجيل حضور",
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
            // ================== اختيار تاريخ آخر ==================
            _cardShell(
              child: Row(
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
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  await addAttendance();
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
                      "حفظ الحضور",
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
