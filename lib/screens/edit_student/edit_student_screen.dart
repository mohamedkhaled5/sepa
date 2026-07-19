import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/add_student/select_group_tree_widget.dart';

class EditStudentScreen extends StatefulWidget {
  const EditStudentScreen({super.key, required this.student});

  final StudentModel student;

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late TextEditingController nameController;
  late TextEditingController parentController;
  late TextEditingController phoneController;
  late TextEditingController parentRelationController;

  bool conectWithPhone = false;
  bool conectWithWhatsApp = false;

  late List<String> currentGroupIds;

  Future<void> updateStudent() async {
    await FirestorePaths.students.doc(widget.student.id).update({
      "name": nameController.text,
      "phone": phoneController.text,
      "parentName": parentController.text,
      "parentRelation": parentRelationController.text,
      "conectWithPhone": conectWithPhone,
      "conectWithWhatsApp": conectWithWhatsApp,
      "groupIds": currentGroupIds,
    });
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.student.name);
    phoneController = TextEditingController(text: widget.student.phone);
    parentController = TextEditingController(text: widget.student.parentName);
    parentRelationController = TextEditingController(
      text: widget.student.parentRelation,
    );

    conectWithPhone = widget.student.conectWithPhone ?? false;
    conectWithWhatsApp = widget.student.conectWithWhatsApp ?? false;

    currentGroupIds = List<String>.from(widget.student.groupIds);
  }

  @override
  void dispose() {
    parentRelationController.dispose();
    nameController.dispose();
    phoneController.dispose();
    parentController.dispose();
    super.dispose();
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
              excludeGroupIds: currentGroupIds,
              onGroupSelected: (GroupModel group) {
                setState(() {
                  if (!currentGroupIds.contains(group.id)) {
                    currentGroupIds.add(group.id!);
                  }
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupChip(String groupId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirestorePaths.groups.doc(groupId).get(),
      builder: (context, snapshot) {
        String label = groupId;
        if (snapshot.hasData && snapshot.data!.exists) {
          final group = GroupModel.fromFirestore(snapshot.data!);
          label =
              "${group.subject ?? ''} - ${group.grade ?? ''} (${group.dayone ?? ''})";
        }
        return Chip(
          label: Text(label),
          onDeleted: () {
            setState(() {
              currentGroupIds.remove(groupId);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تعديل")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
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
                    controller: parentController,
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
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: ' رقم  ولي الأمر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "مجموعات الطالب",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            if (currentGroupIds.isEmpty)
              const Text("الطالب غير مسجل في أي مجموعة بعد"),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentGroupIds
                  .map((gid) => _buildGroupChip(gid))
                  .toList(),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openAddGroupSheet,
              icon: const Icon(Icons.add),
              label: const Text("إضافة / نقل لمجموعة"),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (currentGroupIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "يجب إضافة الطالب لمجموعة واحدة على الأقل",
                        ),
                      ),
                    );
                    return;
                  }

                  await updateStudent();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم تحديث الطالب بنجاح")),
                  );

                  Navigator.pop(context);
                },
                child: const Text("تحديث"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
