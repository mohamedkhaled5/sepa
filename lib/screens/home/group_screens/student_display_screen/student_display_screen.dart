import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/Activity_model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/add_student/add_student_data.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/screens/edit_student/edit_student_screen.dart';
import 'package:seba/screens/student_profile/student_profile_screen.dart';
import 'dart:math';

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

  /// يتحقق هل الطالب منضم لأكتر من مجموعة بنفس المادة (تسجيل مكرر).
  Future<bool> hasDuplicateSubjectGroups(StudentModel student) async {
    if (student.groupIds.length < 2) return false;

    final groupsSnap = await FirestorePaths.groups
        .where(FieldPath.documentId, whereIn: student.groupIds)
        .get();

    final subjects = groupsSnap.docs
        .map((d) => d.data()['subject'] as String?)
        .where((s) => s != null)
        .toList();

    final uniqueSubjects = subjects.toSet();
    return uniqueSubjects.length < subjects.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الطلاب"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: studentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("حدث خطأ"));
            }

            var students = snapshot.data!.docs;

            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                StudentModel student = StudentModel.fromFirestore(
                  students[index],
                );

                return FutureBuilder<bool>(
                  future: hasDuplicateSubjectGroups(student),
                  builder: (context, dupSnapshot) {
                    final isDuplicate = dupSnapshot.data ?? false;

                    return ListTile(
                      title: Row(
                        children: [
                          Flexible(child: Text(student.name ?? "")),
                          if (isDuplicate) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message:
                                  "الطالب مسجل في أكثر من مجموعة لنفس المادة",
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(student.phone ?? ""),
                          const SizedBox(height: 10),
                          if (student.conectWithPhone == true)
                            const Text("📞 اتصال"),
                          const SizedBox(height: 10),
                          if (student.conectWithWhatsApp == true)
                            const Text("🟢 WhatsApp"),

                          // تسجيل الحضور/الغياب متاح دايمًا للمساعد (من أساسيات
                          // دوره)، أما التعديل والحذف فمقيّدين بالصلاحيات.
                          Wrap(
                            spacing: 4,
                            children: [
                              if (AppSession.hasPermission('attendance')) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    addAttendance(student, true);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    addAttendance(student, false);
                                  },
                                ),
                              ],
                              if (AppSession.hasPermission('deleteStudent'))
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final randomNumber =
                                        (Random().nextInt(900) + 100)
                                            .toString();

                                    final controller = TextEditingController();
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text("⚠️ تحذير"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "سيتم حذف الطالب وجميع سجلاته وبياناته نهائياً.\n"
                                                "اكتب الرقم التالي للتأكيد:",
                                              ),
                                              const SizedBox(height: 15),
                                              Text(
                                                randomNumber,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(height: 15),
                                              TextField(
                                                controller: controller,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      hintText:
                                                          "اكتب الرقم هنا",
                                                    ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text("إلغاء"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                if (controller.text ==
                                                    randomNumber) {
                                                  Navigator.pop(context, true);
                                                } else {
                                                  messenger.showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "الرقم غير صحيح",
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text("حذف"),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      await deleteStudent(student.id!);
                                    }
                                  },
                                ),
                              if (AppSession.hasPermission('editStudent'))
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditStudentScreen(student: student),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
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
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      // زر إضافة طالب جديد يظهر بس لو عند المستخدم صلاحية إنشاء طالب.
      floatingActionButton: AppSession.hasPermission('createStudent')
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddStudentData(groupId: widget.groupId),
                  ),
                );
              },
              child: const Text("+", style: TextStyle(fontSize: 24)),
            )
          : null,
    );
  }
}
