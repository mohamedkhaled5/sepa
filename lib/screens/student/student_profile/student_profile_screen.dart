import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/firestore_path.dart';
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

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kIconBg = Color(0xFFF1F5F9); // خلفية الأيقونات
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kSuccess = Color(0xFF10B981); // أخضر زمردي
const _kSuccessBg = Color(0xFFECFDF5); // خلفية الحضور الخفيفة
const _kDanger = Color(0xFFEF4444); // أحمر مرجاني
const _kDangerBg = Color(0xFFFEF2F2); // خلفية التنبيه الخفيفة
const _kWarning = Color(0xFFF59E0B); // تحذير كهرماني

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

  // متغيرات التحديد المتعدد لسجلات الحضور والغياب
  bool _isSelectionMode = false;
  final Set<String> _selectedAttendanceIds = {};

  void _toggleAttendanceSelection(String activityId) {
    setState(() {
      if (_selectedAttendanceIds.contains(activityId)) {
        _selectedAttendanceIds.remove(activityId);
        if (_selectedAttendanceIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAttendanceIds.add(activityId);
      }
    });
  }

  // 🟢 دالة الحذف الجماعي لسجلات الحضور والغياب المحددة مع ميزة حماية الأرقام
  Future<void> _deleteSelectedAttendances() async {
    if (_selectedAttendanceIds.isEmpty) return;

    final String securityCode =
        (10000 + (DateTime.now().microsecondsSinceEpoch % 90000)).toString();
    final TextEditingController codeController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isCodeValid = codeController.text.trim() == securityCode;

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
                    "هل أنت متأكد من حذف (${_selectedAttendanceIds.length}) من سجلات الحضور والغياب المحددة؟\nلا يمكن التراجع عن هذا الإجراء.",
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
                      color: _kDangerBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _kDanger.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "أدخل رمز الحماية للتأكيد:",
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 12,
                            color: _kDanger,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          securityCode,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: _kDanger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: "اكتب الرمز هنا",
                      hintStyle: const TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 13,
                        letterSpacing: 0,
                        color: _kHint,
                      ),
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kDanger, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      setStateDialog(() {});
                    },
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
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: isCodeValid
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text(
                    "حذف المحدّد",
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

    setState(() => _isDeleting = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String actId in _selectedAttendanceIds) {
        final docRef = FirestorePaths.studentActivities(
          widget.student.id!,
        ).doc(actId);
        batch.delete(docRef);
      }

      await batch.commit();

      setState(() {
        _selectedAttendanceIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الحذف: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "تأكيد الحذف",
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              color: _kNavy,
            ),
          ),
          content: const Text(
            "هل أنت متأكد من حذف هذا السجل؟ لا يمكن التراجع بعد الحذف.",
            style: TextStyle(
              fontFamily: 'cairo',
              color: _kNavyLight,
              fontSize: 13.5,
            ),
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
              onPressed: () => Navigator.pop(context, true),
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
    if (percent >= 0.9) return _kSuccess;
    if (percent >= 0.75) return const Color(0xFF0EA5E9); // أزرق سماوي
    if (percent >= 0.6) return _kWarning;
    return _kDanger;
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
    // 🟢 تجنب طلب Composite Index بترك الفرز للذاكرة المحلية
    final activitiesStream = FirestorePaths.studentActivities(
      widget.student.id!,
    ).where('groupId', isEqualTo: groupId).snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: activitiesStream,
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
          return Center(
            child: Text(
              'خطأ: ${snapshot.error}',
              style: const TextStyle(fontFamily: 'cairo', color: _kDanger),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: _kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inbox_rounded,
                    color: _kPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "لا توجد سجلات بعد لهذه المجموعة",
                  style: TextStyle(
                    fontFamily: 'cairo',
                    color: _kHint,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        // 🟢 فرز العناصر محلياً حسب التاريخ تنازلياً لمنع انهيار الاستعلام
        final activities = docs
            .map((doc) => ActivityModel.fromFirestore(doc))
            .toList();
        activities.sort((a, b) {
          final dateA = DateTime.tryParse(a.date ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b.date ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA); // أحدث تاريخ في الأعلى
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildActivityCard(activities[index]);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final isAttendance = activity.type == ActivityType.attendance.name;
    final isSelected = _selectedAttendanceIds.contains(activity.id);

    final isPresent = isAttendance
        ? (activity.attendancePresent == true)
        : (activity.examStatus == "حاضر");
    final borderColor = isPresent
        ? _kSuccess.withValues(alpha: 0.4)
        : _kDanger.withValues(alpha: 0.4);
    final statusColor = isPresent ? _kSuccess : _kDanger;
    final statusBg = isPresent ? _kSuccessBg : _kDangerBg;
    final percent = _examPercent(activity);
    final progressColor = _examProgressColor(percent);

    // 🟢 معالجة آمنة للتاريخ لتجنب أخطاء Parsing
    final parsedDate = DateTime.tryParse(activity.date ?? '')?.toLocal();
    final formattedDate = parsedDate != null
        ? DateFormat('dd-MMM-yyyy', 'ar').format(parsedDate)
        : (activity.date ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: (isAttendance && isSelected) ? _kPrimaryLight : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isAttendance && isSelected) ? _kPrimary : borderColor,
          width: (isAttendance && isSelected) ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAttendance && isSelected)
                ? _kPrimary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (_isSelectionMode && isAttendance) {
              _toggleAttendanceSelection(activity.id!);
            }
          },
          onLongPress: () {
            if (!isAttendance) return;
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedAttendanceIds.add(activity.id!);
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_isSelectionMode && isAttendance)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Checkbox(
                      value: isSelected,
                      activeColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (_) =>
                          _toggleAttendanceSelection(activity.id!),
                    ),
                  )
                else if (!_isSelectionMode) ...[
                  Column(
                    children: [
                      _circleAction(
                        icon: Icons.edit_rounded,
                        onPressed: () {
                          if (activity.type == ActivityType.attendance.name) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditAttendanceState(
                                  student: widget.student,
                                  activity: activity,
                                ),
                              ),
                            );
                          } else if (activity.type == ActivityType.exam.name) {
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
                        icon: _isDeleting
                            ? Icons.hourglass_top_rounded
                            : Icons.delete_rounded,
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
                ],
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
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: _kPrimaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.quiz_rounded,
                                color: _kPrimary,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              isAttendance
                                  ? "الحضور والغياب"
                                  : (activity.examName ?? "اختبار"),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _kNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (activity.note != null &&
                          activity.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          activity.note!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 12.5,
                            color: _kNavyLight,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      //==================== student rating  ==================
                      if (activity.studentRating != null &&
                          activity.studentRating! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${activity.studentRating!.toStringAsFixed(1)} / 10",
                                style: const TextStyle(
                                  fontFamily: 'cairo',
                                  color: _kNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 11.5,
                          color: _kHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isAttendance)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor, width: 1.2),
                          ),
                          child: Text(
                            isPresent ? "حاضر" : "غائب",
                            style: TextStyle(
                              fontFamily: 'cairo',
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Wrap(
                              spacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kPrimaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${activity.currentDegree} / ${activity.maxDegree}",
                                    style: const TextStyle(
                                      fontFamily: 'cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    activity.examStatus ?? "",
                                    style: TextStyle(
                                      fontFamily: 'cairo',
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                                backgroundColor: _kCardBorder,
                                valueColor: AlwaysStoppedAnimation(
                                  progressColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onPressed,
    Color background = _kPrimaryLight,
    Color foreground = _kPrimary,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: foreground, size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kPageBg,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
          ),
        ),
      );
    }

    final groupIds = widget.student.groupIds;
    final reportButton = AppSession.hasPermission('reports')
        ? Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Material(
              color: _kPrimaryLight,
              shape: const CircleBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isGeneratingReport ? null : _generateReport,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: _isGeneratingReport
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kPrimary,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: _kPrimary,
                          size: 20,
                        ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final PreferredSizeWidget appBarWidget = _isSelectionMode
        ? AppBar(
            backgroundColor: _kNavy,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedAttendanceIds.clear();
                });
              },
            ),
            title: Text(
              "تم تحديد ${_selectedAttendanceIds.length} سجل",
              style: const TextStyle(
                fontFamily: 'cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.select_all_rounded, color: Colors.white),
                tooltip: "تحديد كل سجلات الحضور",
                onPressed: () async {
                  final currentGid = _currentGroupId;
                  if (currentGid == null) return;

                  final snap =
                      await FirestorePaths.studentActivities(widget.student.id!)
                          .where('groupId', isEqualTo: currentGid)
                          .where(
                            'type',
                            isEqualTo: ActivityType.attendance.name,
                          )
                          .get();

                  final attendanceIds = snap.docs.map((d) => d.id).toList();

                  setState(() {
                    if (_selectedAttendanceIds.length == attendanceIds.length) {
                      _selectedAttendanceIds.clear();
                    } else {
                      _selectedAttendanceIds.addAll(attendanceIds);
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.redAccent,
                disabledColor: Colors.white38,
                tooltip: "حذف المحددين",
                onPressed: (_selectedAttendanceIds.isEmpty || _isDeleting)
                    ? null
                    : () => _deleteSelectedAttendances(),
              ),
            ],
            bottom: groupIds.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(54),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: _kNavyLight,
                        labelStyle: const TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 13,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: groupIds
                            .map((gid) => Tab(text: _groupLabel(gid)))
                            .toList(),
                      ),
                    ),
                  )
                : null,
          )
        : AppBar(
            backgroundColor: _kPageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: _kNavy,
            centerTitle: false,
            title: Text(
              widget.student.name ?? '',
              style: const TextStyle(
                fontFamily: 'cairo',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _kNavy,
              ),
            ),
            actions: [reportButton],
            bottom: groupIds.isNotEmpty
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(54),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: _kNavyLight,
                        labelStyle: const TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 13,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: groupIds
                            .map((gid) => Tab(text: _groupLabel(gid)))
                            .toList(),
                      ),
                    ),
                  )
                : null,
          );

    if (groupIds.isEmpty) {
      return Scaffold(
        backgroundColor: _kPageBg,
        appBar: appBarWidget,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: _kPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: _kPrimary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "الطالب غير مسجل في أي مجموعة حاليًا",
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: _kHint,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: appBarWidget,
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
              foregroundColor: _kPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
            const SizedBox(width: 10),
          ],
          if (AppSession.hasPermission('exams')) ...[
            FloatingActionButton(
              heroTag: "addExam",
              tooltip: "إضافة امتحان",
              backgroundColor: Colors.white,
              foregroundColor: _kPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _kCardBorder),
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
              child: const Icon(Icons.assignment_add, color: _kPrimary),
            ),
            const SizedBox(width: 10),
          ],
          FloatingActionButton(
            heroTag: "viewReport",
            tooltip: "عرض شاشة التقرير",
            backgroundColor: _kPrimary,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
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
