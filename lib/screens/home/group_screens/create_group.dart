import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/grade_model.dart';
import 'package:seba/model/subject_model.dart';

const List<String> _weekDays = [
  "السبت",
  "الأحد",
  "الاثنين",
  "الثلاثاء",
  "الأربعاء",
  "الخميس",
  "الجمعة",
];

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);

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
  String? selectedDayone;
  String? selectedDaytwo;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Future<void> pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => startTime = time);
  }

  Future<void> pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
    if (selectedDayone == null || selectedDaytwo == null) {
      _showSnack("اختر اليوم");
      return false;
    }
    if (startTime == null || endTime == null) {
      _showSnack("حدد وقت الحصة");
      return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveGroup() async {
    if (!_validate()) return;

    final doc = await FirestorePaths.groups.add({
      "name": groupNameController.text.trim(),
      "subject": selectedSubject,
      "grade": selectedGrade,
      "dayone": selectedDayone,
      "daytwo": selectedDaytwo,
      "startTime": startTime!.format(context),
      "endTime": endTime!.format(context),
      "createdAt": DateTime.now().toIso8601String(),
    });
    await doc.get();

    if (!mounted) return;
    _showSnack("تم إنشاء المجموعة");
    Navigator.pop(context);
  }

  Future<void> updateGroup(String groupId) async {
    if (!_validate()) return;

    await FirestorePaths.groups.doc(groupId).update({
      "name": groupNameController.text.trim(),
      "subject": selectedSubject,
      "grade": selectedGrade,
      "dayone": selectedDayone,
      "daytwo": selectedDaytwo,
      "startTime": startTime!.format(context),
      "endTime": endTime!.format(context),
    });

    if (!mounted) return;
    _showSnack("تم تعديل المجموعة");
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
      selectedDayone = widget.group!.dayone;
      selectedDaytwo = widget.group!.daytwo;

      startTime = _parseTime(widget.group!.startTime!);
      endTime = _parseTime(widget.group!.endTime!);
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
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            "لا توجد خيارات مضافة بعد",
                            style: TextStyle(
                              fontFamily: 'cairo',
                              color: _kHint,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
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
                                  color: isSelected ? _kNavy : Colors.black87,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: _kNavy,
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
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
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
                                color: Colors.black87,
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
                    color: _kIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _kNavy, size: 20),
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
        foregroundColor: _kNavy,
        title: Text(
          widget.group == null ? "إنشاء مجموعة" : "تعديل المجموعة",
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: _kIconBg,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/icon/sepa_without_ground.png",
                width: 33,
                height: 33,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ================== اسم المجموعة (حقل نصي فعلي) ==================
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: groupNameController,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _kNavyLight,
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
                icon: Icons.account_balance_rounded,
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

          // ================== اليوم الأول ==================
          _fieldCard(
            icon: Icons.calendar_today_rounded,
            label: "اليوم الأول",
            valueText: selectedDayone,
            placeholder: "اختر اليوم",
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kHint,
            ),
            onTap: () => _showPicker(
              title: "اختر اليوم الأول",
              options: _weekDays,
              currentValue: selectedDayone,
              onSelected: (v) => setState(() => selectedDayone = v),
            ),
          ),

          // ================== اليوم الثاني ==================
          _fieldCard(
            icon: Icons.calendar_today_rounded,
            label: "اليوم الثاني",
            valueText: selectedDaytwo,
            placeholder: "اختر اليوم",
            trailing: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kHint,
            ),
            onTap: () => _showPicker(
              title: "اختر اليوم الثاني",
              options: _weekDays,
              currentValue: selectedDaytwo,
              onSelected: (v) => setState(() => selectedDaytwo = v),
            ),
          ),

          const SizedBox(height: 6),

          // ================== وقت البداية ==================
          _fieldCard(
            icon: Icons.access_time_rounded,
            label: "اختر وقت البداية",
            valueText: startTime?.format(context),
            placeholder: "حدد وقت بداية المجموعة",
            onTap: pickStartTime,
          ),

          // ================== وقت النهاية ==================
          _fieldCard(
            icon: Icons.access_time_filled_rounded,
            label: "اختر وقت النهاية",
            valueText: endTime?.format(context),
            placeholder: "حدد وقت نهاية المجموعة",
            onTap: pickEndTime,
          ),

          const SizedBox(height: 10),

          // ================== زر الحفظ ==================
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (widget.group == null) {
                  saveGroup();
                } else {
                  updateGroup(widget.group!.id!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
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
                  const SizedBox(width: 10),
                  const Icon(Icons.save_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
