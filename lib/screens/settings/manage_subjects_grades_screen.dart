import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/grade_model.dart';
import 'package:seba/model/subject_model.dart';

const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kDanger = Color(0xFFD1483F);
const _kDangerBg = Color(0xFFFBE9E7);

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: "اسم المادة الجديدة",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.menu_book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  await _addItem(
                    FirestorePaths.subjects,
                    subjectController.text,
                  );
                  subjectController.clear();
                },
                icon: const Icon(Icons.add),
                label: const Text("إضافة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: _kIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: _kNavy,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "لا توجد مواد مضافة",
                        style: TextStyle(color: _kHint),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: _kIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book, color: _kNavy),
                      ),
                      title: Text(
                        subject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded, color: _kDanger),
                        onPressed: () => _confirmDelete(
                          FirestorePaths.subjects,
                          subject.id,
                          subject.name,
                        ),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: gradeController,
                  decoration: InputDecoration(
                    hintText: "اسم الصف الجديد",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.school),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  await _addItem(FirestorePaths.grades, gradeController.text);
                  gradeController.clear();
                },
                icon: const Icon(Icons.add),
                label: const Text("إضافة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: _kIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          color: _kNavy,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "لا توجد صفوف مضافة",
                        style: TextStyle(color: _kHint),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: grades.length,
                itemBuilder: (context, index) {
                  final grade = grades[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: _kIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, color: _kNavy),
                      ),
                      title: Text(
                        grade.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded, color: _kDanger),
                        onPressed: () => _confirmDelete(
                          FirestorePaths.grades,
                          grade.id,
                          grade.name,
                        ),
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
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        foregroundColor: _kNavy,
        title: const Text(
          "إدارة المواد والصفوف",
          style: TextStyle(fontWeight: FontWeight.bold, color: _kNavy),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kCardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: _kNavy,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "المواد"),
                  Tab(text: "الصفوف"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSubjectsTab(), _buildGradesTab()],
      ),
    );
  }
}
