import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';

const _kNavy = Color(0xFF16213E);
const _kIconBg = Color(0xFFEAF1FB);
const _kCardBorder = Color(0xFFEBEEF3);
const _kPageBg = Color(0xFFF6F8FB);

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
            final selected = selectedSubject == name;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  selectedSubject = name;
                  selectedGrade = null;
                  selectedGroupId = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? _kNavy : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? _kNavy : _kCardBorder),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _kNavy.withValues(alpha: .20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          const BoxShadow(
                            color: Color(0x0A16213E),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: selected ? Colors.white : _kNavy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: "cairo",
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : _kNavy,
                      ),
                    ),
                  ],
                ),
              ),
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
            final selected = selectedGrade == grade;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  selectedGrade = grade;
                  selectedGroupId = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? _kNavy : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? _kNavy : _kCardBorder),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : _kNavy,
                  ),
                ),
              ),
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

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  selectedGroupId = group.id;
                });

                widget.onGroupSelected(group);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedGroupId == group.id
                      ? _kNavy.withValues(alpha: .05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedGroupId == group.id ? _kNavy : _kCardBorder,
                    width: selectedGroupId == group.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedGroupId == group.id
                          ? Icons.check_circle
                          : Icons.radio_button_off,
                      color: _kNavy,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            group.name?.isNotEmpty == true
                                ? group.name!
                                : "المجموعة",
                            style: const TextStyle(
                              fontFamily: "cairo",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${group.dayone} • ${group.daytwo}",
                            style: const TextStyle(
                              fontFamily: "cairo",
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            group.startTime ?? "",
                            style: const TextStyle(
                              fontFamily: "cairo",
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
