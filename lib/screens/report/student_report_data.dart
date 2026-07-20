import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';

/// سجل حضور واحد داخل التقرير.
class AttendanceRecord {
  final DateTime date;
  final bool isPresent;
  AttendanceRecord({required this.date, required this.isPresent});
}

/// سجل امتحان واحد داخل التقرير.
class ExamRecord {
  final DateTime date;
  final String examName;
  final bool isPresent;
  final double currentDegree;
  final double maxDegree;

  ExamRecord({
    required this.date,
    required this.examName,
    required this.isPresent,
    required this.currentDegree,
    required this.maxDegree,
  });

  double get percentage =>
      maxDegree <= 0 ? 0 : (currentDegree / maxDegree) * 100;
}

/// قسم التقرير الخاص بمجموعة واحدة من مجموعات الطالب - كل مجموعة
/// (مادة) ليها حضورها وامتحاناتها وإحصائياتها المستقلة.
///
/// معمارية مرنة للتوسع: لو حبيت تضيف قسم جديد مستقبلًا (ملاحظات،
/// مدفوعات، سلوك...) يكفي تضيف List جديدة هنا واستخدامها في الـ PDF
/// builder، من غير ما تلمس منطق التجميع أو الشاشة اللي بتستدعيه.
class GroupReportSection {
  final GroupModel group;
  final List<AttendanceRecord> attendanceRecords;
  final List<ExamRecord> examRecords;

  GroupReportSection({
    required this.group,
    required this.attendanceRecords,
    required this.examRecords,
  });

  int get totalAttendance => attendanceRecords.length;
  int get presentCount => attendanceRecords.where((a) => a.isPresent).length;
  int get absentCount => totalAttendance - presentCount;
  double get attendanceRate =>
      totalAttendance == 0 ? 0 : presentCount / totalAttendance;

  int get totalExams => examRecords.length;
  double get averageExamPercentage {
    final validExams = examRecords.where((e) => e.maxDegree > 0).toList();
    if (validExams.isEmpty) return 0;
    final sum = validExams.fold<double>(0, (s, e) => s + e.percentage);
    return sum / validExams.length;
  }
}

/// نتيجة التقرير الكاملة لطالب واحد - بتُبنى مرة واحدة وتُستخدم في أي
/// شكل عرض (PDF دلوقتي، وممكن مستقبلًا Excel أو عرض داخل الشاشة نفسها
/// من غير أي تغيير في طريقة التجميع).
class StudentReportData {
  final StudentModel student;
  final DateTime generatedAt;
  final List<GroupReportSection> groupSections;

  StudentReportData({
    required this.student,
    required this.generatedAt,
    required this.groupSections,
  });

  int get totalPresent =>
      groupSections.fold(0, (sum, s) => sum + s.presentCount);
  int get totalAbsent => groupSections.fold(0, (sum, s) => sum + s.absentCount);
  int get totalAttendanceRecords => totalPresent + totalAbsent;
  double get overallAttendanceRate =>
      totalAttendanceRecords == 0 ? 0 : totalPresent / totalAttendanceRecords;

  int get totalExamsCount =>
      groupSections.fold(0, (sum, s) => sum + s.totalExams);

  double get overallAverageExamPercentage {
    final allExams = groupSections
        .expand((s) => s.examRecords)
        .where((e) => e.maxDegree > 0)
        .toList();
    if (allExams.isEmpty) return 0;
    final sum = allExams.fold<double>(0, (s, e) => s + e.percentage);
    return sum / allExams.length;
  }
}
