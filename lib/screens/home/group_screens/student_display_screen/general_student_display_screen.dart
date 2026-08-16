import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/student_profile/student_profile_screen.dart';

// ================== نظام الألوان الحديث والموحد ==================
const _kPrimary = Color(0xFF4F46E5); // بنفسجي نيلي عصري ومريح للعين
const _kPrimaryLight = Color(0xFFEEF2FF); // خلفية زاهية خفيفة للأيقونات
const _kNavy = Color(0xFF0F172A); // نصوص وداكن
const _kNavyLight = Color(0xFF334155); // نصوص فرعية
const _kPageBg = Color(0xFFF8FAFC); // خلفية الصفحة
const _kHint = Color(0xFF64748B); // التلميحات
const _kCardBorder = Color(0xFFE2E8F0); // الحدود الناعمة
const _kDanger = Color(0xFFEF4444); // أحمر مرجاني

class GeneralStudentDisplayScreen extends StatefulWidget {
  const GeneralStudentDisplayScreen({super.key});

  @override
  State<GeneralStudentDisplayScreen> createState() =>
      _GeneralStudentDisplayScreenState();
}

class _GeneralStudentDisplayScreenState
    extends State<GeneralStudentDisplayScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kPageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _kNavy,
        centerTitle: false,
        title: const Text(
          "طلابي",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: _kNavy,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 شريط البحث الحديث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 14,
                color: _kNavy,
              ),
              decoration: InputDecoration(
                hintText: "ابحث عن طالب بالاسم...",
                hintStyle: const TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 13.5,
                  color: _kHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _kPrimary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: _kHint,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kCardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                ),
              ),
            ),
          ),

          // 📜 قائمة الطلاب
          Expanded(
            child: currentUser == null
                ? const Center(
                    child: Text(
                      "يرجى تسجيل الدخول أولاً",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        color: _kHint,
                        fontSize: 15,
                      ),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(AppSession.effectiveTeacherId)
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _kPrimary,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "حدث خطأ أثناء جلب البيانات: ${snapshot.error}",
                            style: const TextStyle(
                              fontFamily: 'cairo',
                              color: _kDanger,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
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
                                  Icons.person_off_rounded,
                                  color: _kPrimary,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "لا يوجد طلاب مسجلون لديك حتى الآن",
                                style: TextStyle(
                                  fontFamily: 'cairo',
                                  fontSize: 15,
                                  color: _kHint,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // 🛠️ جلب الكائن المكتمل للحفاظ على جلب groupIds
                      final List<StudentModel> students = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return StudentModel(
                          id: doc.id,
                          name: data['name'] ?? '',
                          phone: data['phone'] ?? '',
                          groupIds: List<String>.from(data['groupIds'] ?? []),
                        );
                      }).toList();

                      // تصفية حسب البحث
                      final filteredStudents = students.where((student) {
                        final name = (student.name ?? '').toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      if (filteredStudents.isEmpty) {
                        return const Center(
                          child: Text(
                            "لا توجد نتائج تطابق بحثك",
                            style: TextStyle(
                              fontFamily: 'cairo',
                              color: _kHint,
                              fontSize: 14.5,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: filteredStudents.length + 1,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildHeaderSummary(
                              total: students.length,
                              filtered: filteredStudents.length,
                            );
                          }
                          final student = filteredStudents[index - 1];
                          return _buildStudentCard(student, index - 1);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 📊 كارت إحصائي علوي يعرض إجمالي الطلاب بنفس ديزاين الشاشات الموحدة
  Widget _buildHeaderSummary({required int total, required int filtered}) {
    final isSearching = _searchQuery.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), _kPrimary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isSearching ? "$filtered من $total" : "$total طالب",
              style: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Row(
            children: [
              Text(
                "قائمة كل الطلاب",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  // 🎴 كارت عرض بيانات الطالب بالتصميم العصري الجديد
  Widget _buildStudentCard(StudentModel student, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 40).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 15),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kCardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentProfileScreen(student: student),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: _kHint,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (student.name != null && student.name!.isNotEmpty)
                            ? student.name!
                            : 'طالب بدون اسم',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: _kNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (student.phone != null && student.phone!.isNotEmpty)
                            ? student.phone!
                            : 'لا يوجد رقم هاتف',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'cairo',
                          fontSize: 12.5,
                          color: _kNavyLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _kPrimaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _kPrimary,
                      size: 24,
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
}
