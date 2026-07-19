import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/model/Activity_model/activity_model_type.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student_profile/add_exam.dart/add_exam_screen.dart';
import 'package:seba/screens/student_profile/add_exam.dart/edit_exam_screen.dart';
import 'package:seba/screens/student_profile/attendance_operation/add_attendance_state.dart';
import 'package:seba/screens/student_profile/attendance_operation/edit_attendance_state.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:intl/intl.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.student,
    this.initialGroupId,
  });

  final StudentModel student;
  final String? initialGroupId;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  Map<String, GroupModel> _groupsById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupsAndSetupTabs();
  }

  Future<void> _loadGroupsAndSetupTabs() async {
    final groupIds = widget.student.groupIds;

    if (groupIds.isNotEmpty) {
      final snap = await FirestorePaths.groups
          .where(FieldPath.documentId, whereIn: groupIds)
          .get();

      _groupsById = {
        for (final doc in snap.docs) doc.id: GroupModel.fromFirestore(doc),
      };
    }

    final initialIndex = widget.initialGroupId != null
        ? groupIds.indexOf(widget.initialGroupId!).clamp(0, groupIds.length - 1)
        : 0;

    _tabController = TabController(
      length: groupIds.length,
      vsync: this,
      initialIndex: groupIds.isEmpty ? 0 : initialIndex,
    );

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> deleteAttendance(String studentId, String activityId) async {
    await FirestorePaths.studentActivities(studentId).doc(activityId).delete();
  }

  String _groupLabel(String groupId) {
    final group = _groupsById[groupId];
    if (group == null) return groupId;
    return "${group.subject ?? ''} - ${group.grade ?? ''}";
  }

  Widget _buildActivitiesListForGroup(String groupId) {
    final activitiesStream =
        FirestorePaths.studentActivities(widget.student.id!)
            .where('groupId', isEqualTo: groupId)
            .orderBy('date', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: activitiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("لا توجد سجلات بعد لهذه المجموعة"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final activity = ActivityModel.fromFirestore(docs[index]);

            return ListTile(
              title: Text(
                DateFormat(
                  'dd-MMM-yyyy',
                  'ar',
                ).format(DateTime.parse(activity.date ?? '')),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.type == "attendance"
                        ? "الحضور"
                        : activity.examName ?? "",
                  ),
                  Text(
                    activity.type == "attendance"
                        ? (activity.attendancePresent == true
                              ? "حاضر✔"
                              : "غائب ❌")
                        : "${activity.examStatus} | الدرجة: ${activity.currentDegree} من ${activity.maxDegree}",
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: () {
                  deleteAttendance(widget.student.id ?? '', activity.id ?? '');
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.edit),
                color: Colors.blue,
                onPressed: () {
                  if (activity.type == "attendance") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditAttendanceState(
                          student: widget.student,
                          activity: activity,
                        ),
                      ),
                    );
                  } else if (activity.type == "exam") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditExamScreen(
                          student: widget.student,
                          activity: activity,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  String? get _currentGroupId {
    final groupIds = widget.student.groupIds;
    if (groupIds.isEmpty || _tabController == null) return null;
    return groupIds[_tabController!.index];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final groupIds = widget.student.groupIds;

    if (groupIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('ملف الطالب - ${widget.student.name}')),
        body: const Center(child: Text("الطالب غير مسجل في أي مجموعة حاليًا")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ملف الطالب - ${widget.student.name}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: groupIds.map((gid) => Tab(text: _groupLabel(gid))).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.small(
                  heroTag: "addAttendance",
                  tooltip: "إضافة حضور",
                  onPressed: () {
                    final gid = _currentGroupId;
                    if (gid == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddAttendanceState(
                          student: widget.student,
                          groupId: gid,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 20),
                FloatingActionButton.small(
                  heroTag: "addExam",
                  tooltip: "إضافة امتحان",
                  onPressed: () {
                    final gid = _currentGroupId;
                    if (gid == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddExamScreen(
                          student: widget.student,
                          groupId: gid,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.book),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: groupIds
                  .map((gid) => _buildActivitiesListForGroup(gid))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
