import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:seba/screens/student/student_profile/add_exam.dart/add_exam_screen.dart';
import 'package:seba/screens/student/student_profile/attendance_operation/add_attendance_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/report/report_data_service.dart';
import 'package:seba/screens/report/student_report_data.dart';
import 'package:seba/screens/report/student_report_pdf_builder.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

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

/// شاشة "بيانات الطالب" الشاملة داخل التطبيق - ملخص بصري لكل حاجة
/// عن الطالب (بياناته، حضوره وغيابه، أداؤه في الامتحانات لكل مجموعة)
/// قبل ما يتصدّر كـ PDF لو حاب.
///
/// ⚠️ نقطة توسع مستقبلية: قسم "الملاحظات" (زي في التصميم المرجعي)
/// مش موجود هنا لأن مفيش Collection أو شاشة ملاحظات مبنية في النظام
/// لسه - بس الصلاحية 'notes' محجوزة له بالفعل في نظام صلاحيات
/// المساعدين، فلو حبيت نضيفه، المكان جاهز هنا في نفس تصميم الكارت.
class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key, required this.student});

  final StudentModel student;

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  late Future<StudentReportData> _reportFuture;
  bool _isExportingPdf = false;
  final ScreenshotController screenshotController = ScreenshotController();
  final WidgetsToImageController widgetsToImageController =
      WidgetsToImageController();
  @override
  void initState() {
    super.initState();
    _reportFuture = ReportDataService().buildReportForStudent(widget.student);
  }

  Future<void> _exportPdf(StudentReportData data) async {
    setState(() => _isExportingPdf = true);
    try {
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
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _callParent() async {
    final phone = widget.student.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("لا يوجد رقم هاتف مسجل")));
      return;
    }
    await launchUrl(Uri.parse("tel:$phone"));
  }

  /// لو الطالب في أكتر من مجموعة، بنسأله يختار أنهي مجموعة قبل ما
  /// يفتح شاشة إضافة حضور/امتحان (لأن كل نشاط لازم يتربط بمجموعة).
  Future<String?> _pickGroupId(StudentReportData data) async {
    if (data.groupSections.length == 1) {
      return data.groupSections.first.group.id;
    }

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "اختر المجموعة",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...data.groupSections.map((section) {
                return ListTile(
                  title: Text(
                    "${section.group.subject ?? ''} - ${section.group.grade ?? ''}",
                    style: const TextStyle(fontFamily: 'cairo'),
                  ),
                  onTap: () => Navigator.pop(context, section.group.id),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> shareScreen() async {
    try {
      final bytes = await widgetsToImageController.capture();

      if (bytes == null) return;

      final dir = await getTemporaryDirectory();

      final file = File("${dir.path}/student_report.png");

      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              """
السلام عليكم ورحمة الله وبركاته

تقرير الطالب: ${widget.student.name ?? 'طالب'}

الأستاذة حسناء
""",
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsToImage(
      controller: widgetsToImageController,
      child: Scaffold(
        backgroundColor: _kPageBg,
        appBar: AppBar(
          backgroundColor: _kNavy,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "بيانات الطالب",
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: FutureBuilder<StudentReportData>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            final data = snapshot.data!;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    _buildHeaderCard(data),
                    const SizedBox(height: 14),
                    _buildAttendanceCard(data),
                    const SizedBox(height: 14),
                    _buildPerformanceCard(data),
                    const SizedBox(height: 14),
                    if (data.groupSections.length > 1)
                      _buildPerGroupBreakdown(data),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildActionBar(data),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================== بطاقة بيانات الطالب ==================
  Widget _buildHeaderCard(StudentReportData data) {
    final student = data.student;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      student.name ?? '',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: data.groupSections
                          .map(
                            (s) => _miniTag(
                              Icons.menu_book_rounded,
                              "${s.group.subject ?? ''} - ${s.group.grade ?? ''}",
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kCardBorder),
          const SizedBox(height: 12),
          _infoRow(Icons.phone_rounded, "هاتف ولي الأمر", student.phone ?? '—'),
          const SizedBox(height: 10),
          _infoRow(
            Icons.groups_2_rounded,
            "ولي الأمر",
            student.parentName ?? '—',
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.family_restroom_rounded,
            "صلة القرابة",
            student.parentRelation ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: _kIconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kNavy, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: _kNavyLight,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontSize: 12,
            color: _kHint,
          ),
        ),
      ],
    );
  }

  Widget _miniTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 10.5,
              color: _kNavy,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: _kNavy),
        ],
      ),
    );
  }

  // ================== بطاقة الحضور والغياب (مجمّعة لكل المجموعات) ==================
  Widget _buildAttendanceCard(StudentReportData data) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle("الحضور والغياب", Icons.event_available_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  value: "${data.totalPresent}",
                  label: "يوم حضور",
                  icon: Icons.check_circle_rounded,
                  color: _kSuccess,
                  background: _kSuccessBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  value: "${data.totalAbsent}",
                  label: "يوم غياب",
                  icon: Icons.cancel_rounded,
                  color: _kDanger,
                  background: _kDangerBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: _kIconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${(data.overallAttendanceRate * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _kNavy,
                  ),
                ),
                const Text(
                  "نسبة الحضور الكلية",
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 11.5,
              color: _kNavyLight,
            ),
          ),
        ],
      ),
    );
  }

  // ================== بطاقة الأداء في الامتحانات ==================
  Widget _buildPerformanceCard(StudentReportData data) {
    final average = data.overallAverageExamPercentage;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle("الأداء في الاختبارات", Icons.insights_rounded),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (average / 100).clamp(0, 1),
                      strokeWidth: 7,
                      backgroundColor: _kCardBorder,
                      valueColor: const AlwaysStoppedAnimation(_kNavy),
                    ),
                    Text(
                      "${average.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _kNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${data.totalExamsCount} اختبار مُسجَّل",
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "متوسط الدرجات لكل المواد",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12,
                        color: _kHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== تفصيل الحضور والدرجات لكل مجموعة ==================
  Widget _buildPerGroupBreakdown(StudentReportData data) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle("تفصيل حسب المادة", Icons.list_alt_rounded),
          const SizedBox(height: 10),
          ...data.groupSections.map((section) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  if (section.totalExams > 0)
                    _miniTag(
                      Icons.grade_rounded,
                      "${section.averageExamPercentage.toStringAsFixed(0)}%",
                    ),
                  const SizedBox(width: 6),
                  _miniTag(
                    Icons.event_available_rounded,
                    "${(section.attendanceRate * 100).toStringAsFixed(0)}%",
                  ),
                  const Spacer(),
                  Text(
                    "${section.group.subject ?? ''} - ${section.group.grade ?? ''}",
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: _kNavyLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================== شريط الإجراءات السفلي ==================
  Widget _buildActionBar(StudentReportData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (AppSession.hasPermission('attendance'))
            _actionButton(
              icon: Icons.event_available_rounded,
              label: "تسجيل حضور",
              onTap: () async {
                final gid = await _pickGroupId(data);
                if (gid == null || !mounted) return;
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
            ),
          if (AppSession.hasPermission('exams'))
            _actionButton(
              icon: Icons.assignment_rounded,
              label: "إضافة اختبار",
              onTap: () async {
                final gid = await _pickGroupId(data);
                if (gid == null || !mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddExamScreen(student: widget.student, groupId: gid),
                  ),
                );
              },
            ),
          _actionButton(
            icon: Icons.phone_rounded,
            label: "تواصل مع ولي الأمر",
            onTap: _callParent,
          ),
          if (AppSession.hasPermission('reports'))
            _actionButton(
              icon: Icons.picture_as_pdf_rounded,
              label: "تقرير PDF",
              isPrimary: true,
              isLoading: _isExportingPdf,
              onTap: _isExportingPdf ? null : () => _exportPdf(data),
            ),
          _actionButton(icon: Icons.share, label: "مشاركة", onTap: shareScreen),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary ? _kNavy : _kIconBg,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      icon,
                      color: isPrimary ? Colors.white : _kNavy,
                      size: 21,
                    ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== عناصر مشتركة ==================
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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

  Widget _cardTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: _kIconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kNavy, size: 17),
        ),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
