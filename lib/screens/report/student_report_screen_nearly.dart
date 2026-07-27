import 'package:flutter/material.dart';
import 'package:seba/model/student_model.dart';

// ================== نظام الألوان الموحّد للشاشة ==================
const _kNavy = Color(0xFF16213E);
const _kIconBg = Color(0xFFEAF1FB);
const _kPageBg = Color(0xFFF6F8FB);
const _kHint = Color(0xFF9AA3B2);
const _kCardBorder = Color(0xFFEBEEF3);
const _kSuccess = Color(0xFF2E9E6B);
const _kSuccessBg = Color(0xFFE4F5EC);
const _kDanger = Color(0xFFD1483F);
const _kDangerBg = Color(0xFFFBE9E7);

class StudentReportScreenNearly extends StatelessWidget {
  const StudentReportScreenNearly({super.key, required this.student});

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "معاينة تقرير الطالب",
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1️⃣ خلفية مبسطة تحتوي على كروت التقرير ببيانات وهمية
          Opacity(
            opacity: 0.4, // إعطاء انطباع بالشفافية/المعاينة
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDummyHeaderCard(),
                const SizedBox(height: 14),
                _buildDummyAttendanceCard(),
                const SizedBox(height: 14),
                _buildDummyPerformanceCard(),
              ],
            ),
          ),

          // 2️⃣ الرسالة التوضيحية في منتصف الشاشة (قريباً)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kCardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A16213E),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
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
                      Icons.auto_awesome_rounded,
                      color: _kNavy,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "ميزة التقارير المباشرة متوفرة قريباً!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "نعمل حالياً على تطوير التقرير المباشر التفاعلي ليكون متاحاً بشكل أشمل وأسهل للمشاركة دون اي صعوبه.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _kNavy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "قريباً في التحديث القادم 🚀",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _kNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== كروت البيانات النموذجية ==================

  Widget _buildDummyHeaderCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: _kNavy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      student.name ?? "اسم الطالب",
                      style: const TextStyle(
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "الصف الثاني الثانوي - رياضيات",
                      style: TextStyle(
                        fontFamily: 'cairo',
                        fontSize: 12,
                        color: _kHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDummyAttendanceCard() {
    return _card(
      child: Column(
        children: [
          _cardTitle("معدل الحضور والغياب", Icons.event_available_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  value: "12",
                  label: "حضور",
                  icon: Icons.check_circle_rounded,
                  color: _kSuccess,
                  background: _kSuccessBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  value: "2",
                  label: "غياب",
                  icon: Icons.cancel_rounded,
                  color: _kDanger,
                  background: _kDangerBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDummyPerformanceCard() {
    return _card(
      child: Column(
        children: [
          _cardTitle("الأداء في الاختبارات", Icons.insights_rounded),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "92%",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: _kNavy,
                ),
              ),
              SizedBox(width: 10),
              Text(
                "متوسط التقييم العام",
                style: TextStyle(
                  fontFamily: 'cairo',
                  fontSize: 13,
                  color: _kHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== المكونات المساعدة ==================

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: _kNavy, size: 20),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'cairo',
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
