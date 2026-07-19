import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// نقطة مركزية واحدة لكل مسارات Firestore الخاصة ببيانات المستخدم الحالي.
///
/// بدل ما كل شاشة تكتب FirebaseFirestore.instance.collection('groups')
/// مباشرة (وده بيخلي بيانات كل المستخدمين مشتركة في نفس الـ collection)،
/// كل الشاشات دلوقتي هتستخدم FirestorePaths.groups مثلاً، واللي
/// بيرجع تلقائيًا: users/{uid}/groups الخاصة بالمستخدم المسجل دخول حاليًا فقط.
///
/// لو مفيش مستخدم مسجل دخول أصلاً، بيرمي خطأ واضح بدل ما يفشل بصمت
/// أو (الأخطر) يكتب/يقرأ من مكان غلط.
class FirestorePaths {
  FirestorePaths._();

  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'لا يوجد مستخدم مسجل دخول حاليًا - لا يمكن الوصول لبيانات Firestore',
      );
    }
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  static CollectionReference<Map<String, dynamic>> get groups =>
      _userDoc.collection('groups');

  static CollectionReference<Map<String, dynamic>> get students =>
      _userDoc.collection('students');

  static CollectionReference<Map<String, dynamic>> get subjects =>
      _userDoc.collection('subjects');

  static CollectionReference<Map<String, dynamic>> get grades =>
      _userDoc.collection('grades');

  /// سجلات الحضور/الامتحانات الخاصة بطالب معين (subcollection تحت الطالب
  /// نفسه، وهو أصلًا تحت users/{uid}/students/{studentId}).
  static CollectionReference<Map<String, dynamic>> studentActivities(
    String studentId,
  ) => students.doc(studentId).collection('activities');
}
