import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/screens/home/group_screens/create_group.dart';
import 'package:seba/screens/home/group_screens/student_display_screen/student_display_screen.dart';
import 'package:seba/screens/settings/settings_screen.dart';
import 'package:seba/screens/student/add_student_general_screen.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kNavyLight = Color(0xFF24365C);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kDanger = Color(0xFFD1483F);

class GroupsDisplayScreen extends StatefulWidget {
  const GroupsDisplayScreen({super.key});

  @override
  State<GroupsDisplayScreen> createState() => _GroupsDisplayScreenState();
}

class _GroupsDisplayScreenState extends State<GroupsDisplayScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>> get groupsStream =>
      FirestorePaths.groups.orderBy("createdAt", descending: true).snapshots();

  Future<void> deleteGroup(GroupModel group) async {
    final randomNumber = (100 + DateTime.now().millisecond % 900).toString();
    final controller = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "⚠️ حذف المجموعة",
            style: TextStyle(fontFamily: 'cairo', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "سيتم حذف المجموعة وجميع الطلاب وسجلاتهم نهائياً.\n\n"
                "اكتب الرقم التالي للتأكيد:",
                style: TextStyle(fontFamily: 'cairo'),
              ),
              const SizedBox(height: 15),
              Text(
                randomNumber,
                style: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 30,
                  color: _kDanger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "اكتب الرقم هنا",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء", style: TextStyle(fontFamily: 'cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kDanger),
              onPressed: () {
                if (controller.text == randomNumber)
                  Navigator.pop(context, true);
              },
              child: const Text(
                "حذف",
                style: TextStyle(fontFamily: 'cairo', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await _deleteGroupData(group.id!);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteGroupData(String groupId) async {
    final firestore = FirebaseFirestore.instance;

    final students = await FirestorePaths.students
        .where("groupIds", arrayContains: groupId)
        .get();

    final batch = firestore.batch();

    for (final studentDoc in students.docs) {
      final data = studentDoc.data();
      final groupIds = List<String>.from(data["groupIds"] ?? []);

      if (groupIds.length <= 1) {
        final activities = await studentDoc.reference
            .collection("activities")
            .get();
        for (final activity in activities.docs) {
          batch.delete(activity.reference);
        }
        batch.delete(studentDoc.reference);
      } else {
        groupIds.remove(groupId);
        batch.update(studentDoc.reference, {"groupIds": groupIds});
      }
    }

    batch.delete(FirestorePaths.groups.doc(groupId));
    await batch.commit();
  }

  Widget _miniTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 10.5,
              color: _kNavy,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: _kNavy),
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Dismissible(
        key: Key(group.id!),
        direction: AppSession.hasPermission('editGroup')
            ? DismissDirection.startToEnd
            : DismissDirection.none,
        confirmDismiss: (direction) async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateGroupScreen(group: group)),
          );
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            color: _kNavy,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.edit, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "تعديل",
                style: TextStyle(fontFamily: 'cairo', color: Colors.white),
              ),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDisplayScreen(groupId: group.id!),
                ),
              );
            },
            onLongPress: AppSession.hasPermission('deleteGroup')
                ? () async => await deleteGroup(group)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _kHint,
                    size: 16,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            group.name ?? "",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${group.subject ?? ''} - ${group.grade ?? ''}",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'cairo',
                              fontSize: 12.5,
                              color: _kNavyLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            alignment: WrapAlignment.end,
                            children: [
                              _miniTag(
                                Icons.calendar_today_rounded,
                                "${group.dayone} و ${group.daytwo}",
                              ),
                              _miniTag(
                                Icons.access_time_rounded,
                                group.startTime ?? "",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: _kNavy,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
          "المجموعات",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: _kNavy,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(21),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: _kNavy,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: _kNavy,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "لا توجد مجموعات بعد\nاضغط + لإنشاء أول مجموعة",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = GroupModel.fromFirestore(groups[index]);
              return _buildGroupCard(group);
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (AppSession.hasPermission('createStudent')) ...[
            FloatingActionButton.extended(
              heroTag: "addStudentGeneral",
              backgroundColor: Colors.white,
              foregroundColor: _kNavy,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _kCardBorder),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddStudentGeneralScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text("طالب", style: TextStyle(fontFamily: 'cairo')),
            ),
            const SizedBox(width: 12),
          ],
          if (AppSession.hasPermission('createGroup'))
            FloatingActionButton(
              heroTag: "addGroup",
              backgroundColor: _kNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
