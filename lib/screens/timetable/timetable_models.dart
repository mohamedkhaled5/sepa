import 'package:seba/model/group_model.dart';
import 'package:seba/core/time_utils.dart';

/// تمثيل "ظهور واحد" لمجموعة في الجدول - المجموعة الواحدة ممكن يكون
/// ليها ظهورين (dayone و daytwo)، فكل ظهور بياخد كائن منفصل هنا عشان
/// حساب التعارض والعرض يتم لكل يوم على حدة.
class TimetableOccurrence {
  final GroupModel group;
  final String day;
  final int startMinutes;
  final int endMinutes;

  /// بيتحسب بعد التجميع: هل الظهور ده متعارض مع ظهور تاني في نفس
  /// اليوم؟ وكام مجموعة بالظبط داخلة في نفس التعارض؟
  int conflictClusterSize = 1;

  /// ترتيب الظهور داخل تعارضه (لعرض البطاقات جنب بعض بدل ما تتراكب) -
  /// 0 يعني أول عمود من اليسار داخل نفس خانة الوقت.
  int conflictIndexInCluster = 0;

  TimetableOccurrence({
    required this.group,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });

  bool get hasConflict => conflictClusterSize > 1;

  int get durationMinutes => endMinutes - startMinutes;
}

/// طبقة منطقية بحتة: تحوّل قائمة مجموعات إلى "ظهورات" مبنية على الوقت،
/// وتكتشف التعارضات ديناميكيًا (بدون أي تخزين في Firestore) - كل مرة
/// تتغيّر المجموعات، الحساب بيعاد من الصفر تلقائيًا لأنه بيشتغل على
/// الـ snapshot الحالي بس.
class TimetableConflictService {
  /// يبني كل الظهورات الممكنة من قائمة المجموعات (كل مجموعة بيومين
  /// ليها ظهور في كل يوم على حدة)، ويحسب التعارضات لكل يوم، ويرجع
  /// خريطة: اليوم -> قائمة الظهورات (بعد ما اتحسبلها التعارض والترتيب).
  static Map<String, List<TimetableOccurrence>> buildSchedule(
    List<GroupModel> groups,
  ) {
    final Map<String, List<TimetableOccurrence>> byDay = {};

    for (final group in groups) {
      final startMin = TimeUtils.parseToMinutes(group.startTime);
      final endMin = TimeUtils.parseToMinutes(group.endTime);
      if (startMin == null || endMin == null || endMin <= startMin) continue;

      for (final day in {group.dayone, group.daytwo}) {
        if (day == null || day.isEmpty) continue;

        byDay
            .putIfAbsent(day, () => [])
            .add(
              TimetableOccurrence(
                group: group,
                day: day,
                startMinutes: startMin,
                endMinutes: endMin,
              ),
            );
      }
    }

    byDay.forEach((day, occurrences) => _detectConflictsForDay(occurrences));

    return byDay;
  }

  /// خوارزمية "خط المسح" (sweep line) القياسية لاكتشاف تجمعات الأوقات
  /// المتداخلة: بترتب الظهورات حسب وقت البداية، وتفتح "تجمّع" (cluster)
  /// جديد كل ما ظهور يبدأ بعد ما آخر تجمّع خلص فعليًا. أي ظهورين تحت
  /// نفس التجمّع بيتحسبوا "متعارضين" حتى لو مش متداخلين مباشرة مع
  /// بعض (زي: أ 9-10، ب 9:30-11، ج 10:30-11:30 -> التلاتة تجمّع واحد
  /// لأن ب بتربط بين أ وج) - ده نفس المنطق اللي تطبيقات المواعيد
  /// الاحترافية (Google/Outlook Calendar) بتستخدمه لتجميع الاجتماعات
  /// المتضاربة، ومعقّديته O(n log n) لكل يوم فقط.
  static void _detectConflictsForDay(List<TimetableOccurrence> occurrences) {
    occurrences.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    int clusterStart = 0;
    int clusterMaxEnd = -1;

    for (int i = 0; i < occurrences.length; i++) {
      final current = occurrences[i];

      if (clusterMaxEnd != -1 && current.startMinutes >= clusterMaxEnd) {
        _finalizeCluster(occurrences, clusterStart, i);
        clusterStart = i;
        clusterMaxEnd = current.endMinutes;
      } else {
        clusterMaxEnd = clusterMaxEnd == -1
            ? current.endMinutes
            : (clusterMaxEnd > current.endMinutes
                  ? clusterMaxEnd
                  : current.endMinutes);
      }
    }

    _finalizeCluster(occurrences, clusterStart, occurrences.length);
  }

  static void _finalizeCluster(
    List<TimetableOccurrence> occurrences,
    int start,
    int end,
  ) {
    final size = end - start;
    for (int i = start; i < end; i++) {
      occurrences[i].conflictClusterSize = size;
      occurrences[i].conflictIndexInCluster = i - start;
    }
  }
}
