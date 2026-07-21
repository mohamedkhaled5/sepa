import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/select_group_tree_widget.dart';

/// شاشة إضافة طالب مستقلة تُفتح من الصفحة الرئيسية.
class AddStudentGeneralScreen extends StatefulWidget {
  const AddStudentGeneralScreen({super.key});

  @override
  State<AddStudentGeneralScreen> createState() =>
      _AddStudentGeneralScreenState();
}

class _AddStudentGeneralScreenState extends State<AddStudentGeneralScreen> {
  bool conectWithPhone = false;
  bool conectWithWhatsApp = false;

  final studentNameController = TextEditingController();
  final studentParentNameController = TextEditingController();
  final parentRelationController = TextEditingController();
  final studentPhoneController = TextEditingController();

  final List<GroupModel> selectedGroups = [];

  Future<void> saveStudent() async {
    final doc = FirestorePaths.students.doc();

    final student = StudentModel(
      id: doc.id,
      groupIds: selectedGroups.map((g) => g.id!).toList(),
      name: studentNameController.text,
      parentName: studentParentNameController.text,
      parentRelation: parentRelationController.text,
      phone: studentPhoneController.text,
      conectWithPhone: conectWithPhone,
      conectWithWhatsApp: conectWithWhatsApp,
    );

    await doc.set(student.toJson());
  }

  void _openAddGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: SelectGroupTreeWidget(
              excludeGroupIds: selectedGroups.map((g) => g.id!).toList(),
              onGroupSelected: (GroupModel group) {
                setState(() {
                  selectedGroups.add(group);
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    studentNameController.dispose();
    studentParentNameController.dispose();
    parentRelationController.dispose();
    studentPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة طالب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "مجموعات الطالب",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            if (selectedGroups.isEmpty)
              const Text("لم يتم اختيار أي مجموعة بعد"),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedGroups.map((g) {
                return Chip(
                  label: Text("${g.subject ?? ''} - ${g.grade ?? ''}"),
                  onDeleted: () {
                    setState(() => selectedGroups.remove(g));
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openAddGroupSheet,
              icon: const Icon(Icons.add),
              label: const Text("إضافة مجموعة"),
            ),

            const Divider(height: 40),

            TextField(
              controller: studentNameController,
              decoration: const InputDecoration(
                labelText: ' اسم  الطالب بالكامل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: parentRelationController,
                    decoration: const InputDecoration(
                      labelText: ' صلة ولي الأمر بالطالب   ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: studentParentNameController,
                    decoration: const InputDecoration(
                      labelText: ' اسم  ولي الأمر',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(" اختر وسائل التواصل المناسبه"),
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  label: const Text("الهاتف"),
                  selected: conectWithPhone,
                  onSelected: (value) {
                    setState(() => conectWithPhone = value);
                  },
                ),
                FilterChip(
                  label: const Text("واتساب"),
                  selected: conectWithWhatsApp,
                  onSelected: (value) {
                    setState(() => conectWithWhatsApp = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: studentPhoneController,
              decoration: const InputDecoration(
                labelText: ' رقم  ولي الأمر',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedGroups.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("اختر مجموعة واحدة على الأقل"),
                      ),
                    );
                    return;
                  }
                  if (studentNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل اسم الطالب")),
                    );
                    return;
                  }
                  if (studentPhoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل رقم الطالب")),
                    );
                    return;
                  }
                  if (studentParentNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ادخل اسم ولي الأمر")),
                    );
                    return;
                  }
                  if (parentRelationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ادخل صلة ولي الأمر بالطالب  "),
                      ),
                    );
                    return;
                  }

                  await saveStudent();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حفظ الطالب بنجاح")),
                  );

                  Navigator.pop(context);
                },
                child: const Text("حفظ"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
