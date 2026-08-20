import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageCodesScreen extends StatefulWidget {
  const AdminManageCodesScreen({super.key});

  @override
  State<AdminManageCodesScreen> createState() => _AdminManageCodesScreenState();
}

class _AdminManageCodesScreenState extends State<AdminManageCodesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 👈 دالة التعديل والتسميع التلقائي في حساب المدرس دون المساس بالـ UID
  Future<void> _updateCodeAndSyncTeacher({
    required String codeDocId,
    required String plan,
    required int durationDays,
    required int maxAssistants,
    required String? usedByUid,
  }) async {
    final batch = _firestore.batch();
    final codeRef = _firestore.collection('subscription_codes').doc(codeDocId);

    // 1. تحديث مستند الكود في subscription_codes
    batch.update(codeRef, {
      'plan': plan,
      'durationDays': durationDays,
      'maxAssistants': maxAssistants,
    });

    // 2. إذا كان الكود مستخدماً، تسميع التعديلات تلقائياً في حساب المدرس
    if (usedByUid != null && usedByUid.trim().isNotEmpty) {
      final userRef = _firestore.collection('users').doc(usedByUid.trim());
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        DateTime startDate = DateTime.now();

        // جلب تاريخ بداية الاشتراك الأصلي للمدرس
        if (userData != null && userData['subscription'] != null) {
          final sub = userData['subscription'] as Map<String, dynamic>;
          if (sub['startDate'] != null && sub['startDate'] is Timestamp) {
            startDate = (sub['startDate'] as Timestamp).toDate();
          }
        }

        // إعادة حساب تاريخ الانتهاء الجديد = (تاريخ البداية + الأيام الجديدة)
        final DateTime newEndDate = startDate.add(Duration(days: durationDays));

        batch.update(userRef, {
          'maxAssistants': maxAssistants,
          'subscription.plan': plan,
          'subscription.maxAssistants': maxAssistants,
          'subscription.endDate': Timestamp.fromDate(newEndDate),
        });
      }
    }

    await batch.commit();
  }

  // 👈 نافذة التعديل الآمنة
  Future<void> _showEditCodeDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final String code = data['code'] ?? doc.id;
    final String? usedByUid = data['usedBy'];
    final bool isUsed = data['used'] ?? data['isUsed'] ?? false;

    final durationController = TextEditingController(
      text: (data['durationDays'] ?? 30).toString(),
    );
    final assistantsController = TextEditingController(
      text: (data['maxAssistants'] ?? 2).toString(),
    );

    String selectedPlan = data['plan'] ?? 'Pro';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'تعديل اشتراك الكود: $code',
              style: const TextStyle(
                fontFamily: 'cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUsed && usedByUid != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_alt, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'هذا الكود مستخدم. أي تعديل في المدة أو الخطة سيسمع فوراً في حساب المدرس.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                                fontFamily: 'cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. مدة الاشتراك (الأيام)
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مدة الاشتراك (بالأيام)',
                      hintText: 'مثال: 30 أو 25',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. نوع الباقة
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlan,
                    decoration: const InputDecoration(
                      labelText: 'نوع الخطة (Plan)',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Basic', 'Pro', 'VIP'].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPlan = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. عدد المساعدين
                  TextField(
                    controller: assistantsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد المساعدين المسموح به',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                ),
                onPressed: () async {
                  try {
                    await _updateCodeAndSyncTeacher(
                      codeDocId: doc.id,
                      plan: selectedPlan,
                      durationDays: int.parse(durationController.text),
                      maxAssistants: int.parse(assistantsController.text),
                      usedByUid: usedByUid,
                    );

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم تعديل البيانات والتسميع عند المدرس بنجاح! 🎉',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'حفظ التعديلات',
                  style: TextStyle(color: Colors.white, fontFamily: 'cairo'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // حذف الكود
  Future<void> _deleteCode(String docId, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الكود', style: TextStyle(fontFamily: 'cairo')),
        content: Text('هل أنت متأكد من حذف الكود "$code"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('subscription_codes').doc(docId).delete();
    }
  }

  String _formatTimestamp(dynamic date) {
    if (date == null) return 'غير محدد';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.year}-${dt.month}-${dt.day} (${dt.hour}:${dt.minute})';
    }
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'سجل ومتابعة الأكواد',
          style: TextStyle(fontFamily: 'cairo'),
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('subscription_codes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد أكواد مسجلة حالياً'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String code = data['code'] ?? doc.id;
              final bool used = data['used'] ?? data['isUsed'] ?? false;
              final String plan = data['plan'] ?? 'Pro';
              final int durationDays = data['durationDays'] ?? 0;
              final int maxAssistants = data['maxAssistants'] ?? 0;
              final String? usedBy = data['usedBy'];
              final dynamic usedAt = data['usedAt'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: used ? Colors.amber.shade400 : Colors.green.shade400,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رأس البطاقة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: used
                                  ? Colors.amber.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              code,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: used
                                    ? Colors.amber.shade900
                                    : Colors.green.shade900,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Chip(
                                label: Text(used ? 'مستخدم 🔒' : 'متاح 🟢'),
                                backgroundColor: used
                                    ? Colors.amber.shade50
                                    : Colors.green.shade50,
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') _showEditCodeDialog(doc);
                                  if (val == 'delete')
                                    _deleteCode(doc.id, code);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('تعديل مدة الاشتراك والخصائص'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('حذف الكود'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // خصائص الكود
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الباقة: $plan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('المدة: $durationDays يوم'),
                          Text('المساعدين: $maxAssistants'),
                        ],
                      ),

                      // 👈 عرض تفاصيل المدرس ومُعرّفه (UID) بشكل واضح وقابل للنسخ
                      if (usedBy != null && usedBy.isNotEmpty) ...[
                        const Divider(height: 20),
                        FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('users')
                              .doc(usedBy)
                              .get(),
                          builder: (context, userSnap) {
                            if (userSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 30,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final teacherData =
                                userSnap.data?.data() as Map<String, dynamic>?;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'بيانات المدرس المستفيد من الكود:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16213E),
                                      fontFamily: 'cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '👤 الاسم: ${teacherData?['name'] ?? 'غير معروف'}',
                                  ),
                                  Text(
                                    '📧 البريد: ${teacherData?['email'] ?? 'غير معروف'}',
                                  ),

                                  // 👈 إظهار الـ UID هنا مع خاصية التحديد والنسخ
                                  SelectableText(
                                    '🔑 معرف المدرس (UID): $usedBy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  Text(
                                    '⏱️ تاريخ التفعيل: ${_formatTimestamp(usedAt)}',
                                  ),
                                  if (teacherData?['subscription'] != null) ...[
                                    Text(
                                      '📅 تاريخ الانتهاء الحالي: ${_formatTimestamp(teacherData!['subscription']['endDate'])}',
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
