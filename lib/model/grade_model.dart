import 'package:cloud_firestore/cloud_firestore.dart';

class GradeModel {
  final String id;
  final String name;

  GradeModel({required this.id, required this.name});

  Map<String, dynamic> toJson() => {"name": name};

  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GradeModel(id: doc.id, name: data['name'] ?? '');
  }
}
