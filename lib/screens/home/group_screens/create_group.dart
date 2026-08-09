import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/grade_model.dart';
import 'package:seba/model/subject_model.dart';
import 'package:seba/screens/settings/manage_subjects_grades_screen.dart';

const List<String> _weekDays = [
  "السبت",
  "الأحد",
  "الاثنين",
  "الثلاثاء",
  "الأربعاء",
  "الخميس",
  "الجمعة",
];
const List<int> _numberOfWeekDays = [1, 2, 3, 4, 5, 6, 7];

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kIconBg = Color(0xFFF1F5F9); // خلفية الأيقونات
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kWarning = Color(0xFFF59E0B); // تحذير كهرماني
const _kWarningBg = Color(0xFFFEF3C7); // خلفية التحذير الناعمة

class CreateGroupScreen extends StatefulWidget {
  final GroupModel? group;
  const CreateGroupScreen({super.key, this.group});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();

  String? selectedSubject;
  String? selectedGrade;

  int selectedNumOfDays = 2;
  List<String> selectedDaysName = ["السبت", "الأحد"];

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Future<void> pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => startTime = time);
  }

  Future<void> pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => endTime = time);
  }

  bool _validate() {
    if (groupNameController.text.trim().isEmpty) {
      _showSnack("اكتب اسم المجموعة");
      return false;
    }
    if (selectedSubject == null) {
      _showSnack("اختر المادة");
      return false;
    }
    if (selectedGrade == null) {
      _showSnack("اختر الصف");
      return false;
    }
    if (selectedDaysName.isEmpty) {
      _showSnack("اختر أيام المجموعة");
      return false;
    }
    if (startTime == null || endTime == null) {
      _showSnack("حدد وقت الحصة");
      return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'cairo')),
      ),
    );
  }

  Future<void> saveGroup() async {
    if (!_validate()) return;

    final doc = await FirestorePaths.groups.add({
      "name": groupNameController.text.trim(),
      "subject": selectedSubject,
      "grade": selectedGrade,
      "daysName": selectedDaysName,
      "startTime": startTime!.format(context),
      "endTime": endTime!.format(context),
      "createdAt": DateTime.now().toIso8601String(),
    });
    await doc.get();

    if (!mounted) return;
    _showSnack("تم إنشاء المجموعة بنجاح");
    Navigator.pop(context);
  }

  Future<void> updateGroup(String groupId) async {
    if (!_validate()) return;

    await FirestorePaths.groups.doc(groupId).update({
      "name": groupNameController.text.trim(),
      "subject": selectedSubject,
      "grade": selectedGrade,
      "daysName": selectedDaysName,
      "startTime": startTime!.format(context),
      "endTime": endTime!.format(context),
    });

    if (!mounted) return;
    _showSnack("تم تعديل المجموعة بنجاح");
    Navigator.pop(context);
  }

  TimeOfDay _parseTime(String time) {
    final now = DateTime.now();
    final dateTime = DateTime.parse(
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
      "${_convertTo24Hour(time)}",
    );
    return TimeOfDay.fromDateTime(dateTime);
  }

  String _convertTo24Hour(String time) {
    final parts = time.split(" ");
    final hm = parts[0].split(":");
    int hour = int.parse(hm[0]);
    final minute = hm[1];
    final period = parts[1];

    if (period == "PM" && hour != 12) hour += 12;
    if (period == "AM" && hour == 12) hour = 0;

    return "${hour.toString().padLeft(2, '0')}:$minute:00";
  }

  @override
  void initState() {
    super.initState();

    if (widget.group != null) {
      groupNameController.text = widget.group!.name ?? "";
      selectedSubject = widget.group!.subject;
      selectedGrade = widget.group!.grade;

      selectedDaysName = List<String>.from(widget.group!.daysName ?? []);
      selectedNumOfDays = selectedDaysName.length;

      if (widget.group!.startTime != null) {
        startTime = _parseTime(widget.group!.startTime!);
      }
      if (widget.group!.endTime != null) {
        endTime = _parseTime(widget.group!.endTime!);
      }
    } else {
      selectedNumOfDays = 2;
      selectedDaysName = List.generate(
        selectedNumOfDays,
        (index) => _weekDays[index],
      );
    }
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  // ================== بوتوم شيت اختيار عام (مادة/صف/يوم) ==================
  Future<void> _showPicker({
    required String title,
    required List<String> options,
    required String? currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kCardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: options.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ManageSubjectsGradesScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "إضافة مادة أو صفوف جديدة",
                                  style: TextStyle(
                                    fontFamily: 'cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "لا توجد خيارات مضافة بعد",
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  color: _kHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: _kCardBorder),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = option == currentValue;
                            return ListTile(
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected ? _kPrimary : _kNavy,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: _kPrimary,
                                    )
                                  : null,
                              onTap: () {
                                onSelected(option);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================== عنصر البطاقة العام لكل حقل ==================
  Widget _fieldCard({
    required IconData icon,
    required String label,
    required String? valueText,
    required String placeholder,
    Widget? trailing,
    VoidCallback? onTap,
    Widget? customChild,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (trailing != null) trailing,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        customChild ??
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _kNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              valueText ?? placeholder,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 12.5,
                                color: valueText == null ? _kHint : _kNavyLight,
                                fontWeight: valueText == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _kPrimary, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        title: Text(
          widget.group == null ? "إنشاء مجموعة" : "تعديل المجموعة",
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _kNavy,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  "assets/icon/sapeel.png",
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ================== اسم المجموعة ==================
          _fieldCard(
            icon: Icons.groups_2_rounded,
            label: "اسم المجموعة",
            valueText: null,
            placeholder: "",
            customChild: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "اسم المجموعة",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: groupNameController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kNavy,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: "اكتب اسم المجموعة",
                    hintStyle: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.5,
                      color: _kHint,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================== المادة ==================
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestorePaths.subjects.snapshots(),
            builder: (context, snapshot) {
              final subjects = (snapshot.data?.docs ?? [])
                  .map((d) => SubjectModel.fromFirestore(d).name)
                  .toList();

              return _fieldCard(
                icon: Icons.menu_book_rounded,
                label: "المادة",
                valueText: selectedSubject,
                placeholder: "اختر المادة",
                trailing: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _kHint,
                ),
                onTap: () => _showPicker(
                  title: "اختر المادة",
                  options: subjects,
                  currentValue: selectedSubject,
                  onSelected: (v) => setState(() => selectedSubject = v),
                ),
              );
            },
          ),

          // ================== الصف الدراسي ==================
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestorePaths.grades.snapshots(),
            builder: (context, snapshot) {
              final grades = (snapshot.data?.docs ?? [])
                  .map((d) => GradeModel.fromFirestore(d).name)
                  .toList();

              return _fieldCard(
                icon: Icons.school_rounded,
                label: "الصف الدراسي",
                valueText: selectedGrade,
                placeholder: "اختر الصف",
                trailing: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _kHint,
                ),
                onTap: () => _showPicker(
                  title: "اختر الصف الدراسي",
                  options: grades,
                  currentValue: selectedGrade,
                  onSelected: (v) => setState(() => selectedGrade = v),
                ),
              );
            },
          ),

          // ================== عدد أيام المجموعة ==================
          _fieldCard(
            icon: Icons.calendar_month_rounded,
            label: "عدد أيام المجموعة",
            valueText: "$selectedNumOfDays أيام",
            placeholder: "",
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kHint,
            ),
            onTap: () => _showPicker(
              title: "اختر عدد أيام المجموعة",
              options: _numberOfWeekDays.map((e) => e.toString()).toList(),
              currentValue: selectedNumOfDays.toString(),
              onSelected: (v) {
                setState(() {
                  selectedNumOfDays = int.parse(v);

                  if (selectedDaysName.length < selectedNumOfDays) {
                    while (selectedDaysName.length < selectedNumOfDays) {
                      selectedDaysName.add(_weekDays[0]);
                    }
                  } else {
                    selectedDaysName = selectedDaysName.sublist(
                      0,
                      selectedNumOfDays,
                    );
                  }
                });
              },
            ),
          ),

          // ================== أيام الدرس ==================
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: selectedNumOfDays,
            itemBuilder: (context, index) => _fieldCard(
              icon: Icons.event_repeat_rounded,
              label: 'اليوم ${index + 1}',
              valueText: selectedDaysName[index],
              placeholder: "اختر اليوم",
              trailing: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _kHint,
              ),
              onTap: () => _showPicker(
                title: "اختر اليوم",
                options: _weekDays,
                currentValue: selectedDaysName[index],
                onSelected: (v) => setState(() => selectedDaysName[index] = v),
              ),
            ),
          ),

          // ================== وقت البداية ==================
          _fieldCard(
            icon: Icons.schedule_rounded,
            label: "وقت البداية",
            valueText: startTime?.format(context),
            placeholder: "حدد وقت بداية المجموعة",
            onTap: pickStartTime,
          ),

          // ================== وقت النهاية ==================
          _fieldCard(
            icon: Icons.timer_off_rounded,
            label: "وقت النهاية",
            valueText: endTime?.format(context),
            placeholder: "حدد وقت نهاية المجموعة",
            onTap: pickEndTime,
          ),

          const SizedBox(height: 8),

          // ================== زر الحفظ ==================
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (widget.group == null) {
                  saveGroup();
                } else {
                  updateGroup(widget.group!.id!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.group == null ? "حفظ المجموعة" : "تعديل المجموعة",
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================== تنبيه وتوجيه للإعدادات ==================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kWarningBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kWarning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'لإضافة مواد أو صفوف دراسية جديدة، انتقل إلى صفحة الإعدادات من القائمة الرئيسية، ثم اضغط على صفحة "المواد والصفوف".',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 12.5,
                      color: Colors.amber.shade900,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kWarning.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: _kWarning,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
