import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/add_student_data.dart';
import 'package:seba/screens/student/edit_student/edit_student_screen.dart';
import 'package:seba/screens/student/student_profile/student_profile_screen.dart';
import 'dart:math';

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

  @override
  void initState() {
    super.initState();
    studentsStream = FirestorePaths.students
        .where("groupIds", arrayContains: widget.groupId)
        .snapshots();
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

  Widget _buildStudentCard(StudentModel student) {
    return FutureBuilder<bool>(
      future: hasDuplicateSubjectGroups(student),
      builder: (context, dupSnapshot) {
        final isDuplicate = dupSnapshot.data ?? false;

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
              onTap: () {
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
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
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
                        if (AppSession.hasPermission('attendance')) ...[
                          _circleAction(
                            icon: Icons.cancel_rounded,
                            tooltip: "غائب",
                            background: _kDangerBg,
                            foreground: _kDanger,
                            onPressed: () => addAttendance(student, false),
                          ),
                          _circleAction(
                            icon: Icons.check_circle_rounded,
                            tooltip: "حاضر",
                            background: _kSuccessBg,
                            foreground: _kSuccess,
                            onPressed: () => addAttendance(student, true),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
            return const Center(child: Text("حدث خطأ"));
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = StudentModel.fromFirestore(students[index]);
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
