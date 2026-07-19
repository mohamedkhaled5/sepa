import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String date;
  final bool isPresent;

  AttendanceModel({
    required this.id,
    required this.date,
    required this.isPresent,
  });

  Map<String, dynamic> toMap() {
    return {"date": date, "isPresent": isPresent};
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return AttendanceModel(
      id: doc.id,
      date: json["date"],
      isPresent: json["isPresent"] ?? false,
    );
  }
}
