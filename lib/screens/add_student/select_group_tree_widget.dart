import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';

/// ويدجت قابل لإعادة الاستخدام لاختيار مجموعة عبر شجرة:
/// مادة -> صف دراسي (متاح فعليًا لهذه المادة) -> معاد (مجموعة فعلية).
/// كل البيانات هنا خاصة بالمستخدم الحالي فقط عبر FirestorePaths.
class SelectGroupTreeWidget extends StatefulWidget {
  final void Function(GroupModel selectedGroup) onGroupSelected;
  final List<String> excludeGroupIds;

  const SelectGroupTreeWidget({
    super.key,
    required this.onGroupSelected,
    this.excludeGroupIds = const [],
  });

  @override
  State<SelectGroupTreeWidget> createState() => _SelectGroupTreeWidgetState();
}

class _SelectGroupTreeWidgetState extends State<SelectGroupTreeWidget> {
  String? selectedSubject;
  String? selectedGrade;
  String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "اختر المادة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildSubjectsStep(),

        if (selectedSubject != null) ...[
          const SizedBox(height: 20),
          const Text(
            "اختر الصف الدراسي",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildGradesStep(),
        ],

        if (selectedSubject != null && selectedGrade != null) ...[
          const SizedBox(height: 20),
          const Text(
            "اختر المعاد",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildGroupsStep(),
        ],
      ],
    );
  }

  Widget _buildSubjectsStep() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.subjects.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('حدث خطأ: ${snapshot.error}');
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text("لا توجد مواد مضافة بعد");
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: docs.map((doc) {
            final name = doc.data()['name'] as String? ?? '';
            return ChoiceChip(
              label: Text(name),
              selected: selectedSubject == name,
              onSelected: (_) {
                setState(() {
                  selectedSubject = name;
                  selectedGrade = null;
                  selectedGroupId = null;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGradesStep() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.groups
          .where('subject', isEqualTo: selectedSubject)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('حدث خطأ: ${snapshot.error}');
        }

        final docs = snapshot.data?.docs ?? [];

        final grades = <String>{};
        for (final doc in docs) {
          final grade = doc.data()['grade'] as String?;
          if (grade != null && grade.isNotEmpty) {
            grades.add(grade);
          }
        }

        if (grades.isEmpty) {
          return const Text("لا توجد مجموعات بهذه المادة بعد");
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: grades.map((grade) {
            return ChoiceChip(
              label: Text(grade),
              selected: selectedGrade == grade,
              onSelected: (_) {
                setState(() {
                  selectedGrade = grade;
                  selectedGroupId = null;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGroupsStep() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.groups
          .where('subject', isEqualTo: selectedSubject)
          .where('grade', isEqualTo: selectedGrade)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('حدث خطأ: ${snapshot.error}');
        }

        final allGroups = (snapshot.data?.docs ?? [])
            .map((doc) => GroupModel.fromFirestore(doc))
            .where((g) => !widget.excludeGroupIds.contains(g.id))
            .toList();

        if (allGroups.isEmpty) {
          return const Text("لا توجد معادين متاحين لهذا الاختيار");
        }

        return Column(
          children: allGroups.map((group) {
            final label =
                "${group.dayone ?? ''} و ${group.daytwo ?? ''} - ${group.startTime ?? ''}"
                "${(group.name?.isNotEmpty ?? false) ? ' (${group.name})' : ''}";

            return RadioListTile<String>(
              title: Text(label),
              value: group.id ?? '',
              groupValue: selectedGroupId,
              onChanged: (_) {
                setState(() {
                  selectedGroupId = group.id;
                });
                widget.onGroupSelected(group);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
