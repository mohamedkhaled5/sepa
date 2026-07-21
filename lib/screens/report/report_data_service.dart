import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/report/student_report_data.dart';

/// مسؤولة عن حاجة واحدة بس: تجميع بيانات Firestore الخام (مجموعات +
/// أنشطة الطالب) في شكل [StudentReportData] منظم وجاهز للعرض.
/// مفصولة تمامًا عن أي منطق PDF أو UI، عشان تقدر تُستخدم مستقبلًا لأي
/// شكل تقرير تاني (Excel، عرض داخل الشاشة، إلخ) من غير أي تكرار كود.
class ReportDataService {
  Future<StudentReportData> buildReportForStudent(StudentModel student) async {
    final groupsById = await _fetchGroupsById(student.groupIds);
    final activities = await _fetchAllActivities(student.id!);

    final sections = <GroupReportSection>[];

    for (final groupId in student.groupIds) {
      final group = groupsById[groupId];
      if (group == null) continue; // مجموعة اتحذفت مثلاً، نتجاهلها بأمان

      final groupActivities = activities.where((a) => a.groupId == groupId);

      final attendanceRecords =
          groupActivities
              .where((a) => a.type == 'attendance')
              .map(
                (a) => AttendanceRecord(
                  date: DateTime.tryParse(a.date ?? '') ?? DateTime.now(),
                  isPresent: a.attendancePresent ?? false,
                ),
              )
              .toList()
            ..sort((x, y) => x.date.compareTo(y.date));

      final examRecords =
          groupActivities
              .where((a) => a.type == 'exam')
              .map(
                (a) => ExamRecord(
                  date: DateTime.tryParse(a.date ?? '') ?? DateTime.now(),
                  examName: a.examName ?? '',
                  isPresent: a.examStatus == 'حاضر',
                  currentDegree: double.tryParse(a.currentDegree ?? '') ?? 0,
                  maxDegree: double.tryParse(a.maxDegree ?? '') ?? 0,
                ),
              )
              .toList()
            ..sort((x, y) => x.date.compareTo(y.date));

      sections.add(
        GroupReportSection(
          group: group,
          attendanceRecords: attendanceRecords,
          examRecords: examRecords,
        ),
      );
    }

    return StudentReportData(
      student: student,
      generatedAt: DateTime.now(),
      groupSections: sections,
    );
  }

  Future<Map<String, GroupModel>> _fetchGroupsById(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return {};

    final snap = await FirestorePaths.groups
        .where(FieldPath.documentId, whereIn: groupIds)
        .get();

    return {for (final doc in snap.docs) doc.id: GroupModel.fromFirestore(doc)};
  }

  Future<List<ActivityModel>> _fetchAllActivities(String studentId) async {
    final snap = await FirestorePaths.studentActivities(
      studentId,
    ).orderBy('date').get();

    return snap.docs.map((d) => ActivityModel.fromFirestore(d)).toList();
  }
}
