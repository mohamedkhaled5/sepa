import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/grade_model.dart';
import 'package:seba/model/subject_model.dart';

/// شاشة إدارة المواد والصفوف الدراسية - خاصة بالمستخدم الحالي فقط.
class ManageSubjectsGradesScreen extends StatefulWidget {
  const ManageSubjectsGradesScreen({super.key});

  @override
  State<ManageSubjectsGradesScreen> createState() =>
      _ManageSubjectsGradesScreenState();
}

class _ManageSubjectsGradesScreenState extends State<ManageSubjectsGradesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final subjectController = TextEditingController();
  final gradeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    subjectController.dispose();
    gradeController.dispose();
    super.dispose();
  }

  Future<void> _addItem(
    CollectionReference<Map<String, dynamic>> collection,
    String name,
  ) async {
    if (name.trim().isEmpty) return;
    await collection.add({'name': name.trim()});
  }

  Future<void> _confirmDelete(
    CollectionReference<Map<String, dynamic>> collection,
    String docId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("حذف"),
        content: Text(
          "هل تريد حذف \"$name\"؟\n"
          "ملاحظة: حذف المادة/الصف هنا لا يحذف المجموعات المرتبطة بها.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await collection.doc(docId).delete();
    }
  }

  Widget _buildSubjectsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: "اسم المادة الجديدة",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  await _addItem(
                    FirestorePaths.subjects,
                    subjectController.text,
                  );
                  subjectController.clear();
                },
                child: const Text("إضافة"),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestorePaths.subjects.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final subjects = (snapshot.data?.docs ?? [])
                  .map((d) => SubjectModel.fromFirestore(d))
                  .toList();

              if (subjects.isEmpty) {
                return const Center(child: Text("لا توجد مواد مضافة بعد"));
              }

              return ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return ListTile(
                    title: Text(subject.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(
                        FirestorePaths.subjects,
                        subject.id,
                        subject.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGradesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(
                    labelText: "اسم الصف الجديد",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  await _addItem(FirestorePaths.grades, gradeController.text);
                  gradeController.clear();
                },
                child: const Text("إضافة"),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestorePaths.grades.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final grades = (snapshot.data?.docs ?? [])
                  .map((d) => GradeModel.fromFirestore(d))
                  .toList();

              if (grades.isEmpty) {
                return const Center(child: Text("لا توجد صفوف مضافة بعد"));
              }

              return ListView.builder(
                itemCount: grades.length,
                itemBuilder: (context, index) {
                  final grade = grades[index];
                  return ListTile(
                    title: Text(grade.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(
                        FirestorePaths.grades,
                        grade.id,
                        grade.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إدارة المواد والصفوف"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "المواد"),
            Tab(text: "الصفوف"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSubjectsTab(), _buildGradesTab()],
      ),
    );
  }
}
