import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/activity_model_type.dart';
import 'package:seba/model/student_model.dart';

class EditExamScreen extends StatefulWidget {
  final StudentModel student;
  final ActivityModel activity;

  const EditExamScreen({
    super.key,
    required this.activity,
    required this.student,
  });
  @override
  State<EditExamScreen> createState() => _EditExamScreenState();
}

class _EditExamScreenState extends State<EditExamScreen> {
  final TextEditingController examNameController = TextEditingController();
  final TextEditingController currentDegreeController = TextEditingController();
  final TextEditingController maxDegreeController = TextEditingController();
  bool useCustomDate = false;

  bool? isPresent;
  late DateTime date;

  Future<void> updateExam(String id) async {
    await FirestorePaths.studentActivities(widget.student.id!).doc(id).update({
      "date": date.toIso8601String(),
      "examName": examNameController.text.trim(),
      "examStatus": isPresent! ? "حاضر" : "غائب",
      "currentDegree": currentDegreeController.text,
      "maxDegree": maxDegreeController.text,
    });
  }

  Future<void> pickExamDate() async {
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

    isPresent = widget.activity.examStatus == "حاضر";
    date = DateTime.parse(widget.activity.date!);

    examNameController.text = widget.activity.examName ?? "";
    currentDegreeController.text = widget.activity.currentDegree ?? "";
    maxDegreeController.text = widget.activity.maxDegree ?? "";
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
      appBar: AppBar(title: const Text('Edit Exam State, ')),
      body: Column(
        children: [
          const Text("Edit Exam State"),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Column(
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
                          await pickExamDate();
                        } else {
                          setState(() {
                            date = DateTime.now();
                          });
                        }
                      },
                    ),
                    TextButton(
                      onPressed: useCustomDate ? pickExamDate : null,
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
                              Icon(
                                present ? Icons.check_circle : Icons.cancel,
                                size: 18,
                              ),
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
                              } else if (currentDegreeController.text == "0") {
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

                        if (isPresent == true &&
                            currentDegreeController.text.isEmpty) {
                          return;
                        }

                        await updateExam(widget.activity.id ?? '');
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Update Exam State'),
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
