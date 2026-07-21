import 'package:cloud_firestore/cloud_firestore.dart';

/// كانت هذه الـ enum معرّفة بالخطأ داخل add_exam_screen.dart سابقًا.
/// نقلناها هنا لأنها جزء من تعريف النشاط نفسه، وليكون بإمكان أي شاشة
/// تستورد activity_model_type.dart استخدامها مباشرة.
enum ActivityType { attendance, exam }

class ActivityModel {
  String? id;
  String? type;
  String? date;

  /// المجموعة التي يتبع لها هذا النشاط (حضور/امتحان).
  /// ضرورية لأن الطالب ممكن يكون منضم لأكتر من مجموعة،
  /// وكل مجموعة لازم يكون ليها سجلاتها المستقلة.
  String? groupId;

  bool? attendancePresent;

  String? examName;
  String? examStatus;
  String? currentDegree;
  String? maxDegree;

  ActivityModel({
    this.id,
    this.type,
    this.date,
    this.groupId,
    this.attendancePresent,
    this.examName,
    this.examStatus,
    this.currentDegree,
    this.maxDegree,
  });

  Map<String, dynamic> toMap() {
    return {
      "type": type,
      "date": date,
      "groupId": groupId,
      "attendancePresent": attendancePresent,
      "examName": examName,
      "examStatus": examStatus,
      "currentDegree": currentDegree,
      "maxDegree": maxDegree,
    };
  }

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return ActivityModel(
      id: doc.id,
      type: json["type"],
      date: json["date"],
      groupId: json["groupId"],
      attendancePresent: json["attendancePresent"],
      examName: json["examName"],
      examStatus: json["examStatus"],
      currentDegree: json["currentDegree"],
      maxDegree: json["maxDegree"],
    );
  }
}
