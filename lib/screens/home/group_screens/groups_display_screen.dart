import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 أضفنا استيراد الفايربيز أوث
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/features/auth/firestore_path.dart';
import 'package:seba/features/subscription/presentation/screens/admin_create_code_screen.dart';
import 'package:seba/model/group_model.dart';
import 'package:seba/screens/home/group_screens/create_group.dart';
import 'package:seba/screens/home/group_screens/student_display_screen/general_student_display_screen.dart';
import 'package:seba/screens/home/group_screens/student_display_screen/student_display_screen.dart';
import 'package:seba/screens/settings/settings_screen.dart';
import 'package:seba/screens/student/add_student_general_screen.dart';
import 'package:seba/screens/timetable/timetable_screen.dart';

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
  // 🟢 1. متغيرات التحكم في وضع التحديد المتعدد
  bool _isSelectionMode = false;
  final Set<String> _selectedGroupIds = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> get groupsStream =>
      FirestorePaths.groups.orderBy("createdAt", descending: true).snapshots();
  // 🟢 2. التبديل في حالة التحديد عند الضغط على عنصر
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedGroupIds.contains(id)) {
        _selectedGroupIds.remove(id);
        if (_selectedGroupIds.isEmpty) {
          _isSelectionMode =
              false; // الخروج من وضع التحديد إذا أصبحت القائمة فارغة
        }
      } else {
        _selectedGroupIds.add(id);
      }
    });
  }

  // 🟢 دالة الحذف الجماعي للمجموعات المحددة مع تأكيد برقم من 8 أرقام
  Future<void> _deleteSelectedGroups() async {
    // 1. توليد رقم تأكيدي من 8 أرقام عشوائياً
    final String confirmationCode = (10000000 + Random().nextInt(90000000))
        .toString();

    // 2. عرض نافذة التأكيد مع حقل الإدخال
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        bool isButtonEnabled = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "⚠️ تأكيد الحذف النهائي",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  color: _kDanger,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "هل أنت متأكد من حذف (${_selectedGroupIds.length}) من المجموعات المحددة؟\nسيتم حذف كافة البيانات المرتبطة بها نهائياً.",
                    style: const TextStyle(fontFamily: 'cairo', fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "أدخل رمز التأكيد التالي لتأكيد الحذف:",
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          confirmationCode,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: _kNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: "أدخل 8 أرقام هنا",
                      hintStyle: const TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kNavy, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        isButtonEnabled = (val.trim() == confirmationCode);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(fontFamily: 'cairo'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: isButtonEnabled
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text(
                    "حذف الكل",
                    style: TextStyle(fontFamily: 'cairo', color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (String groupId in _selectedGroupIds) {
        final students = await FirestorePaths.students
            .where("groupIds", arrayContains: groupId)
            .get();

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
      }

      await batch.commit();

      setState(() {
        _selectedGroupIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الحذف: $e")));
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

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
                if (controller.text == randomNumber) {
                  Navigator.pop(context, true);
                }
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
    final isSelected = _selectedGroupIds.contains(group.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? _kNavy : _kCardBorder,
          width: isSelected ? 2 : 1,
        ),
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
        direction: AppSession.hasPermission('editGroup') && !_isSelectionMode
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
              if (_isSelectionMode) {
                _toggleSelection(group.id!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentDisplayScreen(groupId: group.id!),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!AppSession.hasPermission('deleteGroup')) return;
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedGroupIds.add(group.id!);
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      activeColor: _kNavy,
                      onChanged: (_) => _toggleSelection(group.id!),
                    )
                  else
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
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: _kNavy,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedGroupIds.clear();
                  });
                },
              ),
              title: Text(
                "تم تحديد ${_selectedGroupIds.length}",
                style: const TextStyle(
                  fontFamily: 'cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                // زر تحديد الكل / إلغاء تحديد الكل
                // زر تحديد الكل / إلغاء تحديد الكل
                IconButton(
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  tooltip: "تحديد الكل",
                  onPressed: () async {
                    // جلب كل المعرفات الحالية للمجموعات
                    final snapshot = await FirestorePaths.groups.get();
                    final allIds = snapshot.docs.map((d) => d.id).toList();

                    setState(() {
                      if (_selectedGroupIds.length == allIds.length) {
                        _selectedGroupIds.clear();
                      } else {
                        _selectedGroupIds.addAll(allIds);
                      }
                    });
                  },
                ),
                // زر الحذف المتعدد
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  tooltip: "حذف المحددة",
                  onPressed: _selectedGroupIds.isEmpty
                      ? null
                      : () => _deleteSelectedGroups(),
                ),
              ],
            )
          : AppBar(
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
                // 1. زر لوحة تحكم الأدمن
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final isAdmin = userData?['role'] == 'admin';

                    if (!isAdmin) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(21),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCreateCodeScreen(),
                            ),
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
                            Icons.admin_panel_settings_rounded,
                            color: _kNavy,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 2. زر الإعدادات
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(21),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
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

                // 3. زر الجدول الزمني
                IconButton(
                  icon: const Icon(Icons.calendar_view_week_rounded),
                  tooltip: "الجدول الزمني",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimetableScreen()),
                  ),
                ),

                // 4. زر جميع الطلاب
                IconButton(
                  icon: const Icon(Icons.groups_rounded, color: _kNavy),
                  tooltip: "جميع الطلاب",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const GeneralStudentDisplayScreen(),
                      ),
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
