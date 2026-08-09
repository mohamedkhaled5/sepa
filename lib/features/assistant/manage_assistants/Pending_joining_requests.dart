// ================== طلبات الانضمام المعلّقة ==================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seba/features/auth/auth_service.dart';
import 'package:seba/model/user_model.dart';

class PendingJoiningRequests extends StatefulWidget {
  const PendingJoiningRequests({super.key, required this.teacherId});
  final String teacherId;

  @override
  State<PendingJoiningRequests> createState() => _PendingJoiningRequestsState();
}

class _PendingJoiningRequestsState extends State<PendingJoiningRequests> {
  final _authService = AuthService();

  /// دالة قبول المساعد وإظهار التنبيه في حال اكتمال العدد
  /// دالة معالجة موافقة المساعد مع التقاط الاستثناءات
  Future<void> _handleApproveAssistant(String assistantUid) async {
    try {
      await _authService.approveAssistant(assistantUid, widget.teacherId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت الموافقة على المساعد بنجاح")),
      );
    } catch (e) {
      if (!mounted) return;

      // استخراج نص الخطأ
      final errorMessage = e.toString();

      // 🚨 في حالة الرفض بسبب الوصول للحد الأقصى للمساعدين
      if (errorMessage.contains('الحد الأقصى')) {
        _showUpgradeSubscriptionDialog(errorMessage);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
      }
    }
  }

  /// نافذة تنبيهية تطلب من المدرس ترقية باقة الاشتراك
  void _showUpgradeSubscriptionDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "وصلت للحد الأقصى",
              style: TextStyle(
                fontFamily: "cairo",
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          ],
        ),
        content: const Text(
          "لقد استوفيت العدد المسموح به من المساعدين في باقتك الحالية.\n\nيرجى ترقية باقة الاشتراك لزيادة سعة المساعدين والموافقة على طلبات جديدة.",
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: "cairo", fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "إلغاء",
              style: TextStyle(fontFamily: "cairo", color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // 🚀 يمكنك التوجيه لشاشة الاشتراك هنا لو كانت موجودة لديك
            },
            child: const Text(
              "ترقية الباقة",
              style: TextStyle(fontFamily: "cairo", color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEEF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A16213E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEAF1FB),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Color(0xFF16213E),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "طلبات الانضمام",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16213E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _authService.pendingAssistantsStream(widget.teacherId),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFEAF1FB),
                        child: Icon(
                          Icons.group_off_rounded,
                          color: Color(0xFF16213E),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "لا توجد طلبات انضمام",
                        style: TextStyle(
                          fontFamily: "cairo",
                          color: Color(0xFF9AA3B2),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final assistant = UserModel.fromFirestore(doc);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBEEF3)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            // ✅ الكود الجديد
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _handleApproveAssistant(assistant.uid),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.green,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _authService.rejectAssistant(assistant.uid),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                assistant.name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: "cairo",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                assistant.email,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: "cairo",
                                  color: Color(0xFF9AA3B2),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF1FB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF16213E),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
