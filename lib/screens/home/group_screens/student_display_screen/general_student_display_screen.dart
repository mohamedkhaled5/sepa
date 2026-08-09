import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/model/student_model.dart';
import 'package:seba/screens/student/student_profile/student_profile_screen.dart';

// ألوان موحدة للتطبيق
const _kNavy = Color(0xFF16213E);
const _kPageBg = Color(0xFFF6F8FB);
const _kCardBorder = Color(0xFFEBEEF3);
const _kIconBg = Color(0xFFEAF1FB);

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
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "طلابي",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 شريط البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "ابحث عن طالب...",
                hintStyle: const TextStyle(fontFamily: 'cairo', fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kNavy),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kCardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kCardBorder),
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
                      style: TextStyle(fontFamily: 'cairo'),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(
                          AppSession.effectiveTeacherId,
                        ) //currentUser.uid =>AppSession.effectiveTeacherId
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "حدث خطأ أثناء جلب البيانات: ${snapshot.error}",
                            style: const TextStyle(fontFamily: 'cairo'),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "لا يوجد طلاب مسجلون لديك حتى الآن",
                            style: TextStyle(fontFamily: 'cairo', fontSize: 16),
                          ),
                        );
                      }

                      // 🛠️ جلب الكائن المكتمل للحفاظ على جلب groupIds
                      final List<StudentModel> students = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        // يفضل استخدام StudentModel.fromFirestore(doc) إذا كان متاحاً لديك
                        // أو قراءة المجموعات يدوياً كما يلي:
                        return StudentModel(
                          id: doc.id,
                          name: data['name'] ?? '',
                          phone: data['phone'] ?? '',
                          groupIds: List<String>.from(data['groupIds'] ?? []),
                          // يمكنك إضافة بقية الحقول كـ (parentPhone, grade... إلخ) إن وجدت
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
                            style: TextStyle(fontFamily: 'cairo'),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredStudents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _buildStudentTile(student);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(StudentModel student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: Colors.grey,
        ),
        title: Text(
          student.name ?? 'طالب بدون اسم',
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          student.phone ?? 'لا يوجد رقم هاتف',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'cairo',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _kIconBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: _kNavy, size: 22),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentProfileScreen(student: student),
            ),
          );
        },
      ),
    );
  }
}
