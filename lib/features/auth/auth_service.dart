import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seba/features/assistant/app_session.dart';
import 'package:seba/model/user_model.dart';

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

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ================== توليد كود دعوة فريد ==================
  Future<String> _generateUniqueInviteCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // بدون أحرف ملتبسة
    final random = Random();

    while (true) {
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      final existing = await _usersCollection
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) return code;
    }
  }

  Future<String> _resolveTeacherIdByInviteCode(String inviteCode) async {
    final teacherQuery = await _usersCollection
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .where('role', isEqualTo: 'teacher')
        .limit(1)
        .get();

    if (teacherQuery.docs.isEmpty) {
      throw Exception('كود المدرس غير صحيح');
    }

    return teacherQuery.docs.first.id;
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

  /// بترجع كود الدعوة الخاص بمدرس معين، ولو الحساب قديم ومفيهوش كود
  /// أصلًا (مثلاً اتعمل قبل ما خاصية الأكواد تتضاف)، بتولّد له كود جديد
  /// وتحفظه في نفس اللحظة بدل ما تسيب الشاشة تظهر فاضية.
  Future<String> ensureInviteCode(String teacherUid) async {
    final doc = await _usersCollection.doc(teacherUid).get();
    final existingCode = doc.data()?['inviteCode'] as String?;

    if (existingCode != null && existingCode.isNotEmpty) {
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

  Future<void> approveAssistant(String assistantUid) async {
    await _usersCollection.doc(assistantUid).update({'status': 'approved'});
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
