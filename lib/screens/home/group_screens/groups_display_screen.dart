import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

// ================== نظام الألوان الحديث والموحد ==================
const _kNavy = Color(0xFF0F172A);
const _kNavyLight = Color(0xFF1E293B);
const _kPrimaryBlue = Color(0xFF2563EB);
const _kIconBg = Color(0xFFF1F5F9);
const _kPageBg = Color(0xFFF8FAFC);
const _kHint = Color(0xFF64748B);
const _kCardBorder = Color(0xFFE2E8F0);
const _kDanger = Color(0xFFEF4444);

class GroupsDisplayScreen extends StatefulWidget {
  const GroupsDisplayScreen({super.key});

  @override
  State<GroupsDisplayScreen> createState() => _GroupsDisplayScreenState();
}

class _GroupsDisplayScreenState extends State<GroupsDisplayScreen> {
  // متغيرات التحديد المتعدد
  bool _isSelectionMode = false;
  final Set<String> _selectedGroupIds = {};

  Stream<QuerySnapshot<Map<String, dynamic>>> get groupsStream =>
      FirestorePaths.groups.orderBy("createdAt", descending: true).snapshots();

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedGroupIds.contains(id)) {
        _selectedGroupIds.remove(id);
        if (_selectedGroupIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedGroupIds.add(id);
      }
    });
  }

  // الحذف الجماعي مع الحفاظ على المنطق الكامل
  Future<void> _deleteSelectedGroups() async {
    final String confirmationCode = (10000000 + Random().nextInt(90000000))
        .toString();

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
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _kDanger, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "تأكيد الحذف النهائي",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kDanger,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "هل أنت متأكد من حذف (${_selectedGroupIds.length}) من المجموعات المحددة؟\nسيتم حذف كافة البيانات المرتبطة بها نهائياً.",
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13.5,
                      color: _kNavyLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kIconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kCardBorder),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "أدخل رمز التأكيد التالي لتأكيد الحذف:",
                          style: TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 12,
                            color: _kHint,
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
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(fontFamily: 'cairo', color: _kNavyLight),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

  Widget _miniTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kIconBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kNavyLight,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 13, color: _kPrimaryBlue),
        ],
      ),
    );
  }

  // بناء بطاقة المجموعة مع خفة الحركة وأنيميشن التحديد
  Widget _buildAnimatedGroupCard(GroupModel group, int index) {
    final isSelected = _selectedGroupIds.contains(group.id);

    // حساب تأخير متدرج خفيف جداً لظهور القائمة بدون بطء
    final double animationDelay = min(index * 0.05, 0.3);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 15),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kPrimaryBlue : _kCardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _kPrimaryBlue.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
              MaterialPageRoute(
                builder: (_) => CreateGroupScreen(group: group),
              ),
            );
            return false;
          },
          background: Container(
            decoration: BoxDecoration(
              color: _kPrimaryBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  "تعديل",
                  style: TextStyle(
                    fontFamily: 'cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // أيقونة التحديد أو السهم اليساري
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              activeColor: _kPrimaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (_) => _toggleSelection(group.id!),
                            )
                          : const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _kHint,
                              size: 16,
                            ),
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
                                fontSize: 16,
                                color: _kNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${group.subject ?? ''} • ${group.grade ?? ''}",
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'cairo',
                                fontSize: 13,
                                color: _kHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.end,
                              children: [
                                _miniTag(
                                  Icons.calendar_today_rounded,
                                  (group.daysName != null &&
                                          group.daysName!.isNotEmpty)
                                      ? group.daysName!.join(' • ')
                                      : 'لا يوجد أيام',
                                ),
                                if (group.startTime != null &&
                                    group.startTime!.isNotEmpty)
                                  _miniTag(
                                    Icons.access_time_rounded,
                                    group.startTime!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // أيقونة المجموعة اليمنى
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimaryBlue.withOpacity(0.12)
                            : _kIconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: isSelected ? _kPrimaryBlue : _kNavy,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // زر شريط العمليات العلوي ذو طابع دائري جذاب
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: _kIconBg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: iconColor ?? _kNavy, size: 20),
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

      // شريط AppBar مع أنيميشن انتقال تحوّلي عند التحديد
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSelectionMode
              ? AppBar(
                  key: const ValueKey('selection_appbar'),
                  backgroundColor: _kNavy,
                  elevation: 2,
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                      fontSize: 17,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.select_all_rounded,
                        color: Colors.white,
                      ),
                      tooltip: "تحديد الكل",
                      onPressed: () async {
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
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
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
                  key: const ValueKey('normal_appbar'),
                  backgroundColor: _kPageBg,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  foregroundColor: _kNavy,
                  title: const Text(
                    "المجموعات",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
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

                        return _buildActionButton(
                          icon: Icons.admin_panel_settings_rounded,
                          tooltip: "لوحة الأدمن",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminCreateCodeScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // 2. زر الإعدادات
                    _buildActionButton(
                      icon: Icons.settings_rounded,
                      tooltip: "الإعدادات",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),

                    // 3. زر الجدول الزمني
                    _buildActionButton(
                      icon: Icons.calendar_view_week_rounded,
                      tooltip: "الجدول الزمني",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TimetableScreen(),
                        ),
                      ),
                    ),

                    // 4. زر جميع الطلاب
                    _buildActionButton(
                      icon: Icons.groups_rounded,
                      tooltip: "جميع الطلاب",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const GeneralStudentDisplayScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_kNavy),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(fontFamily: 'cairo', color: _kDanger),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: _kHint,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "لا توجد مجموعات حالياً\nاضغط على + لإنشاء أول مجموعة",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: groups.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final group = GroupModel.fromFirestore(groups[index]);
              return _buildAnimatedGroupCard(group, index);
            },
          );
        },
      ),

      // الأزرار العائمة بتصميم ناعم ومودرن
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (AppSession.hasPermission('createStudent')) ...[
            FloatingActionButton.extended(
              heroTag: "addStudentGeneral",
              backgroundColor: Colors.white,
              foregroundColor: _kNavy,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text(
                "طالب",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (AppSession.hasPermission('createGroup'))
            FloatingActionButton(
              heroTag: "addGroup",
              backgroundColor: _kNavy,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                );
              },
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}
