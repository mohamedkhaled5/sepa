import 'package:cloud_firestore/cloud_firestore.dart';

/// الصلاحيات الافتراضية لأي مساعد جديد عند إنشاء حسابه لأول مرة.
/// المدرس يقدر يغيّرها لاحقًا من شاشة "إدارة المساعدين".
const Map<String, bool> kDefaultAssistantPermissions = {
  'attendance': true, // تسجيل حضور وغياب
  'exams': true, // تسجيل نتائج الامتحانات
  'notes': true, // إضافة ملاحظات
  'createStudent': false,
  'editStudent': false,
  'deleteStudent': false,
  'transferStudent': false, // نقل طالب بين المجموعات
  'createGroup': false,
  'editGroup': false,
  'deleteGroup': false,
  'manageSubjectsGrades': false,
  'reports': false,
};

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;

  /// "teacher" أو "assistant"
  final String role;

  // ================== خاص بالمدرس فقط ==================
  /// كود الدعوة الفريد اللي المدرس بيدّيه للمساعدين عشان ينضموا له.
  final String? inviteCode;

  // ================== خاص بالمساعد فقط ==================
  /// uid بتاع المدرس اللي المساعد طلب الانضمام له.
  final String? teacherId;

  /// "pending" (لسه مستني موافقة) / "approved" / "rejected"
  final String? status;

  final Map<String, bool> permissions;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
    this.role = "teacher",
    this.inviteCode,
    this.teacherId,
    this.status,
    this.permissions = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "createdAt": FieldValue.serverTimestamp(),
      "role": role,
      if (inviteCode != null) "inviteCode": inviteCode,
      if (teacherId != null) "teacherId": teacherId,
      if (status != null) "status": status,
      if (role == "assistant") "permissions": permissions,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data["name"] ?? "",
      email: data["email"] ?? "",
      createdAt: (data["createdAt"] as Timestamp?)?.toDate(),
      role: data["role"] ?? "teacher",
      inviteCode: data["inviteCode"],
      teacherId: data["teacherId"],
      status: data["status"],
      permissions: Map<String, bool>.from(data["permissions"] ?? const {}),
    );
  }
}
