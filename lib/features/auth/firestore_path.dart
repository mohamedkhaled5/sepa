import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seba/features/assistant/app_session.dart';

/// نقطة مركزية واحدة لكل مسارات Firestore.
///
/// كل المسارات هنا بترجع تلقائيًا تحت users/{effectiveTeacherId}/... —
/// effectiveTeacherId هو uid المدرس دايمًا (سواء كان المستخدم الحالي هو
/// المدرس نفسه، أو مساعد تابع له)، وده اللي بيخلي المدرس والمساعد
/// يشوفوا نفس البيانات بالظبط، بينما بيانات كل مدرس تفضل معزولة عن
/// مدرس تاني.
class FirestorePaths {
  FirestorePaths._();

  static DocumentReference<Map<String, dynamic>> get _teacherDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AppSession.effectiveTeacherId);

  static CollectionReference<Map<String, dynamic>> get groups =>
      _teacherDoc.collection('groups');

  static CollectionReference<Map<String, dynamic>> get students =>
      _teacherDoc.collection('students');

  static CollectionReference<Map<String, dynamic>> get subjects =>
      _teacherDoc.collection('subjects');

  static CollectionReference<Map<String, dynamic>> get grades =>
      _teacherDoc.collection('grades');

  static CollectionReference<Map<String, dynamic>> studentActivities(
    String studentId,
  ) => students.doc(studentId).collection('activities');
}
