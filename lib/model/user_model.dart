import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;
  final String role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
    this.role = "teacher",
  });

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "createdAt": FieldValue.serverTimestamp(),
      "role": role,
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
    );
  }
}
