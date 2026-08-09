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
const _kPrimary = Color(0xFF4F46E5); // بنفيجي نيلي عصري مريح للعين
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة للأيقونات
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kDanger = Color(0xFFEF4444); // أحمر مرجاني
const _kDangerBg = Color(0xFFFEF2F2); // خلفية التنبيه الخفيفة
const _kSuccess = Color(0xFF10B981); // أخضر زمردي

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
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _kDangerBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: _kDanger,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "تأكيد الحذف النهائي",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kNavy,
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
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kPrimaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kPrimary.withOpacity(0.15)),
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
                        const SizedBox(height: 6),
                        SelectableText(
                          confirmationCode,
                          style: const TextStyle(
                            fontFamily: 'cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: _kPrimary,
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
                        color: _kHint,
                      ),
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _kCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: _kPrimary,
                          width: 2,
                        ),
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
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDanger,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: isButtonEnabled
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text(
                    "حذف الكل",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _kPrimary)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 13, color: _kPrimary),
        ],
      ),
    );
  }

  // 🔹 عنصر إحصائيات عدد المجموعات بتصميم عصري جذاب
  Widget _buildGroupsCountHeader(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), _kPrimary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // العداد والتمييز
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // العنوان والأيقونة
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "إجمالي المجموعات",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "عدد المجموعات المتاحة حالياً",
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 11.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء بطاقة المجموعة مع خفة الحركة وأنيميشن التحديد
  Widget _buildAnimatedGroupCard(GroupModel group, int index) {
    final isSelected = _selectedGroupIds.contains(group.id);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryLight : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _kPrimary : _kCardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _kPrimary.withOpacity(0.12)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 14,
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
              color: _kPrimary,
              borderRadius: BorderRadius.circular(22),
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
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
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
                              activeColor: _kPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (_) => _toggleSelection(group.id!),
                            )
                          : Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: _kPageBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _kHint,
                                size: 14,
                              ),
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
                                fontSize: 16.5,
                                color: _kNavy,
                              ),
                            ),
                            const SizedBox(height: 3),
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
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : _kPrimaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: isSelected ? Colors.white : _kPrimary,
                        size: 26,
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
          color: Colors.white,
          shape: CircleBorder(
            side: BorderSide(color: _kCardBorder.withOpacity(0.8)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
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
                  elevation: 0,
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
                      fontSize: 24,
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
                          iconColor: _kPrimary,
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
                valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
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
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: _kPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: _kPrimary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "لا توجد مجموعات حالياً\nاضغط على + لإنشاء أول مجموعة",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      color: _kHint,
                      fontSize: 14.5,
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
            itemCount:
                groups.length + 1, // +1 من أجل بطاقة الإحصائيات في البداية
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              // إذا كان العنصر الأول، اظهر حاوي إجمالي المجموعات
              if (index == 0) {
                return _buildGroupsCountHeader(groups.length);
              }

              // باقي العناصر لبطاقات المجموعات
              final group = GroupModel.fromFirestore(groups[index - 1]);
              return _buildAnimatedGroupCard(group, index - 1);
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
                borderRadius: BorderRadius.circular(18),
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
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                color: _kPrimary,
                size: 20,
              ),
              label: const Text(
                "طالب",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (AppSession.hasPermission('createGroup'))
            FloatingActionButton(
              heroTag: "addGroup",
              backgroundColor: _kPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
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
