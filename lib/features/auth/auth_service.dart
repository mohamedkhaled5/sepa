import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/model/user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  // uploadProfileImage=====================
  /// رفع صورة شخصية جديدة للمستخدم وتحديث رابطها في Firestore و FirebaseAuth
  /// رفع صورة شخصية جديدة للمستخدم وتحديث رابطها في Firestore و FirebaseAuth
  /// ضغط الصورة وتحويلها إلى Base64 ثم حفظها في Firestore مباشرة
  /// ضغط الصورة وتحويلها إلى Base64 ثم حفظها في Firestore مباشرة
  Future<String> updateProfileImage(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('المستخدم غير مسجل دخول');

    try {
      // 1. ضغط الصورة
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 200,
        minHeight: 200,
        quality: 50,
      );

      if (compressedBytes == null) {
        throw Exception('فشل في ضغط الصورة');
      }

      // 2. تحويل الـ Bytes إلى Base64 String
      final String base64Image =
          'data:image/jpeg;base64,${base64Encode(compressedBytes)}';

      // 3. التحديث في Firestore فقط (وهو المرجع الأساسي للتطبيق)
      await _usersCollection.doc(uid).update({'photoUrl': base64Image});

      // ❌ تم إلغاء updatePhotoURL لتجنب تجاوز حد الأحرف في FirebaseAuth

      return base64Image;
    } catch (e) {
      print('خطأ في تحويل وحفظ الصورة: $e');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ================== توليد كود دعوة فريد ==================
  CollectionReference<Map<String, dynamic>> get _inviteCodesCollection =>
      _firestore.collection('inviteCodes');

  /// بتحاول تكتب مستند inviteCodes/{code} مباشرة. لو الكود مأخوذ بالفعل،
  /// قواعد Firestore هترفض الكتابة (لأن العملية بتتصنّف "update" على
  /// مستند موجود، والـ update ممنوع تمامًا لمجموعة inviteCodes) فبنجرب
  /// كود تاني. الفرادة هنا مضمونة من Firestore نفسه، مش من فحص قبل
  /// الإنشاء زي الطريقة القديمة (اللي كانت فيها احتمال تضارب نادر).
  Future<String> _generateUniqueInviteCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // بدون أحرف ملتبسة
    final random = Random();
    final uid = _auth.currentUser!.uid;

    while (true) {
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      try {
        await _inviteCodesCollection.doc(code).set({'teacherId': uid});
        return code;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          continue; // الكود مأخوذ بالفعل - جرب كود تاني
        }
        rethrow;
      }
    }
  }

  Future<String> _resolveTeacherIdByInviteCode(String inviteCode) async {
    final doc = await _inviteCodesCollection
        .doc(inviteCode.trim().toUpperCase())
        .get();

    if (!doc.exists) {
      throw Exception('كود المدرس غير صحيح');
    }

    return doc.data()!['teacherId'] as String;
  }

  // ================== تسجيل حساب مدرس (إيميل/باسورد) ==================
  Future<UserModel> registerTeacher({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(name);

    final inviteCode = await _generateUniqueInviteCode();

    final userModel = UserModel(
      uid: uid,
      name: name,
      email: email.trim(),
      role: 'teacher',
      inviteCode: inviteCode,
    );

    await _usersCollection.doc(uid).set(userModel.toJson());
    return userModel;
  }

  // ================== تسجيل حساب مساعد (إيميل/باسورد) ==================
  Future<UserModel> registerAssistant({
    required String name,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final teacherId = await _resolveTeacherIdByInviteCode(inviteCode);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(name);

    final userModel = UserModel(
      uid: uid,
      name: name,
      email: email.trim(),
      role: 'assistant',
      teacherId: teacherId,
      status: 'pending',
      permissions: kDefaultAssistantPermissions,
    );

    await _usersCollection.doc(uid).set(userModel.toJson());
    return userModel;
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// تسجيل الدخول عبر جوجل - متاح للمدرسين فقط. أي مستخدم جوجل جديد
  /// بينشئله التطبيق تلقائيًا حساب "مدرس" (بكود دعوة خاص بيه)، لأن
  /// المساعد لازم يسجل بالإيميل وكلمة المرور فقط عشان يقدر يدخل كود
  /// المدرس أثناء التسجيل - جوجل مفيهوش خطوة زي دي.
  Future<void> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } catch (_) {
      return;
    }

    final idToken = googleUser.authentication.idToken;
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(['email']);

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: authorization?.accessToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final docRef = _usersCollection.doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final inviteCode = await _generateUniqueInviteCode();
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '', // 👈 التقاط صورة جوجل تلقائياً هنا
        role: 'teacher',
        inviteCode: inviteCode,
      );
      await docRef.set(userModel.toJson());
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    await _auth.signOut();
    AppSession.clear();

    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // تجاهل: المستخدم أصلاً خرج من Firebase بنجاح، وده الأهم.
    }
  }

  Future<UserModel?> fetchUserData(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// بترجع كود الدعوة الخاص بمدرس معين. بتغطي 3 حالات:
  /// 1) حساب قديم مفيهوش كود خالص -> تولّد كود جديد كامل.
  /// 2) حساب عنده كود في users لكن مفيش مستند مطابق في inviteCodes
  ///    (حسابات اتعملت قبل إضافة مجموعة inviteCodes) -> تكمّل المستند
  ///    الناقص بدل ما تولّد كود جديد بالغلط (Migration ذاتي).
  /// 3) حساب متظبط بالكامل -> ترجع الكود زي ما هو.
  Future<String> ensureInviteCode(String teacherUid) async {
    final doc = await _usersCollection.doc(teacherUid).get();
    final existingCode = doc.data()?['inviteCode'] as String?;

    if (existingCode != null && existingCode.isNotEmpty) {
      final codeDoc = await _inviteCodesCollection.doc(existingCode).get();
      if (!codeDoc.exists) {
        await _inviteCodesCollection.doc(existingCode).set({
          'teacherId': teacherUid,
        });
      }
      return existingCode;
    }

    final newCode = await _generateUniqueInviteCode();
    await _usersCollection.doc(teacherUid).update({'inviteCode': newCode});
    return newCode;
  }

  // ================== إدارة المساعدين (المدرس فقط) ==================
  Stream<QuerySnapshot<Map<String, dynamic>>> pendingAssistantsStream(
    String teacherId,
  ) {
    return _usersCollection
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> approvedAssistantsStream(
    String teacherId,
  ) {
    return _usersCollection
        .where('teacherId', isEqualTo: teacherId)
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  /// عند القبول، بنعيد ضبط الصلاحيات للقيم الافتراضية الآمنة صراحة -
  /// حتى لو المساعد حاول (بتلاعب مباشر في الطلب مش عبر الواجهة) يسجّل
  /// نفسه بصلاحيات مرفوعة، القبول بيصفّرها تلقائيًا. المدرس بعد كده
  /// يقدر يرفعها يدويًا من شاشة تعديل الصلاحيات لو حابب.
  // في auth_service.dart عند موافقة المدرس على طلب المساعد
  Future<void> approveAssistant(String assistantUid, String teacherUid) async {
    // 1. إذا كان المستخدم الحالي Admin، نتجاوز فحص الحد الأقصى للمساعدين فوراً
    if (!AppSession.isAdmin) {
      // جلب الحد الأقصى للمدرس
      final teacherDoc = await _usersCollection.doc(teacherUid).get();
      final maxAssistants = teacherDoc.data()?['maxAssistants'] ?? 2;

      // حساب عدد المساعدين النشطين للمدرس
      final approvedSnap = await _usersCollection
          .where('teacherId', isEqualTo: teacherUid)
          .where('status', isEqualTo: 'approved')
          .get();

      if (approvedSnap.docs.length >= maxAssistants) {
        throw Exception(
          'وصلت للحد الأقصى المسموح به من المساعدين ($maxAssistants). يُرجى ترقية اشتراكك.',
        );
      }
    }

    // 2. قبول المساعد وتعيين الصلاحيات الافتراضية
    await _usersCollection.doc(assistantUid).update({
      'status': 'approved',
      'permissions': kDefaultAssistantPermissions,
    });
  }

  Future<void> rejectAssistant(String assistantUid) async {
    await _usersCollection.doc(assistantUid).update({'status': 'rejected'});
  }

  /// إزالة مساعد من فريق المدرس. بنحط status = 'removed' بوضوح (مش
  /// بنمسحها خالص)، عشان المساعد يوصله واضح إنه اتشال ومحتاج يبعت طلب
  /// جديد، بدل ما تفضل الحالة null وتتفسر غلط كـ "لسه في الانتظار".
  Future<void> removeAssistant(String assistantUid) async {
    await _usersCollection.doc(assistantUid).update({
      'status': 'removed',
      'teacherId': FieldValue.delete(),
    });
  }

  /// يُستخدم لما مساعد مرفوض أو مُزال يحب يبعت طلب انضمام جديد بكود
  /// (لنفس المدرس أو لمدرس تاني) من غير ما يحتاج يعمل حساب جديد.
  Future<void> resubmitJoinRequest({required String inviteCode}) async {
    final uid = _auth.currentUser!.uid;
    final teacherId = await _resolveTeacherIdByInviteCode(inviteCode);

    await _usersCollection.doc(uid).update({
      'teacherId': teacherId,
      'status': 'pending',
    });
  }

  Future<void> updateAssistantPermissions(
    String assistantUid,
    Map<String, bool> permissions,
  ) async {
    await _usersCollection.doc(assistantUid).update({
      'permissions': permissions,
    });
  }
}
