import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  String? id;

  /// قائمة معرّفات المجموعات التي ينتمي إليها الطالب.
  /// طالب واحد ممكن يكون في أكتر من مجموعة (مواد مختلفة أو نفس المادة).
  List<String> groupIds;

  String? name;
  String? parentName;
  String? parentRelation;
  String? phone;
  bool? conectWithPhone;
  bool? conectWithWhatsApp;

  StudentModel({
    this.id,
    this.groupIds = const [],
    this.name,
    this.parentName,
    this.parentRelation,
    this.phone,
    this.conectWithPhone,
    this.conectWithWhatsApp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'groupIds': groupIds,
      'parentName': parentName,
      'parentRelation': parentRelation,
      'phone': phone,
      'conectWithPhone': conectWithPhone,
      'conectWithWhatsApp': conectWithWhatsApp,
    };
  }

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return StudentModel(
      id: doc.id,
      groupIds: List<String>.from(json["groupIds"] ?? const []),
      name: json["name"],
      parentName: json["parentName"],
      parentRelation: json["parentRelation"],
      phone: json["phone"],
      conectWithPhone: json["conectWithPhone"],
      conectWithWhatsApp: json["conectWithWhatsApp"],
    );
  }

  StudentModel copyWith({List<String>? groupIds}) {
    return StudentModel(
      id: id,
      groupIds: groupIds ?? this.groupIds,
      name: name,
      parentName: parentName,
      parentRelation: parentRelation,
      phone: phone,
      conectWithPhone: conectWithPhone,
      conectWithWhatsApp: conectWithWhatsApp,
    );
  }
}
