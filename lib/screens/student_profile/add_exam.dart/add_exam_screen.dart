import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/Activity_model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';

class AddExamScreen extends StatefulWidget {
  final StudentModel student;
  final String groupId;

  const AddExamScreen({
    super.key,
    required this.student,
    required this.groupId,
  });

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  @override
  void initState() {
    super.initState();
    date = DateTime.now();
  }

  bool useCustomDate = false;
  late DateTime date;
  bool? isPresent = false;
  TextEditingController currentDegreeController = TextEditingController();
  TextEditingController maxDegreeController = TextEditingController();
  TextEditingController examNameController = TextEditingController();

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

  Future<void> addExam() async {
    await FirestorePaths.studentActivities(widget.student.id!).add(
      ActivityModel(
        type: "exam",
        date: date.toIso8601String(),
        groupId: widget.groupId,
        attendancePresent: isPresent,
        examName: examNameController.text.trim(),
        examStatus: isPresent == true ? "حاضر✔" : "غائب❌",
        currentDegree: currentDegreeController.text,
        maxDegree: maxDegreeController.text,
      ).toMap(),
    );
  }

  @override
  void dispose() {
    examNameController.dispose();
    currentDegreeController.dispose();
    maxDegreeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Exam State, ')),
      body: Column(
        children: [
          TextField(
            controller: examNameController,
            decoration: const InputDecoration(
              labelText: "اسم الاختبار",
              border: OutlineInputBorder(),
            ),
          ),
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
          TextField(
            controller: currentDegreeController,
            keyboardType: TextInputType.number,
            enabled: isPresent == true,
            decoration: const InputDecoration(
              labelText: "درجة الطالب",
              border: OutlineInputBorder(),
            ),
          ),
          TextField(
            controller: maxDegreeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "الدرجة النهائية",
              border: OutlineInputBorder(),
            ),
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
                    Icon(present ? Icons.check_circle : Icons.cancel, size: 18),
                    const SizedBox(width: 4),
                    Text(present ? "حاضر✔" : "غائب ❌"),
                  ],
                ),
                selected: isPresent == present,
                onSelected: (_) {
                  setState(() {
                    isPresent = present;

                    if (!present) {
                      currentDegreeController.text = "0";
                    } else {
                      currentDegreeController.clear();
                    }
                  });
                },
              );
            }).toList(),
          ),

          ElevatedButton(
            onPressed: () async {
              if (examNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("أدخل اسم الاختبار")),
                );
                return;
              }

              if (maxDegreeController.text.isEmpty) {
                return;
              }

              if (isPresent == true && currentDegreeController.text.isEmpty) {
                return;
              }

              await addExam();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Add Exam State'),
          ),
        ],
      ),
    );
  }
}
