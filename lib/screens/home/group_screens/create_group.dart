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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("اكتب اسم المجموعة")));
      return false;
    }
    if (selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("اختر المادة")));
      return false;
    }
    if (selectedGrade == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("اختر الصف")));
      return false;
    }
    if (selectedDayone == null || selectedDaytwo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("اختر اليوم")));
      return false;
    }
    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("حدد وقت الحصة")));
      return false;
    }
    return true;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("تم إنشاء المجموعة")));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("تم تعديل المجموعة")));
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

  Widget _buildSubjectDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.subjects.snapshots(),
      builder: (context, snapshot) {
        final subjects = (snapshot.data?.docs ?? [])
            .map((d) => SubjectModel.fromFirestore(d))
            .toList();

        return DropdownButtonFormField<String>(
          value: subjects.any((s) => s.name == selectedSubject)
              ? selectedSubject
              : null,
          decoration: const InputDecoration(
            labelText: "المادة",
            border: OutlineInputBorder(),
          ),
          items: subjects
              .map((s) => DropdownMenuItem(value: s.name, child: Text(s.name)))
              .toList(),
          onChanged: (value) => setState(() => selectedSubject = value),
        );
      },
    );
  }

  Widget _buildGradeDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.grades.snapshots(),
      builder: (context, snapshot) {
        final grades = (snapshot.data?.docs ?? [])
            .map((d) => GradeModel.fromFirestore(d))
            .toList();

        return DropdownButtonFormField<String>(
          value: grades.any((g) => g.name == selectedGrade)
              ? selectedGrade
              : null,
          decoration: const InputDecoration(
            labelText: "الصف الدراسي",
            border: OutlineInputBorder(),
          ),
          items: grades
              .map((g) => DropdownMenuItem(value: g.name, child: Text(g.name)))
              .toList(),
          onChanged: (value) => setState(() => selectedGrade = value),
        );
      },
    );
  }

  Widget _buildDayDropdown({
    required String? value,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _weekDays
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group == null ? "إنشاء مجموعة" : "تعديل المجموعة"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: groupNameController,
            decoration: const InputDecoration(
              labelText: "اسم المجموعة",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          _buildSubjectDropdown(),
          const SizedBox(height: 16),

          _buildGradeDropdown(),
          const SizedBox(height: 16),

          _buildDayDropdown(
            value: selectedDayone,
            label: "اليوم الأول",
            onChanged: (v) => setState(() => selectedDayone = v),
          ),
          const SizedBox(height: 20),

          _buildDayDropdown(
            value: selectedDaytwo,
            label: "اليوم الثاني",
            onChanged: (v) => setState(() => selectedDaytwo = v),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: pickStartTime,
            child: Text(
              startTime == null
                  ? "اختر وقت البداية"
                  : "البداية: ${startTime!.format(context)}",
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: pickEndTime,
            child: Text(
              endTime == null
                  ? "اختر وقت النهاية"
                  : "النهاية: ${endTime!.format(context)}",
            ),
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              if (widget.group == null) {
                saveGroup();
              } else {
                updateGroup(widget.group!.id!);
              }
            },
            child: Text(
              widget.group == null ? "حفظ المجموعة" : "تعديل المجموعة",
            ),
          ),
        ],
      ),
    );
  }
}
