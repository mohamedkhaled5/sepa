import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/screens/student/add_student_general_screen.dart';
import 'package:seba/screens/home/group_screens/create_group.dart';
import 'package:seba/screens/home/group_screens/student_display_screen/student_display_screen.dart';
import 'package:seba/screens/settings/settings_screen.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/firestore_path.dart';

class GroupsDisplayScreen extends StatefulWidget {
  const GroupsDisplayScreen({super.key});

  @override
  State<GroupsDisplayScreen> createState() => _GroupsDisplayScreenState();
}

class _GroupsDisplayScreenState extends State<GroupsDisplayScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>> get groupsStream =>
      FirestorePaths.groups.orderBy("createdAt", descending: true).snapshots();

  // delete group======================================================
  Future<void> deleteGroup(GroupModel group) async {
    final randomNumber = (100 + DateTime.now().millisecond % 900).toString();

    final controller = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("⚠️ حذف المجموعة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "سيتم حذف المجموعة وجميع الطلاب وسجلاتهم نهائياً.\n\n"
                "اكتب الرقم التالي للتأكيد:",
              ),
              const SizedBox(height: 15),
              Text(
                randomNumber,
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "اكتب الرقم هنا",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == randomNumber) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text("حذف"),
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

    if (mounted) {
      Navigator.pop(context);
    }
  }

  // delete group data (والطلاب المرتبطين بها فقط عبر groupIds array) =======
  Future<void> _deleteGroupData(String groupId) async {
    final students = await FirestorePaths.students
        .where("groupIds", arrayContains: groupId)
        .get();

    final batch = FirebaseFirestore.instance.batch();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المجموعات"),
        actions: [
          IconButton(
            tooltip: "الإعدادات",
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
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
            return const Center(child: Text("لا توجد مجموعات"));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = GroupModel.fromFirestore(groups[index]);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Dismissible(
                  key: Key(group.id!),
                  direction: AppSession.hasPermission('editGroup')
                      ? DismissDirection.startToEnd
                      : DismissDirection.none,
                  confirmDismiss: (direction) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateGroupScreen(group: group),
                      ),
                    );
                    return false;
                  },
                  background: Container(
                    color: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white),
                        SizedBox(width: 8),
                        Text("تعديل", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.groups)),
                    title: Text(group.name ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.subject ?? ""),
                        Text(group.grade ?? ""),
                        Text("${group.dayone} و ${group.daytwo}   "),
                        Text("${group.startTime ?? ""} "),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentDisplayScreen(groupId: group.id!),
                        ),
                      );
                    },
                    onLongPress: AppSession.hasPermission('deleteGroup')
                        ? () async {
                            await deleteGroup(group);
                          }
                        : null,
                  ),
                ),
              );
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddStudentGeneralScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text("طالب"),
            ),
            const SizedBox(width: 12),
          ],
          if (AppSession.hasPermission('createGroup'))
            FloatingActionButton(
              heroTag: "addGroup",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }
}
