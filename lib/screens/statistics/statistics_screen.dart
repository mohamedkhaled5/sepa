import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/student_profile/student_profile_screen.dart';

// ================== نظام الألوان الحديث ==================
const _kPrimary = Color(0xFF4F46E5);
const _kPrimaryLight = Color(0xFFEEF2FF);
const _kNavy = Color(0xFF0F172A);
const _kNavyLight = Color(0xFF334155);
const _kPageBg = Color(0xFFF8FAFC);
const _kHint = Color(0xFF64748B);
const _kCardBorder = Color(0xFFE2E8F0);
const _kDanger = Color(0xFFEF4444);
const _kSuccess = Color(0xFF10B981);
const _kWarning = Color(0xFFF59E0B);

/// نموذج داخلي لتجميع وحساب إحصائيات كل طالب
class StudentStats {
  final StudentModel student;
  final int presentCount;
  final int absentCount;
  final double attendancePercentage;
  final double totalObtainedMarks;
  final double totalMaxMarks;
  final double examPercentage;
  final int examCount;
  final double avgRating;
  final double overallScore; // النتيجة العامة لترتيب الطالب

  StudentStats({
    required this.student,
    required this.presentCount,
    required this.absentCount,
    required this.attendancePercentage,
    required this.totalObtainedMarks,
    required this.totalMaxMarks,
    required this.examPercentage,
    required this.examCount,
    required this.avgRating,
    required this.overallScore,
  });
}

class StatisticsScreen extends StatefulWidget {
  /// إذا تم تمرير groupId، سيتم عرض إحصائيات هذه المجموعة فقط.
  /// إذا كان null، سيتم عرض الإحصائيات لجميع المجموعات والطلاب.
  final String? groupId;

  const StatisticsScreen({super.key, this.groupId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  List<StudentStats> _statsList = [];
  String _searchQuery = "";

  // إحصائيات عامة ملخصة
  int _totalStudents = 0;
  double _overallAttendanceRate = 0.0;
  double _overallExamAverage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // 1. جلب الطلاب (إما لمجموعة محددة أو للكل)
      Query<Map<String, dynamic>> query = FirestorePaths.students;
      if (widget.groupId != null) {
        query = query.where("groupIds", arrayContains: widget.groupId);
      }

      final studentsSnap = await query.get();
      final students = studentsSnap.docs
          .map((doc) => StudentModel.fromFirestore(doc))
          .toList();

      List<StudentStats> computedStats = [];
      int globalPresent = 0;
      int globalAttendanceTotal = 0;
      double globalExamObtainedSum = 0;
      double globalExamMaxSum = 0;

      // 2. جلب أنشطة كل طالب وتجميع بياناته
      for (var student in students) {
        if (student.id == null) continue;

        final activitiesSnap = await FirestorePaths.studentActivities(
          student.id!,
        ).get();

        int presentCount = 0;
        int absentCount = 0;
        double obtainedMarks = 0;
        double maxMarks = 0;
        int examCount = 0;
        double totalRating = 0;
        int ratingCount = 0;

        for (var doc in activitiesSnap.docs) {
          final act = ActivityModel.fromFirestore(doc);

          // إذا كانت الصفحة محددة بمجموعة، نقوم بتصفية الأنشطة التابعة للمجموعة فقط
          if (widget.groupId != null && act.groupId != widget.groupId) {
            continue;
          }

          // حساب الحضور والغياب
          if (act.type == ActivityType.attendance.name) {
            if (act.attendancePresent == true) {
              presentCount++;
            } else {
              absentCount++;
            }
          }

          // حساب درجات الاختبارات
          if (act.type == ActivityType.exam.name) {
            final cur = double.tryParse(act.currentDegree ?? '0') ?? 0;
            final max = double.tryParse(act.maxDegree ?? '0') ?? 0;

            if (max > 0) {
              obtainedMarks += cur;
              maxMarks += max;
              examCount++;
            }
          }

          // حساب التقييم
          if (act.studentRating != null && act.studentRating! > 0) {
            totalRating += act.studentRating!;
            ratingCount++;
          }
        }

        // الحسابات المئوية لكل طالب
        final totalAttendance = presentCount + absentCount;
        final attendancePct = totalAttendance > 0
            ? (presentCount / totalAttendance) * 100
            : 0.0;
        final examPct = maxMarks > 0 ? (obtainedMarks / maxMarks) * 100 : 0.0;
        final avgRating = ratingCount > 0 ? (totalRating / ratingCount) : 0.0;

        // معادلة الترتيب العام (60% درجات الاختبارات + 30% الحضور والغياب + 10% التقييم)
        double overallScore = 0.0;
        if (maxMarks > 0 && totalAttendance > 0) {
          overallScore =
              (examPct * 0.60) +
              (attendancePct * 0.30) +
              ((avgRating / 5.0) * 10.0);
        } else if (maxMarks > 0) {
          overallScore = (examPct * 0.85) + ((avgRating / 5.0) * 15.0);
        } else if (totalAttendance > 0) {
          overallScore = (attendancePct * 0.85) + ((avgRating / 5.0) * 15.0);
        } else {
          overallScore = (avgRating / 5.0) * 100.0;
        }

        // تجميع الإحصائيات الشاملة
        globalPresent += presentCount;
        globalAttendanceTotal += totalAttendance;
        globalExamObtainedSum += obtainedMarks;
        globalExamMaxSum += maxMarks;

        computedStats.add(
          StudentStats(
            student: student,
            presentCount: presentCount,
            absentCount: absentCount,
            attendancePercentage: attendancePct,
            totalObtainedMarks: obtainedMarks,
            totalMaxMarks: maxMarks,
            examPercentage: examPct,
            examCount: examCount,
            avgRating: avgRating,
            overallScore: overallScore,
          ),
        );
      }

      // 3. ترتيب الطلاب تنازلياً حسب التقييم العام Score
      computedStats.sort((a, b) => b.overallScore.compareTo(a.overallScore));

      if (mounted) {
        setState(() {
          _statsList = computedStats;
          _totalStudents = students.length;
          _overallAttendanceRate = globalAttendanceTotal > 0
              ? (globalPresent / globalAttendanceTotal) * 100
              : 0.0;
          _overallExamAverage = globalExamMaxSum > 0
              ? (globalExamObtainedSum / globalExamMaxSum) * 100
              : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء تحميل الإحصائيات: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStats = _statsList.where((item) {
      final name = item.student.name ?? "";
      return name.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _kNavy,
        title: Text(
          widget.groupId != null
              ? "إحصائيات المجموعة"
              : "الإحصائيات وترتيب الطلاب",
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _kNavy,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. كارت الملخص العام للإحصائيات
                  _buildSummaryHeader(),
                  const SizedBox(height: 20),

                  // 2. حقل البحث في ترتيب الطلاب
                  TextField(
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: "بحث باسم الطالب...",
                      hintStyle: const TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 13,
                        color: _kHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _kPrimary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _kCardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _kCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _kPrimary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ترتيب الطلاب (الأعلى أداءً)",
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kNavy,
                        ),
                      ),
                      Icon(
                        Icons.leaderboard_rounded,
                        color: _kPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. قائمة الترتيب والبطاقات
                  if (filteredStats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          "لا توجد بيانات متاحة حالياً",
                          style: TextStyle(fontFamily: 'cairo', color: _kHint),
                        ),
                      ),
                    )
                  else
                    ...List.generate(filteredStats.length, (index) {
                      final item = filteredStats[index];
                      return _buildLeaderboardCard(item, index + 1);
                    }),
                ],
              ),
            ),
    );
  }

  // كارت ملخص الإحصائيات العلوي
  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "إجمالي الطلاب: $_totalStudents",
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                "نظرة عامة على الأداء",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStatBox(
                  title: "نسبة الحضور العام",
                  value: "${_overallAttendanceRate.toStringAsFixed(1)}%",
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderStatBox(
                  title: "متوسط الاختبارات",
                  value: "${_overallExamAverage.toStringAsFixed(1)}%",
                  icon: Icons.assignment_turned_in_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة عرض ترتيب الطالب وتفاصيل أداءه
  Widget _buildLeaderboardCard(StudentStats stat, int rank) {
    Widget rankBadge;

    if (rank == 1) {
      rankBadge = const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFFFD700),
        child: Text("🥇", style: TextStyle(fontSize: 16)),
      );
    } else if (rank == 2) {
      rankBadge = const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFC0C0C0),
        child: Text("🥈", style: TextStyle(fontSize: 16)),
      );
    } else if (rank == 3) {
      rankBadge = const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFFCD7F32),
        child: Text("🥉", style: TextStyle(fontSize: 16)),
      );
    } else {
      rankBadge = CircleAvatar(
        radius: 16,
        backgroundColor: _kPrimaryLight,
        child: Text(
          "$rank",
          style: const TextStyle(
            fontFamily: 'cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentProfileScreen(
                  student: stat.student,
                  initialGroupId:
                      widget.groupId ??
                      (stat.student.groupIds.isNotEmpty
                          ? stat.student.groupIds.first
                          : ""),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    rankBadge,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.student.name ?? "بدون اسم",
                            style: const TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: _kNavy,
                            ),
                          ),
                          if (stat.student.phone != null)
                            Text(
                              stat.student.phone!,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 12,
                                color: _kNavyLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: _kWarning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${stat.overallScore.toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: _kCardBorder),
                const SizedBox(height: 10),

                // تفاصيل الحضور والاختبارات للـ Student
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatDetailItem(
                      label: "الحضور والغياب",
                      value: "${stat.attendancePercentage.toStringAsFixed(0)}%",
                      subValue:
                          "حضر ${stat.presentCount} / غاب ${stat.absentCount}",
                      color: stat.attendancePercentage >= 80
                          ? _kSuccess
                          : _kDanger,
                    ),
                    Container(width: 1, height: 30, color: _kCardBorder),
                    _buildStatDetailItem(
                      label: "مجموع الدرجات",
                      value: stat.totalMaxMarks > 0
                          ? "${stat.examPercentage.toStringAsFixed(0)}%"
                          : "لا يوجد",
                      subValue: stat.totalMaxMarks > 0
                          ? "${stat.totalObtainedMarks.toStringAsFixed(1)} / ${stat.totalMaxMarks.toStringAsFixed(1)}"
                          : "لم يختبر",
                      color: stat.examPercentage >= 50 ? _kPrimary : _kDanger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDetailItem({
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontSize: 11,
            color: _kHint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          subValue,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontSize: 10.5,
            color: _kNavyLight,
          ),
        ),
      ],
    );
  }
}
