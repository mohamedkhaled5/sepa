import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seba/features/subscription/data/repositories/subscription_repository.dart';

class AdminCreateCodeScreen extends StatefulWidget {
  const AdminCreateCodeScreen({super.key});

  @override
  State<AdminCreateCodeScreen> createState() => _AdminCreateCodeScreenState();
}

class _AdminCreateCodeScreenState extends State<AdminCreateCodeScreen> {
  final _codeController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _maxAssistantsController = TextEditingController(text: '2');

  final _repository = SubscriptionRepository();

  String _selectedPlan = 'Pro';
  bool _isLoading = false;
  String? _lastCreatedCode;

  // 👈 قائمة الـ 12 صلاحية الكاملة مع أسمائها البرمجية والعربية
  final Map<String, String> _permissionLabels = const {
    'attendance': 'تسجيل الحضور والغياب',
    'exams': 'تسجيل نتائج الامتحانات',
    'notes': 'إضافة الملاحظات',
    'createStudent': 'إضافة طلاب جديد',
    'editStudent': 'تعديل بيانات الطلاب',
    'deleteStudent': 'حذف الطلاب',
    'transferStudent': 'نقل الطالب بين المجموعات',
    'createGroup': 'إنشاء مجموعات جديدة',
    'editGroup': 'تعديل المجموعات',
    'deleteGroup': 'حذف المجموعات',
    'manageSubjectsGrades': 'إدارة الدرجات والمواد',
    'reports': 'عرض وتقارير البيانات',
  };

  // 👈 حالة مفاتيح التحكم (مفعلة جميعها افتراضياً للأدمن)
  late Map<String, bool> _allowedPermissions;

  @override
  void initState() {
    super.initState();
    _allowedPermissions = {for (var key in _permissionLabels.keys) key: true};
  }

  @override
  void dispose() {
    _codeController.dispose();
    _durationController.dispose();
    _maxAssistantsController.dispose();
    super.dispose();
  }

  void _generateRandomCode() {
    setState(() {
      _codeController.text = _repository.generateRandomCode();
    });
  }

  void _toggleAllPermissions(bool value) {
    setState(() {
      _allowedPermissions.updateAll((key, _) => value);
    });
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim().toUpperCase();
    final durationText = _durationController.text.trim();
    final assistantsText = _maxAssistantsController.text.trim();

    if (code.isEmpty || durationText.isEmpty || assistantsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء تعبئة جميع الحقول بشكل صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final duration = int.parse(durationText);
      final maxAssistants = int.parse(assistantsText);

      // حفظ الكود وسقف الصلاحيات الـ 12 المحددة
      await _repository.createSubscriptionCode(
        code: code,
        durationDays: duration,
        plan: _selectedPlan,
        maxAssistants: maxAssistants,
      );

      setState(() {
        _lastCreatedCode = code;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء كود الاشتراك بنجاح! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _shareCode(String code) {
    final message =
        '''
أهلاً بك! 🌸
كود تفعيل اشتراكك في تطبيق صِبا:
🔑 كود التفعيل: *$code*
📊 الخطة: $_selectedPlan
⏱️ المدة: ${_durationController.text} يوم
👥 عدد المساعدين المسموح به: ${_maxAssistantsController.text} مساعدين

قم بإدخال الكود عند إنشاء حساب المدرس للبدء مباشرة.
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'توليد كود اشتراك جديد',
          style: TextStyle(fontFamily: 'cairo'),
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. حقل الكود والتوليد العشوائي
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'كود التفعيل',
                      hintText: 'مثال: TEACHER2026',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF16213E),
                  ),
                  onPressed: _generateRandomCode,
                  icon: const Icon(Icons.autorenew_rounded),
                  tooltip: 'توليد كود عشوائي',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. مدة الاشتراك
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'مدة الاشتراك (بالأيام)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 3. عدد المساعدين
            TextField(
              controller: _maxAssistantsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'عدد المساعدين المسموح به',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 4. نوع الخطة
            DropdownButtonFormField<String>(
              initialValue: _selectedPlan,
              decoration: InputDecoration(
                labelText: 'نوع الخطة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: ['Basic', 'Pro', 'VIP'].map((plan) {
                return DropdownMenuItem(value: plan, child: Text(plan));
              }).toList(),
              onChanged: (val) => setState(() => _selectedPlan = val!),
            ),
            const SizedBox(height: 24),

            // 5. قسم التحكم الكامل بالـ 12 صلاحية
            // Card(
            //   elevation: 0,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(16),
            //     side: BorderSide(color: Colors.grey.shade300),
            //   ),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             const Text(
            //               'سقف الصلاحيات المتاحة للباقة:',
            //               style: TextStyle(
            //                 fontWeight: FontWeight.bold,
            //                 fontSize: 15,
            //                 fontFamily: 'cairo',
            //                 color: Color(0xFF16213E),
            //               ),
            //             ),
            //             Row(
            //               children: [
            //                 TextButton(
            //                   onPressed: () => _toggleAllPermissions(true),
            //                   child: const Text('تحديد الكل'),
            //                 ),
            //                 TextButton(
            //                   onPressed: () => _toggleAllPermissions(false),
            //                   child: const Text(
            //                     'إلغاء الكل',
            //                     style: TextStyle(color: Colors.red),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //         const Text(
            //           'الصلاحية المعطلة هنا لن يراها المدرس ولن يستطيع منحها لمساعده.',
            //           style: TextStyle(fontSize: 12, color: Colors.grey),
            //         ),
            //         const Divider(height: 20),

            //         // قائمة الـ 12 مفتاح تحكم
            //         ..._permissionLabels.entries.map((entry) {
            //           final key = entry.key;
            //           final label = entry.value;

            //           return SwitchListTile(
            //             dense: true,
            //             contentPadding: EdgeInsets.zero,
            //             title: Text(
            //               label,
            //               style: const TextStyle(
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.w500,
            //               ),
            //             ),
            //             value: _allowedPermissions[key] ?? true,
            //             onChanged: (val) {
            //               setState(() {
            //                 _allowedPermissions[key] = val;
            //               });
            //             },
            //           );
            //         }),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 24),

            // زر الحفظ
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ الكود في الفايربيس',
                        style: TextStyle(fontSize: 16, fontFamily: 'cairo'),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // بطاقة المشاركة بعد الحفظ
            if (_lastCreatedCode != null) ...[
              Card(
                color: Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'تم إنشاء الكود بنجاح وهو جاهز للإرسال:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _lastCreatedCode!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _lastCreatedCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ الكود!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('نسخ'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _shareCode(_lastCreatedCode!),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('إرسال للمدرس'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
