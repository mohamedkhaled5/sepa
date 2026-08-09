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

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kDanger = Color(0xFFD1483F);
const _kDangerBg = Color(0xFFFBE9E7);
const _kSuccess = Color(0xFF2E9E6B);
const _kSuccessBg = Color(0xFFE4F5EC);
const _kWarning = Color(0xFFC98A2C);

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
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "⚠️ تأكيد الحذف النهائي",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  color: _kDanger,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "هل أنت متأكد من حذف (${_selectedStudentIds.length}) من الطلاب المحددين؟\nسيتم حذف كافة البيانات والأنشطة المرتبطة بهم نهائياً.",
                    style: const TextStyle(fontFamily: 'cairo', fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "أدخل رمز التأكيد التالي لتأكيد الحذف:",
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          confirmationCode,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: _kNavy,
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
                      ),
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kNavy, width: 2),
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
                    style: TextStyle(fontFamily: 'cairo'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: isButtonEnabled
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text(
                    "حذف الكل",
                    style: TextStyle(fontFamily: 'cairo', color: Colors.white),
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "⚠️ تحذير",
            style: TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "سيتم حذف الطالب وجميع سجلاته وبياناته نهائياً.\n"
                "اكتب الرقم التالي للتأكيد:",
                style: TextStyle(fontFamily: 'cairo'),
              ),
              const SizedBox(height: 15),
              Text(
                randomNumber,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _kDanger,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "اكتب الرقم هنا",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء", style: TextStyle(fontFamily: 'cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kDanger),
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
                style: TextStyle(fontFamily: 'cairo', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) await deleteStudent(student.id!);
  }

  // 🟢 عرض القائمة المنسدلة للطلاب مع إمكانية الانقال لشاشة الطالب عند النقر
  void _showStudentsListBottomSheet({
    required String title,
    required List<StudentModel> studentsList,
    required Color headerColor,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: headerColor.withOpacity(0.15),
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
              const Divider(height: 24),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final student = studentsList[idx];
                      return Material(
                        color: _kPageBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(ctx); // إغلاق القائمة السفلية
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
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  student.phone ?? "",
                                  style: const TextStyle(
                                    fontFamily: 'cairo',
                                    fontSize: 12,
                                    color: _kNavyLight,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  student.name ?? "",
                                  style: const TextStyle(
                                    fontFamily: 'cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _kNavy,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: headerColor.withOpacity(0.2),
                                  child: Icon(
                                    headerColor == _kSuccess
                                        ? Icons.check
                                        : Icons.close,
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
    Color background = _kIconBg,
    Color foreground = _kNavy,
    String? tooltip,
  }) {
    final button = Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: foreground, size: 19),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Widget _tinyTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'cairo', fontSize: 10.5),
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
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kNavy, _kNavyLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kNavy.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                  Row(
                    children: const [
                      Text(
                        "إحصائيات الطلاب",
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 20,
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
                      bgColor: Colors.white.withOpacity(0.15),
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
                      bgColor: _kSuccessBg,
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
                      bgColor: _kDangerBg,
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
    final isWhite = color == Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
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
                      color: isWhite ? Colors.white70 : color,
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
                  color: isWhite ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    final isSelected = _selectedStudentIds.contains(student.id);

    return FutureBuilder<bool>(
      future: hasDuplicateSubjectGroups(student),
      builder: (context, dupSnapshot) {
        final isDuplicate = dupSnapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _kNavy : _kCardBorder,
              width: isSelected ? 2 : 1,
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (_isSelectionMode)
                          Checkbox(
                            value: isSelected,
                            activeColor: _kNavy,
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
                                        size: 16,
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
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.phone ?? "",
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 12.5,
                                  color: _kNavyLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (student.conectWithPhone == true ||
                                  student.conectWithWhatsApp == true) ...[
                                const SizedBox(height: 6),
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
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: _kIconBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: _kNavy,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (!_isSelectionMode) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: _kCardBorder),
                      const SizedBox(height: 8),
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
                                    builder: (_) =>
                                        EditStudentScreen(student: student),
                                  ),
                                );
                              },
                            )
                          else
                            const SizedBox(width: 38),
                          if (AppSession.hasPermission('deleteStudent'))
                            _circleAction(
                              icon: Icons.delete_rounded,
                              tooltip: "حذف",
                              background: _kDangerBg,
                              foreground: _kDanger,
                              onPressed: () => _confirmDeleteStudent(student),
                            )
                          else
                            const SizedBox(width: 38),
                          if (AppSession.hasPermission('attendance'))
                            _buildTodayAttendanceAction(student)
                          else
                            const SizedBox(width: 38),
                        ],
                      ),
                    ],
                  ],
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
          return const SizedBox(width: 38, height: 38);
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
              const SizedBox(width: 20),
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
              width: 38,
              height: 38,
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
              width: 38,
              height: 38,
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
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: _kNavy,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
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
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.white),
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
                    Icons.delete_forever,
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
              backgroundColor: _kPageBg,
              elevation: 0,
              foregroundColor: _kNavy,
              centerTitle: false,
              title: const Text(
                "الطلاب",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  color: _kNavy,
                ),
              ),
            ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: studentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ في جلب الطلاب"));
          }

          final studentDocs = snapshot.data!.docs;

          if (studentDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off_rounded,
                      color: _kNavy,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "لا يوجد طلاب في هذه المجموعة بعد",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontSize: 13,
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
              return _buildStudentCard(student);
            },
          );
        },
      ),
      floatingActionButton: AppSession.hasPermission('createStudent')
          ? FloatingActionButton.extended(
              backgroundColor: _kNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
              ),
              label: const Text(
                "طالب جديد",
                style: TextStyle(fontFamily: 'cairo', color: Colors.white),
              ),
            )
          : null,
    );
  }
}
