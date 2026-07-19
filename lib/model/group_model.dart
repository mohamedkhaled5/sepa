import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String? id;
  final String? gender;

  final String? subjectId;
  final String? gradeId;
  final String? name;
  final String? subject;
  final String? grade;
  final String? dayone;
  final String? daytwo;
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
    this.dayone,
    this.daytwo,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      "gender": gender,
      "subjectId": subjectId,
      "gradeId": gradeId,
      "name": name,
      "subject": subject,
      "grade": grade,
      "dayone": dayone,
      "daytwo": daytwo,
      "startTime": startTime,
      "endTime": endTime,
      "createdAt": DateTime.now().toIso8601String(),
    };
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GroupModel(
      id: doc.id,
      gender: data["gender"],
      subjectId: data["subjectId"],
      gradeId: data["gradeId"],
      name: data["name"],
      subject: data["subject"],
      grade: data["grade"],
      dayone: data["dayone"],
      daytwo: data["daytwo"],
      startTime: data["startTime"],
      endTime: data["endTime"],
    );
  }
}
