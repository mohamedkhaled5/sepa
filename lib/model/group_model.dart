import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String? id;
  final String? gender;
  final String? subjectId;
  final String? gradeId;
  final String? name;
  final String? subject;
  final String? grade;
  final List<String>? daysName;
  final String? startTime;
  final String? endTime;

  GroupModel({
    this.id,
    this.gender,
    this.subjectId,
    this.gradeId,
    this.name,
    this.subject,
    this.grade,
    this.daysName,
    this.startTime,
    this.endTime,
  });

  // 📤 الحفظ بيكون بالشكل الجديد فقط دائماً
  Map<String, dynamic> toJson() {
    return {
      "gender": gender,
      "subjectId": subjectId,
      "gradeId": gradeId,
      "name": name,
      "subject": subject,
      "grade": grade,
      "daysName": daysName ?? [],
      "startTime": startTime,
      "endTime": endTime,
      "createdAt": DateTime.now().toIso8601String(),
    };
  }

  // 📥 القراءة تدعم الشكلين (القديم والجديد) بحماية من الأخطاء
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<String> parsedDays = [];

    // 1️⃣ فحص النظام الجديد أولاً
    if (data["daysName"] != null && data["daysName"] is List) {
      parsedDays = List<String>.from(data["daysName"]);
    }
    // 2️⃣ التحول للنظام القديم في حال عدم وجود أيام بالنظام الجديد
    else {
      if (data["dayone"] != null &&
          data["dayone"].toString().trim().isNotEmpty) {
        parsedDays.add(data["dayone"].toString());
      }
      if (data["daytwo"] != null &&
          data["daytwo"].toString().trim().isNotEmpty) {
        parsedDays.add(data["daytwo"].toString());
      }
    }

    return GroupModel(
      id: doc.id,
      gender: data["gender"],
      subjectId: data["subjectId"],
      gradeId: data["gradeId"],
      name: data["name"],
      subject: data["subject"],
      grade: data["grade"],
      daysName: parsedDays, // 👈 النتيجة قائمة جاهزة دائماً
      startTime: data["startTime"],
      endTime: data["endTime"],
    );
  }
}
