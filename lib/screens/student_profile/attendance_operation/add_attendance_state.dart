import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/Activity_model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';

class AddAttendanceState extends StatefulWidget {
  final StudentModel student;
  final String groupId;

  const AddAttendanceState({
    super.key,
    required this.student,
    required this.groupId,
  });

  @override
  State<AddAttendanceState> createState() => _AddAttendanceStateState();
}

class _AddAttendanceStateState extends State<AddAttendanceState> {
  @override
  void initState() {
    super.initState();
    date = DateTime.now();
  }

  bool useCustomDate = false;
  late DateTime date;
  bool? isPresent = false;

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

  Future<void> addAttendance() async {
    await FirestorePaths.studentActivities(widget.student.id!).add(
      ActivityModel(
        type: "attendance",
        date: date.toIso8601String(),
        groupId: widget.groupId,
        attendancePresent: isPresent == true,
      ).toMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Attendance State, ')),
      body: Column(
        children: [
          CheckboxListTile(
            title: const Text("اختيار تاريخ آخر"),
            value: useCustomDate,
            onChanged: (value) async {
              setState(() {
                useCustomDate = value!;
              });

              if (useCustomDate) {
                await pickDate();
              } else {
                setState(() {
                  date = DateTime.now();
                });
              }
            },
          ),
          TextButton(
            onPressed: useCustomDate ? pickDate : null,
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
                    Icon(present ? Icons.check_circle : Icons.cancel, size: 18),
                    const SizedBox(width: 4),
                    Text(present ? "حاضر✔" : "❌"),
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
              await addAttendance();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Add Attendance State'),
          ),
        ],
      ),
    );
  }
}
