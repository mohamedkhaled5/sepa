import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String id;
  final String name;

  SubjectModel({required this.id, required this.name});

  Map<String, dynamic> toJson() => {"name": name};

  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectModel(id: doc.id, name: data['name'] ?? '');
  }
}
