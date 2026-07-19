import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seba/model/user_model.dart';

/// كل منطق المصادقة (Auth) والتعامل الأولي مع مستند المستخدم في Firestore
/// مجمّع هنا، عشان الشاشات (login/register/...) تبقى نظيفة وتستدعي بس
/// الدوال دي من غير ما تكتب كود Firebase مباشرة.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // من إصدار google_sign_in 7 فأعلى: GoogleSignIn بقت Singleton، مفيش
  // constructor عادي، ولازم initialize() تتنادى مرة واحدة قبل أي استخدام.
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  /// Stream بيبعت المستخدم الحالي (أو null) كل ما تتغير حالة تسجيل الدخول.
  /// AuthWrapper هيستخدمها عشان يقرر يوريك Home ولا Login.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  /// إنشاء حساب جديد بالبريد وكلمة المرور، وحفظ بيانات المستخدم في
  /// users/{uid} في Firestore مباشرة بعد الإنشاء.
  Future<UserModel> register({
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

    final userModel = UserModel(uid: uid, name: name, email: email.trim());

    await _firestore.collection('users').doc(uid).set(userModel.toJson());

    return userModel;
  }

  /// تسجيل الدخول بالبريد وكلمة المرور فقط (بدون أي لوجيك تاني).
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// تسجيل الدخول عبر Google (API الإصدار 7 فأعلى).
  /// المصادقة (Authentication) والتفويض (Authorization) بقوا خطوتين
  /// منفصلتين: authenticate() بيجيب هوية المستخدم + idToken، وبعدين
  /// نجيب accessToken منفصل عبر authorizationClient قبل ما نبني الـ
  /// credential ونسجّل دخول في Firebase بيه.
  Future<void> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } catch (_) {
      // المستخدم لغى عملية تسجيل الدخول أو حصل خطأ في نافذة الاختيار
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

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      );
      await docRef.set(userModel.toJson());
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    // نعمل signOut من Firebase الأول وبشكل مضمون - ده اللي فعليًا بيغيّر
    // حالة authStateChanges ويخلي AuthWrapper يرجّعك لشاشة تسجيل الدخول.
    await _auth.signOut();

    // تسجيل خروج جوجل ثانويّ: لو فشل لأي سبب (مثلاً initialize() لسه
    // مش متظبطة بالكامل) منسيبوش يوقف أو يمنع خروجك من التطبيق.
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // تجاهل: المستخدم أصلاً خرج من Firebase بنجاح، وده الأهم.
    }
  }

  /// جلب بيانات المستخدم الكاملة من Firestore (اسم، إيميل، role...).
  Future<UserModel?> fetchUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
