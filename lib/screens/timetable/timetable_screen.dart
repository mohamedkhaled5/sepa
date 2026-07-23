import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/screens/home/group_screens/student_display_screen/student_display_screen.dart';
import 'package:seba/screens/timetable/timetable_models.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kWarning = Color(0xFFC98A2C);
const _kWarningBg = Color(0xFFFCF1E1);

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
const double _kTimeColWidth = 52;

/// لوحة ألوان ثابتة للمواد - نفس المادة بتاخد نفس اللون دايمًا (مبني
/// على hash اسم المادة)، عشان تسهيل التمييز البصري بين المواد المختلفة
/// جوه الجدول من غير أي إعداد يدوي من المستخدم.
const List<Color> _kSubjectPalette = [
  Color(0xFFDCEBFF), // أزرق فاتح
  Color(0xFFE3F5E1), // أخضر فاتح
  Color(0xFFFCEBD8), // برتقالي فاتح
  Color(0xFFF3E1F7), // بنفسجي فاتح
  Color(0xFFE1F5F1), // تركواز فاتح
  Color(0xFFFCE4E4), // وردي فاتح
];

Color _colorForSubject(String? subject) {
  if (subject == null || subject.isEmpty) return _kIconBg;
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
        foregroundColor: _kNavy,
        centerTitle: false,
        title: const Text(
          "الجدول الزمني",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestorePaths.groups.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
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
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kNavy : _kCardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
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
        Row(
          children: [
            SizedBox(width: _kTimeColWidth),
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
        const Divider(height: 1, color: _kCardBorder),

        // الجسم: عمود الساعات + شبكة الأيام، بتمرير رأسي وأفقي متزامنين
        Expanded(
          child: SingleChildScrollView(
            controller: _vController,
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
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // اليوم الحالي ياخد خلفية فاتحة مميزة عشان يلفت النظر فورًا،
        // من غير ما يكون صارخ أو يكسر هدوء باقي التصميم.
        color: isToday ? _kIconBg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isToday ? Border.all(color: _kNavy.withOpacity(0.25)) : null,
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
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kNavy,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                day,
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _kNavy,
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 2),
            Text(
              "$count مجموعة",
              style: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 10,
                color: _kHint,
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
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 11,
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
        color: isToday ? const Color(0xFFF8FBFF) : Colors.white,
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
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentDisplayScreen(groupId: occ.group.id!),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: occ.hasConflict
                    ? _kWarning
                    : Colors.black.withOpacity(0.05),
                width: occ.hasConflict ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (occ.hasConflict) ...[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: _kWarning,
                      ),
                      const SizedBox(width: 2),
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
                          fontSize: 10.5,
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
                      fontSize: 9,
                      color: _kNavyLight,
                    ),
                  ),
                ],
                if (height > 56) ...[
                  Text(
                    "${_formatShortTime(occ.startMinutes)}-${_formatShortTime(occ.endMinutes)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 8.5,
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
