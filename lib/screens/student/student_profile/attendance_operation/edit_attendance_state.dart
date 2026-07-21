import 'package:flutter/material.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/features/auth/firestore_path.dart';

class EditAttendanceState extends StatefulWidget {
  final StudentModel student;
  final ActivityModel activity;

  const EditAttendanceState({
    super.key,
    required this.student,
    required this.activity,
  });
  @override
  State<EditAttendanceState> createState() => _EditAttendanceStateState();
}

class _EditAttendanceStateState extends State<EditAttendanceState> {
  bool? isPresent;
  late DateTime date;
  bool editDate = false;

  Future<void> updateAttendance(String id) async {
    await FirestorePaths.studentActivities(widget.student.id!).doc(id).update({
      "date": date.toIso8601String(),
      "attendancePresent": isPresent!,
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        date = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    isPresent = widget.activity.attendancePresent;
    date = DateTime.parse(widget.activity.date ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Attendance State, ')),
      body: Column(
        children: [
          const Text("Edit Attendance State"),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text("تعديل التاريخ"),
                      value: editDate,
                      onChanged: (value) {
                        setState(() {
                          editDate = value!;
                        });
                      },
                    ),
                    TextButton(
                      onPressed: editDate ? pickDate : null,
                      child: Text("${date.day}/${date.month}/${date.year}"),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [true, false].map((present) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 4),
                              Icon(
                                present ? Icons.check_circle : Icons.cancel,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(present ? "حاضر✔" : "❌غائب"),
                            ],
                          ),
                          selected: isPresent == present,
                          onSelected: (selected) {
                            setState(() {
                              isPresent = present;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        await updateAttendance(widget.activity.id ?? '');
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Update Attendance State'),
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
}
