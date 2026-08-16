import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/add_student_data.dart';
import 'package:seba/screens/student/edit_student/edit_student_screen.dart';
import 'package:seba/screens/student/student_profile/student_profile_screen.dart';

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري ومريح للعين
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة للأيقونات
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kDanger = Color(0xFFEF4444); // أحمر مرجاني
const _kDangerBg = Color(0xFFFEF2F2); // خلفية التنبيه الخفيفة
const _kSuccess = Color(0xFF10B981); // أخضر زمردي
const _kSuccessBg = Color(0xFFECFDF5); // خلفية الحضور الخفيفة
const _kWarning = Color(0xFFF59E0B); // تحذير كهرماني

class StudentDisplayScreen extends StatefulWidget {
  final String groupId;
  const StudentDisplayScreen({super.key, required this.groupId});

  @override
  State<StudentDisplayScreen> createState() => _StudentDisplayScreenState();
}

class _StudentDisplayScreenState extends State<StudentDisplayScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> studentsStream;

  bool _isSelectionMode = false;
  final Set<String> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();
    studentsStream = FirestorePaths.students
        .where("groupIds", arrayContains: widget.groupId)
        .snapshots();
  }

  bool _isSameDay(String? dateStr) {
    if (dateStr == null) return false;
    final parsed = DateTime.tryParse(dateStr)?.toLocal();
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  void _toggleSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
        if (_selectedStudentIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  Future<void> _deleteSelectedStudents() async {
    final String confirmationCode = (10000000 + Random().nextInt(90000000))
        .toString();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        bool isButtonEnabled = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _kDangerBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: _kDanger,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "تأكيد الحذف النهائي",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kNavy,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "هل أنت متأكد من حذف (${_selectedStudentIds.length}) من الطلاب المحددين؟\nسيتم حذف كافة البيانات والأنشطة المرتبطة بهم نهائياً.",
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13.5,
                      color: _kNavyLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kPrimaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "أدخل رمز التأكيد التالي لتأكيد الحذف:",
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 12,
                            color: _kHint,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          confirmationCode,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: "أدخل 8 أرقام هنا",
                      hintStyle: const TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 13,
                        letterSpacing: 0,
                        color: _kHint,
                      ),
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _kPrimary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        isButtonEnabled = (val.trim() == confirmationCode);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: isButtonEnabled
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text(
                    "حذف الكل",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _kPrimary)),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String studentId in _selectedStudentIds) {
        final activities = await FirestorePaths.studentActivities(
          studentId,
        ).get();
        for (var doc in activities.docs) {
          batch.delete(doc.reference);
        }
        batch.delete(FirestorePaths.students.doc(studentId));
      }

      await batch.commit();

      setState(() {
        _selectedStudentIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الحذف: $e")));
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> deleteStudent(String studentId) async {
    final activities = await FirestorePaths.studentActivities(studentId).get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in activities.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(FirestorePaths.students.doc(studentId));
    await batch.commit();
  }

  Future<void> addAttendance(StudentModel student, bool isPresent) async {
    await FirestorePaths.studentActivities(student.id!).add(
      ActivityModel(
        type: ActivityType.attendance.name,
        date: DateTime.now().toIso8601String(),
        groupId: widget.groupId,
        attendancePresent: isPresent,
      ).toMap(),
    );
  }

  Future<bool> hasDuplicateSubjectGroups(StudentModel student) async {
    if (student.groupIds.length < 2) return false;

    final groupsSnap = await FirestorePaths.groups
        .where(FieldPath.documentId, whereIn: student.groupIds)
        .get();

    final subjects = groupsSnap.docs
        .map((d) => d.data()['subject'] as String?)
        .where((s) => s != null)
        .toList();

    return subjects.toSet().length < subjects.length;
  }

  Future<void> _confirmDeleteStudent(StudentModel student) async {
    final randomNumber = (Random().nextInt(900) + 100).toString();
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _kDangerBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _kDanger,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "تحذير الحذف",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _kNavy,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "سيتم حذف الطالب وجميع سجلاته وبياناته نهائياً.\n"
                "اكتب الرقم التالي للتأكيد:",
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: _kNavyLight,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 15),
              SelectableText(
                randomNumber,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: _kDanger,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kCardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kDanger, width: 2),
                  ),
                  hintText: "اكتب الرقم هنا",
                  hintStyle: const TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13,
                    color: _kHint,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "إلغاء",
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: _kHint,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDanger,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (controller.text == randomNumber) {
                  Navigator.pop(context, true);
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text("الرقم غير صحيح")),
                  );
                }
              },
              child: const Text(
                "حذف",
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) await deleteStudent(student.id!);
  }

  // 🟢 عرض القائمة المنسدلة للطلاب مع إمكانية الانتقال لشاشة الطالب عند النقر
  void _showStudentsListBottomSheet({
    required String title,
    required List<StudentModel> studentsList,
    required Color headerColor,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${studentsList.length}",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: headerColor,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: _kCardBorder),
              if (studentsList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    "لا يوجد طلاب في هذه القائمة لليوم",
                    style: TextStyle(fontFamily: 'cairo', color: _kHint),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: studentsList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final student = studentsList[idx];
                      return Material(
                        color: _kPageBg,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentProfileScreen(
                                  student: student,
                                  initialGroupId: widget.groupId,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  student.phone ?? "",
                                  style: const TextStyle(
                                    fontFamily: 'cairo',
                                    fontSize: 12.5,
                                    color: _kNavyLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  student.name ?? "",
                                  style: const TextStyle(
                                    fontFamily: 'cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: _kNavy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: headerColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    headerColor == _kSuccess
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    size: 16,
                                    color: headerColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback? onPressed,
    Color background = _kPrimaryLight,
    Color foreground = _kPrimary,
    String? tooltip,
  }) {
    final button = Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: foreground, size: 20),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Widget _tinyTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'cairo',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kPrimary,
        ),
      ),
    );
  }

  Future<Map<String, List<StudentModel>>> _fetchTodayAttendanceStats(
    List<StudentModel> students,
  ) async {
    final List<StudentModel> present = [];
    final List<StudentModel> absent = [];

    for (var student in students) {
      if (student.id == null) continue;

      final snap = await FirestorePaths.studentActivities(student.id!)
          .where('groupId', isEqualTo: widget.groupId)
          .where('type', isEqualTo: ActivityType.attendance.name)
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        if (_isSameDay(data['date']?.toString())) {
          if (data['attendancePresent'] == true) {
            present.add(student);
          } else {
            absent.add(student);
          }
          break;
        }
      }
    }

    return {'present': present, 'absent': absent};
  }

  Widget _buildStudentsCountHeader(List<StudentModel> students) {
    return FutureBuilder<Map<String, List<StudentModel>>>(
      future: _fetchTodayAttendanceStats(students),
      builder: (context, snapshot) {
        final presentStudents = snapshot.data?['present'] ?? [];
        final absentStudents = snapshot.data?['absent'] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), _kPrimary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ملخص اليوم",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        "إحصائيات الطلاب",
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderStatItem(
                      title: "الإجمالي",
                      value: "${students.length}",
                      icon: Icons.people_alt_rounded,
                      color: Colors.white,
                      bgColor: Colors.white.withValues(alpha: 0.18),
                      onTap: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeaderStatItem(
                      title: "الحضور",
                      value: snapshot.connectionState == ConnectionState.waiting
                          ? "..."
                          : "${presentStudents.length}",
                      icon: Icons.check_circle_rounded,
                      color: _kSuccess,
                      bgColor: Colors.white,
                      onTap: () => _showStudentsListBottomSheet(
                        title: "قائمة الحضور اليوم",
                        studentsList: presentStudents,
                        headerColor: _kSuccess,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeaderStatItem(
                      title: "الغياب",
                      value: snapshot.connectionState == ConnectionState.waiting
                          ? "..."
                          : "${absentStudents.length}",
                      icon: Icons.cancel_rounded,
                      color: _kDanger,
                      bgColor: Colors.white,
                      onTap: () => _showStudentsListBottomSheet(
                        title: "قائمة الغياب اليوم",
                        studentsList: absentStudents,
                        headerColor: _kDanger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    final isWhiteBg = bgColor == Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isWhiteBg ? color : Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isWhiteBg ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student, int index) {
    final isSelected = _selectedStudentIds.contains(student.id);

    return FutureBuilder<bool>(
      future: hasDuplicateSubjectGroups(student),
      builder: (context, dupSnapshot) {
        final isDuplicate = dupSnapshot.data ?? false;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 250 + (index * 50).clamp(0, 500)),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimaryLight : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? _kPrimary : _kCardBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? _kPrimary.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(student.id!);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentProfileScreen(
                          student: student,
                          initialGroupId: widget.groupId,
                        ),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (!AppSession.hasPermission('deleteStudent')) return;
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedStudentIds.add(student.id!);
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (_isSelectionMode)
                            Checkbox(
                              value: isSelected,
                              activeColor: _kPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (_) => _toggleSelection(student.id!),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isDuplicate) ...[
                                      const Tooltip(
                                        message:
                                            "الطالب مسجل في أكثر من مجموعة لنفس المادة",
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: _kWarning,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(
                                        student.name ?? "",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontFamily: 'cairo',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _kNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  student.phone ?? "",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontFamily: 'cairo',
                                    fontSize: 13,
                                    color: _kNavyLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (student.conectWithPhone == true ||
                                    student.conectWithWhatsApp == true) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      if (student.conectWithPhone == true)
                                        _tinyTag("📞 اتصال"),
                                      if (student.conectWithWhatsApp == true)
                                        _tinyTag("🟢 واتساب"),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? _kPrimary : _kPrimaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: isSelected ? Colors.white : _kPrimary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      if (!_isSelectionMode) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: _kCardBorder),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (AppSession.hasPermission('editStudent'))
                              _circleAction(
                                icon: Icons.edit_rounded,
                                tooltip: "تعديل",
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditStudentScreen(
                                        groupId: widget.groupId,
                                        studentId: student.id!,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              const SizedBox(width: 40),
                            if (AppSession.hasPermission('deleteStudent'))
                              _circleAction(
                                icon: Icons.delete_rounded,
                                tooltip: "حذف",
                                background: _kDangerBg,
                                foreground: _kDanger,
                                onPressed: () => _confirmDeleteStudent(student),
                              )
                            else
                              const SizedBox(width: 40),
                            if (AppSession.hasPermission('attendance'))
                              _buildTodayAttendanceAction(student)
                            else
                              const SizedBox(width: 40),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAttendanceAction(StudentModel student) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.studentActivities(
        student.id!,
      ).where('groupId', isEqualTo: widget.groupId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 40, height: 40);
        }

        final todayDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          return _isSameDay(data['date']?.toString());
        }).toList();

        if (todayDocs.isEmpty) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _circleAction(
                icon: Icons.cancel_rounded,
                tooltip: "غائب",
                background: _kDangerBg,
                foreground: _kDanger,
                onPressed: () => addAttendance(student, false),
              ),
              const SizedBox(width: 12),
              _circleAction(
                icon: Icons.check_circle_rounded,
                tooltip: "حاضر",
                background: _kSuccessBg,
                foreground: _kSuccess,
                onPressed: () => addAttendance(student, true),
              ),
            ],
          );
        }

        Map<String, dynamic>? attendanceData;

        for (var doc in todayDocs) {
          if (doc.data()['type'] == ActivityType.attendance.name) {
            attendanceData = doc.data();
            break;
          }
        }

        bool isPresent = true;

        if (attendanceData != null) {
          isPresent = attendanceData['attendancePresent'] ?? false;
        }

        if (isPresent) {
          return Tooltip(
            message: "تم تسجيل الحضور اليوم",
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kSuccessBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _kSuccess,
                size: 24,
              ),
            ),
          );
        } else {
          return Tooltip(
            message: "تم تسجيل الغياب اليوم",
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kDangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: _kDanger,
                size: 24,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSelectionMode
              ? AppBar(
                  key: const ValueKey('selection_appbar'),
                  backgroundColor: _kNavy,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedStudentIds.clear();
                      });
                    },
                  ),
                  title: Text(
                    "تم تحديد ${_selectedStudentIds.length}",
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.select_all_rounded,
                        color: Colors.white,
                      ),
                      tooltip: "تحديد الكل",
                      onPressed: () async {
                        final snapshot = await FirestorePaths.students
                            .where("groupIds", arrayContains: widget.groupId)
                            .get();
                        final allIds = snapshot.docs.map((d) => d.id).toList();

                        setState(() {
                          if (_selectedStudentIds.length == allIds.length) {
                            _selectedStudentIds.clear();
                          } else {
                            _selectedStudentIds.addAll(allIds);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      tooltip: "حذف المحددين",
                      onPressed: _selectedStudentIds.isEmpty
                          ? null
                          : () => _deleteSelectedStudents(),
                    ),
                  ],
                )
              : AppBar(
                  key: const ValueKey('normal_appbar'),
                  backgroundColor: _kPageBg,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  foregroundColor: _kNavy,
                  centerTitle: false,
                  title: const Text(
                    "الطلاب",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: _kNavy,
                    ),
                  ),
                ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: studentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "حدث خطأ في جلب الطلاب",
                style: TextStyle(fontFamily: 'cairo', color: _kDanger),
              ),
            );
          }

          final studentDocs = snapshot.data!.docs;

          if (studentDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: _kPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off_rounded,
                      color: _kPrimary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "لا يوجد طلاب في هذه المجموعة بعد\nاضغط على الزر لإضافة طالب جديد",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          final students = studentDocs
              .map((doc) => StudentModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: students.length + 1,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStudentsCountHeader(students);
              }

              final student = students[index - 1];
              return _buildStudentCard(student, index - 1);
            },
          );
        },
      ),
      floatingActionButton: AppSession.hasPermission('createStudent')
          ? FloatingActionButton.extended(
              backgroundColor: _kPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStudentData(groupId: widget.groupId),
                  ),
                );
              },
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: const Text(
                "طالب جديد",
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }
}
