import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:seba/features/assistant/app_session.dart';

import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/report/report_data_service.dart';
import 'package:seba/screens/report/student_report_pdf_builder.dart';
import 'package:seba/screens/report/student_report_screen.dart';
import 'package:seba/screens/student/student_profile/add_exam.dart/add_exam_screen.dart';
import 'package:seba/screens/student/student_profile/add_exam.dart/edit_exam_screen.dart';
import 'package:seba/screens/student/student_profile/attendance_operation/add_attendance_state.dart';
import 'package:seba/screens/student/student_profile/attendance_operation/edit_attendance_state.dart';

import 'package:seba/features/auth/firestore_path.dart';
import 'package:intl/intl.dart';

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
  bool _isGeneratingReport = false;
  bool _isDeleting = false;

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
      setState(() {
        _loading = false;
      });
      _tabController!.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> deleteAttendance(String studentId, String activityId) async {
    if (_isDeleting) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text(
            "هل أنت متأكد من حذف هذا السجل؟ لا يمكن التراجع بعد الحذف.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("حذف", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirestorePaths.studentActivities(
        studentId,
      ).doc(activityId).delete();
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  double _examPercent(ActivityModel activity) {
    final current =
        double.tryParse(activity.currentDegree?.toString() ?? "0") ?? 0;

    final max = double.tryParse(activity.maxDegree?.toString() ?? "1") ?? 1;

    if (max <= 0) return 0;

    return (current / max).clamp(0.0, 1.0);
  }

  Color _examProgressColor(double percent) {
    if (percent >= 0.999) return Colors.green;
    if (percent >= 0.8) return Colors.lightBlue;
    if (percent >= 0.6) return Colors.amber;
    if (percent >= 0.5) return Colors.orange;
    return Colors.red;
  }

  // ================== إنشاء التقرير الشامل ==================
  Future<void> _generateReport() async {
    setState(() => _isGeneratingReport = true);

    try {
      final data = await ReportDataService().buildReportForStudent(
        widget.student,
      );
      final pdfDoc = await StudentReportPdfBuilder.build(data);

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (format) => pdfDoc.save(),
        name: 'تقرير_${widget.student.name ?? 'طالب'}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر إنشاء التقرير: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  String _groupLabel(String groupId) {
    final group = _groupsById[groupId];
    if (group == null) return groupId;
    return "${group.subject ?? ''} - ${group.grade ?? ''}";
  }

  String? get _currentGroupId {
    final groupIds = widget.student.groupIds;
    if (groupIds.isEmpty || _tabController == null) return null;
    return groupIds[_tabController!.index];
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
                    Icons.inbox_rounded,
                    color: _kNavy,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "لا توجد سجلات بعد لهذه المجموعة",
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final activity = ActivityModel.fromFirestore(docs[index]);
            return _buildActivityCard(activity);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final isAttendance = activity.type == "attendance";
    final isPresent = isAttendance
        ? (activity.attendancePresent == true)
        : (activity.examStatus == "حاضر");
    final borderColor = isPresent ? _kSuccess : _kDanger;
    final statusColor = isPresent ? _kSuccess : _kDanger;
    final statusBg = isPresent ? _kSuccessBg : _kDangerBg;
    final percent = _examPercent(activity);
    final progressColor = _examProgressColor(percent);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16213E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // إجراءات (تعديل/حذف)
          Column(
            children: [
              _circleAction(
                icon: Icons.edit_rounded,
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
              const SizedBox(height: 8),
              _circleAction(
                icon: _isDeleting ? Icons.hourglass_top : Icons.delete_rounded,
                background: _kDangerBg,
                foreground: _kDanger,
                onPressed: _isDeleting
                    ? () {}
                    : () => deleteAttendance(
                        widget.student.id ?? '',
                        activity.id ?? '',
                      ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isAttendance) ...[
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: _kIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.quiz_rounded,
                          color: _kNavy,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        isAttendance ? "الحضور" : (activity.examName ?? ""),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'dd-MMM-yyyy',
                    'ar',
                  ).format(DateTime.parse(activity.date ?? '')),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 11.5,
                    color: _kHint,
                  ),
                ),
                const SizedBox(height: 8),
                if (isAttendance)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      isPresent ? "حاضر" : "غائب",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Wrap(
                        spacing: 6,
                        alignment: WrapAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kIconBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${activity.currentDegree} / ${activity.maxDegree}",
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                color: _kNavy,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor,
                                width: 1.4,
                              ),
                            ),
                            child: Text(
                              activity.examStatus ?? "",
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color background = _kIconBg,
    Color foreground = _kNavy,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: foreground, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kPageBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final groupIds = widget.student.groupIds;
    final reportButton = AppSession.hasPermission('reports')
        ? Padding(
            padding: const EdgeInsets.only(left: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: _isGeneratingReport ? null : _generateReport,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: _isGeneratingReport
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kNavy,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: _kNavy,
                        size: 20,
                      ),
              ),
            ),
          )
        : const SizedBox.shrink();

    if (groupIds.isEmpty) {
      return Scaffold(
        backgroundColor: _kPageBg,
        appBar: AppBar(
          backgroundColor: _kPageBg,
          elevation: 0,
          foregroundColor: _kNavy,
          centerTitle: false,
          title: Text(
            widget.student.name ?? '',
            style: const TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              color: _kNavy,
            ),
          ),
          actions: [reportButton],
        ),
        body: Center(
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
                  Icons.groups_2_rounded,
                  color: _kNavy,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "الطالب غير مسجل في أي مجموعة حاليًا",
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: _kHint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        foregroundColor: _kNavy,
        centerTitle: false,
        title: Text(
          widget.student.name ?? '',
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
        actions: [reportButton],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kCardBorder),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: _kNavy,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _kNavyLight,
              labelStyle: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 12.5,
              ),
              dividerColor: Colors.transparent,
              tabs: groupIds.map((gid) => Tab(text: _groupLabel(gid))).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: groupIds
            .map((gid) => _buildActivitiesListForGroup(gid))
            .toList(),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (AppSession.hasPermission('attendance')) ...[
            FloatingActionButton(
              heroTag: "addAttendance",
              tooltip: "إضافة حضور",
              backgroundColor: Colors.white,
              foregroundColor: _kNavy,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: _kCardBorder),
              ),
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
              child: const Icon(Icons.event_available_rounded),
            ),
            const SizedBox(width: 12),
          ],
          if (AppSession.hasPermission('exams'))
            FloatingActionButton(
              heroTag: "addExam",
              tooltip: "إضافة امتحان",
              backgroundColor: _kNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onPressed: () {
                final gid = _currentGroupId;
                if (gid == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddExamScreen(student: widget.student, groupId: gid),
                  ),
                );
              },
              child: const Icon(Icons.assignment_rounded, color: Colors.white),
            ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: "viewReport",
            tooltip: " عرض شاشة التقرير",
            backgroundColor: _kNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentReportScreen(student: widget.student),
                ),
              );
            },
            child: const Icon(Icons.print_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
