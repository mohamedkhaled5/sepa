import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/screens/home/group_screens/student_display_screen/student_display_screen.dart';
import 'package:seba/screens/timetable/timetable_models.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة للأيقونات
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kWarning = Color(0xFFF59E0B); // برتقالي تحذيري للتعارضات
const _kWarningBg = Color(0xFFFEF3C7); // خلفية التعارض الخفيفة

// ================== ثوابت الشبكة ==================
const List<String> _kWeekDays = [
  "السبت",
  "الأحد",
  "الاثنين",
  "الثلاثاء",
  "الأربعاء",
  "الخميس",
  "الجمعة",
];

const int _kStartHour = 1; // 8 صباحًا
const int _kEndHour = 24; // 11 مساءً
const double _kHourHeight = 76;
const double _kDayColWidth = 168;
const double _kTimeColWidth = 56;

/// لوحة ألوان ثابتة هادئة للمواد - نفس المادة بتاخد نفس اللون دايمًا (مبني
/// على hash اسم المادة)، عشان تسهيل التمييز البصري بين المواد المختلفة
/// جوه الجدول من غير أي إعداد يدوي من المستخدم.
const List<Color> _kSubjectPalette = [
  Color(0xFFEEF2FF), // نيلي فاتح
  Color(0xFFECFDF5), // أخضر زمردي فاتح
  Color(0xFFFFF7ED), // برتقالي دافئ فاتح
  Color(0xFFF3E8FF), // بنفسجي فاتح
  Color(0xFFF0FDFA), // تركواز فاتح
  Color(0xFFFEF2F2), // وردي فاتح
];

Color _colorForSubject(String? subject) {
  if (subject == null || subject.isEmpty) return _kPrimaryLight;
  final index = subject.hashCode.abs() % _kSubjectPalette.length;
  return _kSubjectPalette[index];
}

/// شاشة الجدول الزمني الأسبوعي لكل مجموعات المستخدم. مرتبطة مباشرة
/// بـ Firestore عبر StreamBuilder، فأي إضافة/تعديل/حذف لمجموعة بينعكس
/// فورًا على الجدول من غير أي تحديث يدوي.
///
/// التعارضات بتتحسب ديناميكيًا في كل مرة يوصل فيها snapshot جديد
/// (عبر TimetableConflictService) - مفيش أي حالة "تعارض" متخزنة في
/// Firestore نفسه، فمينفعش تتقدّم أو تفضل عالقة.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // كنترولر منفصل لكل Scrollable: الرأس (غير تفاعلي، بيتبع الجسم بس)
  // والجسم (اللي فعليًا بيتحرك بإيد المستخدم). مشاركة نفس الكنترولر
  // بين اتنين Scrollable مختلفين ماكانتش بتزامنهم فعليًا - أي سحب على
  // الجسم كان بيحدّث الـ ScrollPosition بتاعته هو بس، فده سبب المشكلة
  // اللي كان شريط الأيام واقف فيها ثابت.
  final ScrollController _headerHController = ScrollController();
  final ScrollController _bodyHController = ScrollController();
  final ScrollController _vController = ScrollController();

  // فلتر بسيط بالمادة - نقطة توسع جاهزة لإضافة فلاتر صف/معلم لاحقًا
  // بنفس الطريقة، لأنه بيشتغل على القائمة المجلوبة أصلًا في الذاكرة
  // بدون أي استعلام إضافي على Firestore.
  String? _selectedSubjectFilter;

  // ربط DateTime.weekday (الإثنين=1 ... الأحد=7) بترتيب أيام الأسبوع
  // عندنا (السبت أول يوم، الجمعة آخر يوم) عشان نعرف نحدد عمود اليوم
  // الحالي بالظبط في الجدول.
  static const Map<int, int> _weekdayToIndex = {
    6: 0,
    7: 1,
    1: 2,
    2: 3,
    3: 4,
    4: 5,
    5: 6,
  };

  late final int _todayIndex = _weekdayToIndex[DateTime.now().weekday]!;
  String get _todayName => _kWeekDays[_todayIndex];

  @override
  void initState() {
    super.initState();
    // كل ما جسم الجدول يتحرك أفقيًا، رأس الأيام يتبعه فورًا لنفس
    // الموضع بالظبط.
    _bodyHController.addListener(() {
      if (_headerHController.hasClients) {
        _headerHController.jumpTo(_bodyHController.offset);
      }
    });

    // بعد أول رسم للشاشة، نمرّر الجدول أفقيًا تلقائيًا لعمود اليوم
    // الحالي، عشان يبقى أول حاجة المدرس شايفها من غير ما يسحب بنفسه.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!_bodyHController.hasClients) return;

    final target = (_todayIndex * _kDayColWidth).clamp(
      0.0,
      _bodyHController.position.maxScrollExtent,
    );

    _bodyHController.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _headerHController.dispose();
    _bodyHController.dispose();
    _vController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _kNavy,
        centerTitle: false,
        title: const Text(
          "الجدول الزمني",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: _kNavy,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestorePaths.groups.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: const TextStyle(fontFamily: 'cairo', color: _kNavy),
              ),
            );
          }

          var groups = (snapshot.data?.docs ?? [])
              .map((d) => GroupModel.fromFirestore(d))
              .toList();

          final subjects =
              groups.map((g) => g.subject).whereType<String>().toSet().toList()
                ..sort();

          if (_selectedSubjectFilter != null) {
            groups = groups
                .where((g) => g.subject == _selectedSubjectFilter)
                .toList();
          }

          final schedule = TimetableConflictService.buildSchedule(groups);

          return Column(
            children: [
              if (subjects.isNotEmpty) _buildSubjectFilterBar(subjects),
              Expanded(child: _buildGrid(schedule)),
            ],
          );
        },
      ),
    );
  }

  // ================== شريط فلترة المواد ==================
  Widget _buildSubjectFilterBar(List<String> subjects) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        physics: const BouncingScrollPhysics(),
        children: [
          _filterChip(
            label: "الكل",
            selected: _selectedSubjectFilter == null,
            onTap: () {
              setState(() => _selectedSubjectFilter = null);
            },
          ),
          const SizedBox(width: 8),
          ...subjects.map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _filterChip(
                label: s,
                selected: _selectedSubjectFilter == s,
                onTap: () => setState(() => _selectedSubjectFilter = s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kPrimary : _kCardBorder,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : _kNavyLight,
          ),
        ),
      ),
    );
  }

  // ================== الشبكة الأساسية ==================
  Widget _buildGrid(Map<String, List<TimetableOccurrence>> schedule) {
    final totalMinutes = (_kEndHour - _kStartHour) * 60;
    final gridHeight = totalMinutes / 60 * _kHourHeight;

    return Column(
      children: [
        // رأس الأيام - مش قابل للسحب مباشرة (physics معطّلة)، بس بيتبع
        // موضع جسم الجدول أوتوماتيكيًا عبر الـ listener فوق.
        Container(
          color: Colors.white,
          child: Row(
            children: [
              const SizedBox(width: _kTimeColWidth),
              Expanded(
                child: SingleChildScrollView(
                  controller: _headerHController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: _kWeekDays
                        .map(
                          (day) => _dayHeaderCell(
                            day,
                            schedule[day]?.length ?? 0,
                            isToday: day == _todayName,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _kCardBorder),

        // الجسم: عمود الساعات + شبكة الأيام، بتمرير رأسي وأفقي متزامنين
        Expanded(
          child: SingleChildScrollView(
            controller: _vController,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _kTimeColWidth,
                  height: gridHeight,
                  child: _buildHourLabelsColumn(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _bodyHController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: gridHeight,
                      child: Row(
                        children: _kWeekDays
                            .map(
                              (day) => _buildDayColumn(
                                day,
                                schedule[day] ?? [],
                                gridHeight,
                                isToday: day == _todayName,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayHeaderCell(String day, int count, {required bool isToday}) {
    return Container(
      width: _kDayColWidth,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // اليوم الحالي ياخد خلفية مميزة مع ألوان الهوية البصرية،
        // لتسهيل التمييز الفوري.
        color: isToday ? _kPrimaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: _kPrimary.withValues(alpha: 0.3), width: 1.2)
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isToday) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                day,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isToday ? _kPrimary : _kNavy,
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 2),
            Text(
              "$count مجموعة",
              style: TextStyle(
                fontFamily: 'cairo',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isToday ? _kPrimary : _kHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHourLabelsColumn() {
    final hours = List.generate(
      _kEndHour - _kStartHour,
      (i) => _kStartHour + i,
    );
    return Column(
      children: hours.map((h) {
        final label = h == 0
            ? "12 ص"
            : h < 12
            ? "$h ص"
            : h == 12
            ? "12 م"
            : "${h - 12} م";
        return SizedBox(
          height: _kHourHeight,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _kHint,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayColumn(
    String day,
    List<TimetableOccurrence> occurrences,
    double gridHeight, {
    required bool isToday,
  }) {
    final hourCount = _kEndHour - _kStartHour;

    return Container(
      width: _kDayColWidth,
      height: gridHeight,
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFF1F5F9).withValues(alpha: 0.5)
            : Colors.white,
        border: const Border(left: BorderSide(color: _kCardBorder)),
      ),
      child: Stack(
        children: [
          // خطوط الساعات الأفقية الخفيفة
          Column(
            children: List.generate(
              hourCount,
              (_) => Container(
                height: _kHourHeight,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: _kCardBorder, width: 0.6),
                  ),
                ),
              ),
            ),
          ),
          ...occurrences.map((occ) => _buildOccurrenceCard(occ)),
        ],
      ),
    );
  }

  Widget _buildOccurrenceCard(TimetableOccurrence occ) {
    final pixelsPerMinute = _kHourHeight / 60;
    final top = (occ.startMinutes - _kStartHour * 60) * pixelsPerMinute;
    final height = (occ.durationMinutes * pixelsPerMinute).clamp(
      28.0,
      double.infinity,
    );

    // لو فيه تعارض، كل بطاقة تاخد جزء من عرض العمود جنب بعضها بدل ما
    // تتراكب فوق بعض، بنفس أسلوب تطبيقات المواعيد الاحترافية.
    final clusterSize = occ.conflictClusterSize;
    final slotWidth = (_kDayColWidth - 6) / clusterSize;
    final left = 3 + occ.conflictIndexInCluster * slotWidth;

    final bg = occ.hasConflict
        ? _kWarningBg
        : _colorForSubject(occ.group.subject);

    return Positioned(
      top: top,
      left: left,
      width: slotWidth - 3,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentDisplayScreen(groupId: occ.group.id!),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: occ.hasConflict
                    ? _kWarning
                    : Colors.black.withValues(alpha: 0.06),
                width: occ.hasConflict ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (occ.hasConflict) ...[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: _kWarning,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Text(
                        occ.hasConflict
                            ? "${occ.group.subject ?? ''} (${occ.conflictClusterSize})"
                            : occ.group.subject ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: occ.hasConflict ? _kWarning : _kNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                if (height > 40) ...[
                  Text(
                    occ.group.grade ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: _kNavyLight,
                    ),
                  ),
                ],
                if (height > 56) ...[
                  const Spacer(),
                  Text(
                    "${_formatShortTime(occ.startMinutes)} - ${_formatShortTime(occ.endMinutes)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: _kHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// دالة صغيرة محلية لعرض وقت مختصر جوه البطاقة (مش محتاجة صيغة AM/PM
// كاملة زي TimeUtils.formatMinutes الرسمية، بس عرض سريع بالأرقام).
String _formatShortTime(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return "$h:${m.toString().padLeft(2, '0')}";
}
